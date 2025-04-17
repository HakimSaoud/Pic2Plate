# Pic2Plate

CookSmart is a Flutter-based mobile application designed to simplify meal planning by leveraging AI-driven ingredient recognition and personalized recipe recommendations. Built with a robust tech stack including **Flutter**, **MongoDB**, **Express.js**, **Node.js**, and **TensorFlow**, CookSmart empowers users to identify ingredients, discover recipes, track cooking history, and manage their profiles securely.

## Features

- **AI Ingredient Recognition**: Upload a photo of an ingredient (e.g., apple, carrot), and a TensorFlow-based Convolutional Neural Network (CNN) identifies it with a confidence score, preventing duplicate entries.
- **Personalized Recipe Recommendations**: Matches your ingredients to a MongoDB-stored recipe database, suggesting dishes with highlighted matched ingredients.
- **Cooking History & Favorites**: Mark dishes as cooked (stores up to 5 recent meals), save favorites, and clear history or remove individual entries.
- **Profile Management**: Update username, email, and profile picture. Remove your profile picture directly while editing your profile for a fresh start.
- **Secure Authentication**: Sign up/sign in with JWT-based authentication (30-minute access tokens, 7-day refresh tokens) and bcrypt-hashed passwords.
- **Responsive UI**: Built with Flutter for a smooth, cross-platform experience with custom visuals like triangle backgrounds and animated snackbars.

## Tech Stack

- **Frontend**: Flutter (Dart) for a responsive, modern UI.
- **Backend**: Node.js with Express.js, MongoDB for data storage, Mongoose for schema management, and Multer for image uploads.
- **AI Model**: TensorFlow CNN trained on 54 fruit and vegetable classes, integrated via a Python script (`predict_ingredient.py`).
- **Security**: JWT for authentication, bcrypt for password hashing, and automatic cleanup of old images using `fs`.
- **Others**: Child processes for TensorFlow-Node.js integration, data augmentation for robust AI training.

## Installation

### Prerequisites

- Flutter SDK (v3.0.0 or higher)
- Node.js (v16 or higher)
- MongoDB (local or Atlas)
- Python (v3.8 or higher) with TensorFlow installed
- Git

### Steps

1. **Clone the Repository**:

   ```bash
   git clone https://github.com/yourusername/cooksmart.git
   cd cooksmart
   ```


   2. **Backend Setup**:

   - Navigate to the backend directory:

     ```bash
     cd backend
     ```
   - Install dependencies:

     ```bash
     npm install
     ```
   - Create a `.env` file with the following:

     ```env
     MONGODB_URI=your_mongodb_connection_string
     JWT_SECRET=your_jwt_secret
     JWT_REFRESH_SECRET=your_refresh_secret
     ```
   - Start the backend server:

     ```bash
     npm start
     ```

3. **AI Model Setup**:

   - Ensure TensorFlow is installed:

     ```bash
     pip install tensorflow
     ```
   - Place the trained model (`model.h5`) in the backend’s `/model` directory.
   - Update `predict_ingredient.py` to point to the model path if needed.