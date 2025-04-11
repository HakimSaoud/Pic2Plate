const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  username: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  profilePicture: { type: String, default: null },
  ingredientsImages: [{
    imagePath: { type: String },
    ingredient: { type: String, default: 'unknown' }
  }],
  lastCookedDishes: [{
    name: { type: String },
    ingredients: [{ type: String }],
    recipe: { type: String },
    matchedIngredients: [{ type: String }],
    timestamp: { type: Date, default: Date.now }
  }],
  favoriteDishes: [{
    name: { type: String },
    ingredients: [{ type: String }],
    recipe: { type: String },
    matchedIngredients: [{ type: String }]
  }]
});

module.exports = mongoose.model('User', userSchema);