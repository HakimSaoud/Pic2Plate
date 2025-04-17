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

4. **Frontend Setup**:

   - Navigate to the frontend directory:

     ```bash
     cd frontend
     ```
   - Install Flutter dependencies:

     ```bash
     flutter pub get
     ```
   - Update `lib/components/base_auth.dart` with your backend URL:

     ```dart
     static const String baseUrl = 'http://your-backend-url:3000';
     ```
   - Run the Flutter app:

     ```bash
     flutter run
     ```
## Usage

1. **Sign Up/Sign In**: Create an account or log in to access the app.
2. **Add Ingredients**: Upload photos of ingredients via the “Add Ingredients” screen to build your inventory.
3. **Get Recommendations**: Tap “Get a Recommendation” or visit the “Recommendations” tab to find recipes matching your ingredients.
4. **Track Cooking**: Mark dishes as cooked, save favorites, or remove them from your history.
5. **Manage Profile**: Update your username, email, or profile picture. In edit mode, remove your profile picture if desired.
6. **Logout**: Securely log out to end your session.

## AI Model Details

- **Model**: Convolutional Neural Network (CNN) built with TensorFlow.
- **Classes**: Trained on 54 fruit and vegetable categories (e.g., broccoli, tomato, zucchini).
- **Training**: Used a diverse dataset with augmentation (rotations, flips) for robustness across lighting and angles.
- **Inference**: Processes images via `predict_ingredient.py`, returning the top class and confidence score (e.g., “cucumber, 93.2%”).
- **Integration**: Called by the Node.js backend using child processes, results are sent to the Flutter frontend.

## Project Structure

```
cooksmart/
├── backend/                    # Node.js/Express backend
│   ├── model/                  # TensorFlow model files
│   ├── uploads/                # Stored images
│   ├── app.js                  # Main server file
│   ├── predict_ingredient.py   # AI prediction script
│   └── ...
├── frontend/                   # Flutter frontend
│   ├── lib/                    # Dart source code
│   │   ├── components/         # Reusable widgets
│   │   ├── screens/            # App screens
│   │   └── main.dart           # Entry point
│   └── pubspec.yaml            # Flutter dependencies
├── README.md                   # This file
└── ...
```

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository.
2. Create a new branch (`git checkout -b feature/your-feature`).
3. Commit your changes (`git commit -m 'Add your feature'`).
4. Push to the branch (`git push origin feature/your-feature`).
5. Open a pull request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

For questions or feedback, reach out via 50655hakim@gmail.com or open an issue on GitHub.

Happy cooking with CookSmart! 🍽️


