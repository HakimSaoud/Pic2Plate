const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  username: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  ingredientsImages: [{
    imagePath: { type: String },
    ingredient: { type: String, default: 'unknown' }
  }],
  latestRecommendations: [{
    name: { type: String },
    ingredients: [{ type: String }],
    recipe: { type: String },
    matchedIngredients: [{ type: String }],
    timestamp: { type: Date, default: Date.now }
  }]
});

module.exports = mongoose.model('User', userSchema);