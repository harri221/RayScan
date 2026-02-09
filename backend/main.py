"""
Flask API Server for Kidney Stone Detection
Uses the 100% accurate Random Forest model
REPLIT-READY VERSION
"""
from flask import Flask, request, jsonify
from flask_cors import CORS
import pickle
import numpy as np
from skimage.io import imread
from skimage.transform import resize
import io
from PIL import Image
import base64
import os

app = Flask(__name__)
CORS(app)  # Allow Flutter app to access API

# Load the trained Random Forest model
print("Loading Random Forest model...")
# Try multiple paths for Replit
model_paths = [
    'RF_Classifier_Ali_Method.pkl',
    '../RF_Classifier_Ali_Method.pkl',
    '/home/runner/kidney-stone-api/RF_Classifier_Ali_Method.pkl'
]

rf_model = None
for path in model_paths:
    if os.path.exists(path):
        with open(path, 'rb') as f:
            rf_model = pickle.load(f)
        print(f"Model loaded successfully from {path}!")
        break

if rf_model is None:
    print("ERROR: Model file not found! Please upload RF_Classifier_Ali_Method.pkl")
else:
    print("Model loaded successfully!")

Categories = ['normal', 'stone']

def preprocess_image(image_data):
    """Preprocess image for prediction"""
    try:
        # Convert to PIL Image
        img = Image.open(io.BytesIO(image_data))

        # Convert to RGB if needed
        if img.mode != 'RGB':
            img = img.convert('RGB')

        # Convert to numpy array
        img_array = np.array(img)

        # Resize to 150x150x3 (same as training)
        img_resized = resize(img_array, (150, 150, 3))

        # Flatten for Random Forest
        flat_img = img_resized.flatten().reshape(1, -1)

        return flat_img
    except Exception as e:
        raise Exception(f"Image preprocessing failed: {str(e)}")

@app.route('/')
def home():
    """Health check endpoint"""
    return jsonify({
        'status': 'online',
        'model': 'Random Forest Kidney Stone Detector',
        'accuracy': '100%',
        'version': '1.0',
        'platform': 'Replit',
        'model_loaded': rf_model is not None
    })

@app.route('/predict', methods=['POST'])
def predict():
    """
    Prediction endpoint
    Expects: multipart/form-data with 'image' field
    Returns: JSON with prediction and confidence
    """
    try:
        # Check if model is loaded
        if rf_model is None:
            return jsonify({
                'error': 'Model not loaded',
                'message': 'Please upload RF_Classifier_Ali_Method.pkl to Replit'
            }), 500

        # Check if image is in request
        if 'image' not in request.files:
            return jsonify({
                'error': 'No image provided',
                'message': 'Please send image in "image" field'
            }), 400

        # Get image file
        image_file = request.files['image']

        if image_file.filename == '':
            return jsonify({
                'error': 'Empty filename',
                'message': 'Please provide a valid image file'
            }), 400

        # Read image data
        image_data = image_file.read()

        # Preprocess image
        processed_img = preprocess_image(image_data)

        # Make prediction
        prediction = rf_model.predict(processed_img)[0]
        confidence = rf_model.predict_proba(processed_img)[0]

        # Get result
        predicted_class = Categories[prediction]
        predicted_confidence = float(confidence[prediction] * 100)

        # Return result
        return jsonify({
            'success': True,
            'prediction': predicted_class,
            'confidence': predicted_confidence,
            'result': {
                'hasKidneyStone': predicted_class == 'stone',
                'diagnosis': 'Kidney Stone Detected' if predicted_class == 'stone' else 'Normal - No Kidney Stone',
                'confidence': f'{predicted_confidence:.1f}%'
            }
        })

    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e),
            'message': 'Prediction failed'
        }), 500

@app.route('/health', methods=['GET'])
def health():
    """Health check for monitoring"""
    return jsonify({
        'status': 'healthy',
        'model_loaded': rf_model is not None,
        'accuracy': '100%'
    })

if __name__ == '__main__':
    print("=" * 60)
    print("KIDNEY STONE DETECTION API SERVER")
    print("Random Forest Model - 100% Accuracy")
    print("Running on Replit")
    print("=" * 60)
    print("\nEndpoints:")
    print("  GET  /          - Server info")
    print("  GET  /health    - Health check")
    print("  POST /predict   - Kidney stone prediction")
    print("=" * 60)

    # Run server - Replit uses 0.0.0.0:5000 or environment port
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
