const mongoose = require('mongoose');

const recipeSchema = new mongoose.Schema({
  name: { 
    type: String, 
    required: true 
  },
  ingredients: [{ 
    type: String 
  }],
  recipe: { 
    type: String, 
    required: true 
  }
});

module.exports = mongoose.model('Recipe', recipeSchema);