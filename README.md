# Pic2Plate

CookSmart is a Flutter-based mobile application designed to simplify meal planning by leveraging AI-driven ingredient recognition and personalized recipe recommendations. Built with a robust tech stack including **Flutter**, **MongoDB**, **Express.js**, **Node.js**, and **TensorFlow**, CookSmart empowers users to identify ingredients, discover recipes, track cooking history, and manage their profiles securely.

## Features

- **AI Ingredient Recognition**: Upload a photo of an ingredient (e.g., apple, carrot), and a TensorFlow-based Convolutional Neural Network (CNN) identifies it with a confidence score, preventing duplicate entries.
- **Personalized Recipe Recommendations**: Matches your ingredients to a MongoDB-stored recipe database, suggesting dishes with highlighted matched ingredients.
- **Cooking History & Favorites**: Mark dishes as cooked (stores up to 5 recent meals), save favorites, and clear history or remove individual entries.
- **Profile Management**: Update username, email, and profile picture. Remove your profile picture directly while editing your profile for a fresh start.
- **Secure Authentication**: Sign up/sign in with JWT-based authentication (30-minute access tokens, 7-day refresh tokens) and bcrypt-hashed passwords.
- **Responsive UI**: Built with Flutter for a smooth, cross-platform experience with custom visuals like triangle backgrounds and animated snackbars.