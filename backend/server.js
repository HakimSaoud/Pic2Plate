
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const app = express();
const port = process.PORT || 3000;

require('./dbConnect')


// Models 
const userSchema = require('./models/userSchema');
const User = mongoose.model('User', userSchema);




app.use(bodyParser.json());
app.use(cors({
  origin: 'http://localhost:<your-flutter-port>', // Replace with your Flutter app's port
  credentials: true
}));




// Authentication Middleware
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

// Token Generation
const generateAccessToken = (user) => {
  return jwt.sign(
    { id: user._id, email: user.email },
    'ACCESS_SECRET_KEY',
    { expiresIn: '15m' }
  );
};

const generateRefreshToken = (user) => {
  return jwt.sign(
    { id: user._id, email: user.email },
    'REFRESH_SECRET_KEY',
    { expiresIn: '7d' }
  );
};

// API Endpoints

// Signup
app.post('/signup', async (req, res) => {
  try {
    const { username, email, password } = req.body;

    // Validation
    if (!username || !email || !password) {
      return res.status(400).json({ error: 'All fields are required' });
    }

    // Check existing user
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(409).json({ error: 'User already exists' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create user
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

// Signin
app.post('/signin', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validation
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    // Find user
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Verify password
    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Generate tokens
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

// Refresh Token
app.post('/refresh', (req, res) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) return res.sendStatus(401);

    // Verify refresh token
    jwt.verify(refreshToken, REFRESH_SECRET_KEY, (err, decoded) => {
      if (err) return res.status(403).json({ error: 'Invalid or expired refresh token' });

      // Generate new access token
      const accessToken = generateAccessToken({ _id: decoded.id, email: decoded.email });
      res.json({ accessToken });
    });

  } catch (error) {
    console.error('Refresh token error:', error);
    res.status(500).json({ error: 'Server error', details: error.message });
  }
});

// Protected Home Route
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

// Logout
app.post('/logout', (req, res) => {
  // Since refresh tokens are stateless, no action is needed on the server
  res.json({ message: 'Logged out successfully' });
});

// Start Server
app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});