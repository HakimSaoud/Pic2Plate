const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  username: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  ingredientsImages: [{
    imagePath: { type: String },
    ingredient: { type: String, default: 'unknown' }
  }]
});

module.exports = mongoose.model('User', userSchema);