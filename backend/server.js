const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
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

const ACCESS_SECRET_KEY = 'ACCESS_SECRET_KEY'; // Replace with env vars in production
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
      // Token expired or invalid, attempt refresh
      const refreshToken = req.body.refreshToken || req.headers['x-refresh-token'];
      if (!refreshToken) return res.status(403).json({ error: 'Refresh token required' });

      jwt.verify(refreshToken, REFRESH_SECRET_KEY, (refreshErr, decoded) => {
        if (refreshErr) return res.status(403).json({ error: 'Invalid or expired refresh token' });

        const newAccessToken = jwt.sign(
          { id: decoded.id, email: decoded.email },
          ACCESS_SECRET_KEY,
          { expiresIn: '30m' }
        );
        req.user = decoded;
        req.newAccessToken = newAccessToken; // Pass new token back to client
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

// Restricted Routes with Refresh Logic
app.post('/upload-ingredients', authenticateToken, upload.single('image'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'No image uploaded' });

    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    const imagePath = req.file.path;
    const ingredient = 'unknown';

    user.ingredientsImages.push({ imagePath, ingredient });
    await user.save();

    res.status(201).json({
      message: 'Image uploaded successfully',
      imagePath,
      ingredient,
      userImages: user.ingredientsImages,
      newAccessToken: req.newAccessToken || null,
    });
  } catch (error) {
    console.error('Upload error:', error);
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

// Unchanged Endpoints
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