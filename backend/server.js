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
const port = process.PORT || 3000;

require('./dbConnect');
const User = require('./models/userSchema');
const Recipe = require('./models/recipeSchema');

const ACCESS_SECRET_KEY = 'ACCESS_SECRET_KEY';
const REFRESH_SECRET_KEY = 'REFRESH_SECRET_KEY';

app.use(bodyParser.json());


app.use(cors({
  origin: 'http://localhost:55555',
  credentials: true
}));
app.use('/uploads', express.static('uploads'));

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

if (!fs.existsSync('uploads')) fs.mkdirSync('uploads');

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
          { expiresIn: '15d' }
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

const generateAccessToken = (user) => {
  return jwt.sign({ id: user._id, email: user.email }, ACCESS_SECRET_KEY, { expiresIn: '30m' });
};

const generateRefreshToken = (user) => {
  return jwt.sign({ id: user._id, email: user.email }, REFRESH_SECRET_KEY, { expiresIn: '7d' });
};

 // Add this at the top with other requires

 app.post('/upload-ingredients', authenticateToken, upload.single('image'), async (req, res) => {
  try {
    console.log('Received upload request');
    if (!req.file) {
      console.log('No file uploaded');
      return res.status(400).json({ error: 'No image uploaded' });
    }

    console.log('File uploaded:', req.file.path);
    const user = await User.findById(req.user.id);
    if (!user) {
      console.log('User not found:', req.user.id);
      return res.status(404).json({ error: 'User not found' });
    }

    const imagePath = req.file.path;

    if (!fs.existsSync(imagePath)) {
      console.error('Uploaded file not found:', imagePath);
      return res.status(500).json({ error: 'Uploaded file not found on server' });
    }

    const pythonCommand = `/Users/macbook/miniconda3/bin/python3.12 predict_ingredient.py "${imagePath}"`;
    console.log('Executing Python command:', pythonCommand);

    const execPromise = new Promise((resolve, reject) => {
      exec(pythonCommand, { timeout: 10000 }, (error, stdout, stderr) => {
        if (error) {
          console.error('Exec error:', error);
          console.error('Stderr:', stderr);
          return reject(error);
        }
        console.log('Stdout:', stdout);
        console.log('Stderr:', stderr);
        resolve(stdout);
      });
    });

    let result;
    try {
      const output = await execPromise;
      console.log('Python script output:', output);
      if (!output) {
        console.log('No output from Python script');
        return res.status(500).json({ error: 'No prediction result returned' });
      }

      const jsonLine = output.split('\n').find(line => line.trim().startsWith('{') && line.trim().endsWith('}'));
      if (!jsonLine) {
        console.error('No valid JSON found in output:', output);
        return res.status(500).json({ error: 'No valid JSON in prediction output' });
      }

      result = JSON.parse(jsonLine);
      console.log('Parsed result:', result);
    } catch (err) {
      console.error('Python execution or parsing error:', err);
      return res.status(500).json({ error: 'Prediction failed', details: err.message });
    }

    const ingredient = result.ingredient.toLowerCase(); // Normalize to lowercase
    const confidence = result.confidence;

    // Check for duplicate ingredient
    const existingIngredient = user.ingredientsImages.find(
      item => item.ingredient.toLowerCase() === ingredient
    );
    if (existingIngredient) {
      console.log(`Ingredient "${ingredient}" already exists in user's list`);
      // Optionally delete the new uploaded file since it won't be saved
      if (fs.existsSync(imagePath)) {
        fs.unlinkSync(imagePath);
        console.log(`Deleted duplicate image: ${imagePath}`);
      }
      return res.status(200).json({
        message: `Ingredient "${ingredient}" already exists`,
        imagePath: existingIngredient.imagePath,
        ingredient: existingIngredient.ingredient,
        userImages: user.ingredientsImages,
        newAccessToken: req.newAccessToken || null,
      });
    }

    // If no duplicate, proceed to save
    console.log('Saving to user:', { imagePath, ingredient });
    user.ingredientsImages.push({ imagePath, ingredient });
    await user.save({ maxTimeMS: 5000 });
    console.log('User saved successfully');

    console.log('Sending response to client');
    res.status(201).json({
      message: 'Image uploaded and ingredient identified successfully',
      imagePath,
      ingredient,
      confidence: confidence.toFixed(2),
      userImages: user.ingredientsImages,
      newAccessToken: req.newAccessToken || null,
    });
  } catch (error) {
    console.error('Upload endpoint error:', error);
    res.status(500).json({ error: 'Server error', details: error.message });
  }
});


app.get('/identify-ingredients', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    if (!user.ingredientsImages || user.ingredientsImages.length === 0) {
      return res.status(400).json({ error: 'No ingredients found for this user' });
    }

    const ingredients = user.ingredientsImages.map(item => ({
      imagePath: item.imagePath,
      ingredient: item.ingredient
    }));

    res.status(200).json({
      message: 'Ingredients retrieved successfully',
      ingredients,
      newAccessToken: req.newAccessToken || null,
    });
  } catch (error) {
    console.error('Identify ingredients error:', error);
    res.status(500).json({ error: 'Server error', details: error.message });
  }
});


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
      console.log(`Deleted file: ${removedImagePath}`);
    }

    res.status(200).json({
      message: 'Ingredient removed successfully',
      ingredients: user.ingredientsImages,
      newAccessToken: req.newAccessToken || null,
    });
  } catch (error) {
    console.error('Remove ingredient error:', error);
    res.status(500).json({ error: 'Server error', details: error.message });
  }
});

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
      user: { id: user._id, username: user.username, email: user.email }
    });
  } catch (error) {
    console.error('Signup error:', error);
    res.status(500).json({ error: 'Server error', details: error.message });
  }
});

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
      user: { id: user._id, username: user.username, email: user.email },
      accessToken,
      refreshToken
    });
  } catch (error) {
    console.error('Signin error:', error);
    res.status(500).json({ error: 'Server error', details: error.message });
  }
});

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

    const recommendations = recipes.filter(recipe => {
      const recipeIngredients = recipe.ingredients.map(ing => ing.toLowerCase());
      return recipeIngredients.some(ing => userIngredients.includes(ing));
    }).map(recipe => ({
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
    console.error('Recommend recipes error:', error);
    res.status(500).json({ error: 'Server error', details: error.message });
  }
});

// New endpoint to mark a dish as cooked
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

    // Remove any existing dish with the same name to avoid duplicates
    user.lastCookedDishes = user.lastCookedDishes.filter(
      (dish) => dish.name !== name
    );

    // Add the new dish
    user.lastCookedDishes.push(cookedDish);

    // Keep only the last 5 dishes
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
    console.error('Mark cooked error:', error);
    res.status(500).json({ error: 'Server error', details: error.message });
  }
});

// New endpoint to toggle favorite status
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
      // Remove if already favorited
      user.favoriteDishes = user.favoriteDishes.filter(fav => fav.name !== name);
    } else {
      // Add only if not already present (redundant check since we toggle, but ensures no duplicates)
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
    console.error('Toggle favorite error:', error);
    res.status(500).json({ error: 'Server error', details: error.message });
  }
});


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
    console.error('Refresh token error:', error);
    res.status(500).json({ error: 'Server error', details: error.message });
  }
});

app.post('/clear-cooked-history', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    user.lastCookedDishes = []; // Clear the array
    await user.save();

    res.status(200).json({
      message: 'Cooked dishes history cleared successfully',
      lastCookedDishes: user.lastCookedDishes,
      newAccessToken: req.newAccessToken || null,
    });
  } catch (error) {
    console.error('Clear cooked history error:', error);
    res.status(500).json({ error: 'Server error', details: error.message });
  }
});

app.get('/home', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json({ user, newAccessToken: req.newAccessToken || null });
  } catch (error) {
    console.error('Home route error:', error);
    res.status(500).json({ error: 'Server error', details: error.message });
  }
});

app.post('/logout', (req, res) => {
  res.json({ message: 'Logged out successfully' });
});

app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});