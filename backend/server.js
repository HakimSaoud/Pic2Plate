const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

const app = express();
const port = process.env.PORT || 3000;

require('./dbConnect');
const User = require('./models/userSchema');
const Recipe = require('./models/recipeSchema');

const ACCESS_SECRET_KEY = 'ACCESS_SECRET_KEY';
const REFRESH_SECRET_KEY = 'REFRESH_SECRET_KEY';

app.use(bodyParser.json());
app.use(cors({
  origin: 'http://localhost:55555',
  credentials: true,
}));
app.use('/uploads', express.static('uploads'));

// Multer setup for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'uploads/'),
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const originalName = file.originalname.toLowerCase();
    const fileExtension = path.extname(originalName);
    const baseName = path.basename(originalName, fileExtension);
    cb(null, `${baseName}-${uniqueSuffix}${fileExtension}`);
  },
});
const upload = multer({ storage });

// Ensure the 'uploads' directory exists
if (!fs.existsSync('uploads')) fs.mkdirSync('uploads');








// Middleware to authenticate JWT tokens
const authenticateToken = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) return res.sendStatus(401);

  jwt.verify(token, ACCESS_SECRET_KEY, (err, user) => {
    if (err) {
      const refreshToken = req.body.refreshToken || req.headers['x-refresh-token'];
      if (!refreshToken) return res.status(403).json({ error: 'Refresh token required' });

      jwt.verify(refreshToken, REFRESH_SECRET_KEY, (refreshErr, decoded) => {
        if (refreshErr) return res.status(403).json({ error: 'Invalid or expired refresh token' });

        const newAccessToken = jwt.sign(
          { id: decoded.id, email: decoded.email },
          ACCESS_SECRET_KEY,
          { expiresIn: '15m' }
        );
        req.user = decoded;
        req.newAccessToken = newAccessToken;
        next();
      });
    } else {
      req.user = user;
      next();
    }
  });
};

// Token generation functions
const generateAccessToken = (user) => {
  return jwt.sign({ id: user._id, email: user.email }, ACCESS_SECRET_KEY, { expiresIn: '30m' });
};

const generateRefreshToken = (user) => {
  return jwt.sign({ id: user._id, email: user.email }, REFRESH_SECRET_KEY, { expiresIn: '7d' });
};

// Upload ingredients image and predict ingredient
app.post('/upload-ingredients', authenticateToken, upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No image uploaded' });
    }

    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    const imagePath = req.file.path;

    if (!fs.existsSync(imagePath)) {
      return res.status(500).json({ error: 'Uploaded file not found on server' });
    }

    const pythonCommand = `/Users/macbook/miniconda3/bin/python3.12 predict_ingredient.py "${imagePath}"`;
    const execPromise = new Promise((resolve, reject) => {
      exec(pythonCommand, { timeout: 10000 }, (error, stdout, stderr) => {
        if (error) {
          console.error('Exec error:', error);
          console.error('Stderr:', stderr);
          return reject(error);
        }
        resolve(stdout);
      });
    });

    let result;
    try {
      const output = await execPromise;
      const jsonLine = output.split('\n').find(line => line.trim().startsWith('{') && line.trim().endsWith('}'));
      if (!jsonLine) {
        return res.status(500).json({ error: 'No valid JSON in prediction output' });
      }
      result = JSON.parse(jsonLine);
    } catch (err) {
      return res.status(500).json({ error: 'Prediction failed', details: err.message });
    }

    const ingredient = result.ingredient.toLowerCase();
    const confidence = result.confidence;

    const existingIngredient = user.ingredientsImages.find(
      item => item.ingredient.toLowerCase() === ingredient
    );
    if (existingIngredient) {
      if (fs.existsSync(imagePath)) {
        fs.unlinkSync(imagePath);
      }
      return res.status(200).json({
        message: `Ingredient "${ingredient}" already exists`,
        imagePath: existingIngredient.imagePath,
        ingredient: existingIngredient.ingredient,
        userImages: user.ingredientsImages,
        newAccessToken: req.newAccessToken || null,
      });
    }

    user.ingredientsImages.push({ imagePath, ingredient });
    await user.save();

    res.status(201).json({
      message: 'Image uploaded and ingredient identified successfully',
      imagePath,
      ingredient,
      confidence: confidence.toFixed(2),
      userImages: user.ingredientsImages,
      newAccessToken: req.newAccessToken || null,
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error', details: error.message });
  }
});

// Get user's ingredients
app.get('/identify-ingredients', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    if (!user.ingredientsImages || user.ingredientsImages.length === 0) {
      return res.status(400).json({ error: 'No ingredients found for this user' });
    }

    const ingredients = user.ingredientsImages.map(item => ({
      imagePath: item.imagePath,
      ingredient: item.ingredient,
    }));

    res.status(200).json({
      message: 'Ingredients retrieved successfully',
      ingredients,
      newAccessToken: req.newAccessToken || null,
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error', details: error.message });
  }
});

// Remove an ingredient
app.post('/remove-ingredient', authenticateToken, async (req, res) => {
  try {
    const { imagePath } = req.body;
    if (!imagePath) return res.status(400).json({ error: 'Image path is required' });

    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    const imageIndex = user.ingredientsImages.findIndex(item => item.imagePath === imagePath);
    if (imageIndex === -1) return res.status(404).json({ error: 'Image not found in user\'s list' });

    const removedImagePath = user.ingredientsImages[imageIndex].imagePath;
    user.ingredientsImages.splice(imageIndex, 1);
    await user.save();

    if (removedImagePath && fs.existsSync(removedImagePath)) {
      fs.unlinkSync(removedImagePath);
    }

    res.status(200).json({
      message: 'Ingredient removed successfully',
      ingredients: user.ingredientsImages,
      newAccessToken: req.newAccessToken || null,
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error', details: error.message });
  }
});

// Signup endpoint
app.post('/signup', async (req, res) => {
  try {
    const { username, email, password } = req.body;
    if (!username || !email || !password) {
      return res.status(400).json({ error: 'All fields are required' });
    }

    const existingUser = await User.findOne({ email });
    if (existingUser) return res.status(409).json({ error: 'User already exists' });

    const hashedPassword = await bcrypt.hash(password, 10);
    const user = new User({ username, email, password: hashedPassword });
    await user.save();

    res.status(201).json({
      message: 'User created successfully',
      user: { id: user._id, username: user.username, email: user.email },
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error', details: error.message });
  }
});

// Signin endpoint
app.post('/signin', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ error: 'User not found' });

    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) return res.status(401).json({ error: 'Invalid credentials' });

    const accessToken = generateAccessToken(user);
    const refreshToken = generateRefreshToken(user);

    res.json({
      message: 'Signin successful',
      user: {
        id: user._id,
        username: user.username,
        email: user.email,
        profilePicture: user.profilePicture, // Include profile picture
      },
      accessToken,
      refreshToken,
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error', details: error.message });
  }
});

// Recommend recipes based on user's ingredients
app.get('/recommend-recipes', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    if (!user.ingredientsImages || user.ingredientsImages.length === 0) {
      return res.status(200).json({
        message: 'No ingredients available for recommendations',
        recommendations: [],
        newAccessToken: req.newAccessToken || null,
      });
    }

    const userIngredients = user.ingredientsImages.map(item => item.ingredient.toLowerCase());
    const recipes = await Recipe.find();

    const recommendations = recipes
      .filter(recipe => {
        const recipeIngredients = recipe.ingredients.map(ing => ing.toLowerCase());
        return recipeIngredients.some(ing => userIngredients.includes(ing));
      })
      .map(recipe => ({
        name: recipe.name,
        ingredients: recipe.ingredients,
        recipe: recipe.recipe,
        matchedIngredients: recipe.ingredients.filter(ing => userIngredients.includes(ing.toLowerCase())),
      }));

    res.status(200).json({
      message: 'Recommendations retrieved successfully',
      recommendations,
      newAccessToken: req.newAccessToken || null,
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error', details: error.message });
  }
});

// Mark a dish as cooked
app.post('/mark-cooked', authenticateToken, async (req, res) => {
  try {
    const { name, ingredients, recipe, matchedIngredients } = req.body;
    if (!name || !ingredients || !recipe || !matchedIngredients) {
      return res.status(400).json({ error: 'All dish details are required' });
    }

    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    const cookedDish = {
      name,
      ingredients,
      recipe,
      matchedIngredients,
      timestamp: new Date(),
    };

    user.lastCookedDishes = user.lastCookedDishes.filter(dish => dish.name !== name);
    user.lastCookedDishes.push(cookedDish);

    if (user.lastCookedDishes.length > 5) {
      user.lastCookedDishes = user.lastCookedDishes.slice(-5);
    }

    await user.save();

    res.status(200).json({
      message: 'Dish marked as cooked',
      lastCookedDishes: user.lastCookedDishes,
      newAccessToken: req.newAccessToken || null,
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error', details: error.message });
  }
});

// Remove a cooked dish
app.post('/remove-cooked-dish', authenticateToken, async (req, res) => {
  try {
    const { name } = req.body;
    if (!name) {
      return res.status(400).json({ error: 'Dish name is required' });
    }

    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    user.lastCookedDishes = user.lastCookedDishes.filter(dish => dish.name !== name);
    await user.save();

    res.status(200).json({
      message: 'Dish removed from history',
      lastCookedDishes: user.lastCookedDishes,
      newAccessToken: req.newAccessToken || null,
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error', details: error.message });
  }
});

// Toggle favorite status of a dish
app.post('/toggle-favorite', authenticateToken, async (req, res) => {
  try {
    const { name, ingredients, recipe, matchedIngredients } = req.body;
    if (!name || !ingredients || !recipe || !matchedIngredients) {
      return res.status(400).json({ error: 'All dish details are required' });
    }

    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    const dish = { name, ingredients, recipe, matchedIngredients };
    const isFavorited = user.favoriteDishes.some(fav => fav.name === name);

    if (isFavorited) {
      user.favoriteDishes = user.favoriteDishes.filter(fav => fav.name !== name);
    } else {
      if (!user.favoriteDishes.some(fav => fav.name === name)) {
        user.favoriteDishes.push(dish);
      }
    }
    await user.save();

    res.status(200).json({
      message: isFavorited ? 'Removed from favorites' : 'Added to favorites',
      favoriteDishes: user.favoriteDishes,
      newAccessToken: req.newAccessToken || null,
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error', details: error.message });
  }
});

// Refresh token endpoint
app.post('/refresh', (req, res) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) return res.sendStatus(401);

    jwt.verify(refreshToken, REFRESH_SECRET_KEY, (err, decoded) => {
      if (err) return res.status(403).json({ error: 'Invalid or expired refresh token' });

      const accessToken = generateAccessToken({ _id: decoded.id, email: decoded.email });
      res.json({ accessToken });
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error', details: error.message });
  }
});

// Clear cooked history
app.post('/clear-cooked-history', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    user.lastCookedDishes = [];
    await user.save();

    res.status(200).json({
      message: 'Cooked dishes history cleared successfully',
      lastCookedDishes: user.lastCookedDishes,
      newAccessToken: req.newAccessToken || null,
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error', details: error.message });
  }
});

// Home endpoint (returns user data including profile picture)
app.get('/home', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');
    if (!user) return res.status(404).json({ error: 'User not found' });

    res.json({
      user: {
        id: user._id,
        username: user.username,
        email: user.email,
        profilePicture: user.profilePicture, // Include profile picture
        lastCookedDishes: user.lastCookedDishes,
        favoriteDishes: user.favoriteDishes,
        ingredientsImages: user.ingredientsImages,
      },
      newAccessToken: req.newAccessToken || null,
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error', details: error.message });
  }
});

// Logout endpoint
app.post('/logout', (req, res) => {
  res.json({ message: 'Logged out successfully' });
});
app.put('/update-profile', authenticateToken, upload.single('profilePicture'), async (req, res) => {
  try {
    const { username, email, removeProfilePicture } = req.body;
    if (!username || !email) {
      return res.status(400).json({ error: 'Username and email are required' });
    }

    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    if (email !== user.email) {
      const existingUser = await User.findOne({ email });
      if (existingUser) {
        return res.status(400).json({ error: 'Email is already in use' });
      }
    }

    user.username = username;
    user.email = email;

    if (removeProfilePicture === 'true') {
      // Remove profile picture
      if (user.profilePicture && fs.existsSync(user.profilePicture)) {
        fs.unlinkSync(user.profilePicture); // Delete the image file
      }
      user.profilePicture = null; // Set to null in the database
    } else if (req.file) {
      // Handle new profile picture upload
      if (user.profilePicture && fs.existsSync(user.profilePicture)) {
        fs.unlinkSync(user.profilePicture); // Delete old image
      }
      user.profilePicture = `/uploads/${req.file.filename}`;
    }

    await user.save();

    res.status(200).json({
      message: 'Profile updated successfully',
      newAccessToken: req.newAccessToken || null,
      user: {
        username: user.username,
        email: user.email,
        profilePicture: user.profilePicture,
      },
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error', details: error.message });
  }
});

// Start the server
app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});