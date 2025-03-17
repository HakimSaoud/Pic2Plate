
import tensorflow as tf
import numpy as np
from tensorflow.keras.preprocessing import image
import sys
import json

model = tf.keras.models.load_model('fruit_vegetable_classifier_improved.keras')

class_labels = [
    'apple', 'banana', 'beetroot', 'bell_pepper', 'cabbage', 'capsicum', 'carrot', 'cauliflower',
    'chilli_pepper', 'corn', 'cucumber', 'eggplant', 'garlic', 'ginger', 'grapes', 'jalepeno',
    'kiwi', 'lemon', 'lettuce', 'mango', 'onion', 'orange', 'paprika', 'pear', 'peas', 'pineapple',
    'pomegranate', 'potato', 'raddish', 'soy_beans', 'spinach', 'sweetcorn', 'sweetpotato', 'tomato',
    'turnip', 'watermelon', 'apricot', 'avocado', 'broccoli', 'brussels_sprouts', 'celery', 'cherries',
    'coconut', 'fig', 'green_beans', 'leek', 'lime', 'mushroom', 'okra', 'peach', 'plum', 'pumpkin',
    'raspberry', 'strawberry', 'zucchini'
]

def preprocess_image(img_path):
    img = image.load_img(img_path, target_size=(224, 224))
    img_array = image.img_to_array(img)
    img_array = img_array / 255.0
    img_array = np.expand_dims(img_array, axis=0)
    return img_array

def predict_ingredient(img_path):
    img_array = preprocess_image(img_path)
    prediction = model.predict(img_array)
    predicted_class_index = np.argmax(prediction, axis=1)[0]
    predicted_class_label = class_labels[predicted_class_index]
    confidence = prediction[0][predicted_class_index] * 100
    return predicted_class_label, confidence

if __name__ == "__main__":
    img_path = sys.argv[1]
    ingredient, confidence = predict_ingredient(img_path)
    result = {"ingredient": ingredient, "confidence": float(confidence)}
    print(json.dumps(result))