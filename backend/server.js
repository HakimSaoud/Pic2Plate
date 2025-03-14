const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const fs = require('fs');
const path = require('path');

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
  credentials: true
}));

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/');
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const originalName = file.originalname.toLowerCase();
    const fileExtension = path.extname(originalName);
    const baseName = path.basename(originalName, fileExtension);
    cb(null, `${baseName}-${uniqueSuffix}${fileExtension}`);
  },
});
const upload = multer({ storage });

if (!fs.existsSync('uploads')) {
  fs.mkdirSync('uploads');
}

const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) return res.sendStatus(401);

  jwt.verify(token, ACCESS_SECRET_KEY, (err, user) => {
    if (err) return res.status(403).json({ error: 'Invalid or expired token' });
    req.user = user;
    next();
  });
};

const generateAccessToken = (user) => {
  return jwt.sign(
    { id: user._id, email: user.email },
    ACCESS_SECRET_KEY,
    { expiresIn: '30m' }
  );
};

const generateRefreshToken = (user) => {
  return jwt.sign(
    { id: user._id, email: user.email },
    REFRESH_SECRET_KEY,
    { expiresIn: '7d' }
  );
};

// Simple mapping of labels to ingredients
const labelToIngredientMap = {
  'carrot': 'carrot',
  'apple': 'apple',
  'orange': 'orange',
  'banana': 'banana',
  'tomato': 'tomato',
  'potato': 'potato',
  'onion': 'onion',
  'garlic': 'garlic',
  'bell pepper': 'bell pepper',
  'eggplant': 'eggplant',
  'zucchini': 'zucchini',
  'olive': 'olive',
  'chickpea': 'chickpea',
  'lentil': 'lentil',
  'beef': 'beef',
  'chicken': 'chicken',
  'fish': 'fish',
  'egg': 'egg',
};

// Rule-based ingredient prediction (based on file name or manual mapping)
function predictIngredient(imagePath) {
  const fileName = path.basename(imagePath).toLowerCase();
  let ingredient = 'unknown';

  // Check if the file name contains any ingredient keywords
  for (const [key, value] of Object.entries(labelToIngredientMap)) {
    if (fileName.includes(key)) {
      ingredient = value;
      break;
    }
  }

  return ingredient;
}

app.post('/signup', async (req, res) => {
  try {
    const { username, email, password } = req.body;

    if (!username || !email || !password) {
      return res.status(400).json({ error: 'All fields are required' });
    }

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(409).json({ error: 'User already exists' });
    }

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
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

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

app.get('/home', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json({ user });
  } catch (error) {
    console.error('Home route error:', error);
    res.status(500).json({ error: 'Server error', details: error.message });
  }
});

app.post('/logout', (req, res) => {
  res.json({ message: 'Logged out successfully' });
});

app.post('/upload-ingredients', authenticateToken, upload.single('image'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'No image uploaded' });

    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    const imagePath = req.file.path;
    let ingredient = req.body.ingredient || predictIngredient(imagePath); // Allow user to specify ingredient

    user.ingredientsImages.push({ imagePath, ingredient }); // Store ingredient with image
    await user.save();

    res.status(201).json({
      message: 'Image uploaded successfully',
      imagePath: imagePath,
      ingredient: ingredient,
      userImages: user.ingredientsImages
    });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ error: 'Server error', details: error.message });
  }
});

app.post('/remove-ingredient', authenticateToken, async (req, res) => {
  try {
    const { imagePath } = req.body;

    if (!imagePath) {
      return res.status(400).json({ error: 'imagePath is required' });
    }

    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    const imageIndex = user.ingredientsImages.findIndex(item => item.imagePath === imagePath);
    if (imageIndex === -1) {
      return res.status(404).json({ error: 'Image not found in user\'s ingredients' });
    }

    user.ingredientsImages.splice(imageIndex, 1);
    await user.save();

    if (fs.existsSync(imagePath)) {
      fs.unlinkSync(imagePath);
      console.log(`Deleted file: ${imagePath}`);
    }

    res.status(200).json({
      message: 'Image removed successfully',
      userImages: user.ingredientsImages
    });
  } catch (error) {
    console.error('Remove ingredient error:', error);
    res.status(500).json({ error: 'Server error', details: error.message });
  }
});

app.get('/identify-ingredients', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    if (!user.ingredientsImages || user.ingredientsImages.length === 0) {
      return res.status(400).json({ error: 'No images found for this user' });
    }

    const identifiedIngredients = user.ingredientsImages.map(item => ({
      imagePath: item.imagePath,
      ingredient: item.ingredient !== 'unknown' ? item.ingredient : predictIngredient(item.imagePath)
    }));

    res.status(200).json({
      message: 'Ingredients identified successfully',
      ingredients: identifiedIngredients
    });
  } catch (error) {
    console.error('Identify ingredients error:', error);
    res.status(500).json({ error: 'Server error', details: error.message });
  }
});

app.get('/recommend-dishes', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    if (!user.ingredientsImages || user.ingredientsImages.length === 0) {
      return res.status(400).json({ error: 'No images found for this user' });
    }

    // Identify ingredients
    const identifiedIngredients = [];
    for (const item of user.ingredientsImages) {
      const ingredient = item.ingredient !== 'unknown' ? item.ingredient : predictIngredient(item.imagePath);
      if (ingredient !== 'unknown') {
        identifiedIngredients.push(ingredient);
      }
    }

    if (identifiedIngredients.length === 0) {
      return res.status(400).json({ error: 'No recognizable ingredients found' });
    }

    // Fetch recipes from MongoDB and select only name and recipe fields
    const recipes = await Recipe.find().select('name recipe ingredients');
    const recommendedDishes = recipes
      .filter(recipe => {
        // Ensure all recipe ingredients are in identifiedIngredients
        return recipe.ingredients.every(ingredient => identifiedIngredients.includes(ingredient));
      })
      .map(recipe => ({
        name: recipe.name,
        recipe: recipe.recipe
      }));

    if (recommendedDishes.length === 0) {
      return res.status(404).json({ error: 'No Tunisian dishes found that can be made with only these ingredients' });
    }

    res.status(200).json({
      message: 'Dishes recommended successfully',
      userIngredients: identifiedIngredients,
      recommendedDishes: recommendedDishes
    });
  } catch (error) {
    console.error('Recommend dishes error:', error);
    res.status(500).json({ error: 'Server error', details: error.message });
  }
});

app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});