"""
Flask ML Service for Kidney Stone Detection
Serves the kidney_stone_cnn.h5 model for predictions
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import numpy as np
import cv2
import tensorflow as tf
from tensorflow.keras.models import load_model
import os
from werkzeug.utils import secure_filename
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Configuration
MODEL_PATH = os.path.join(os.path.dirname(__file__), 'Kidney', 'kidney_stone_cnn.h5')
UPLOAD_FOLDER = 'uploads/ml_temp'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}
IMG_SIZE = 224

# Create upload folder if it doesn't exist
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# Load the trained model
logger.info(f"Loading model from: {MODEL_PATH}")
try:
    # Try loading with compile=False to avoid compatibility issues
    model = load_model(MODEL_PATH, compile=False)
    logger.info("Model loaded successfully!")
    logger.info(f"Model input shape: {model.input_shape}")
    logger.info(f"Model output shape: {model.output_shape}")
except Exception as e:
    logger.error(f"Failed to load model: {e}")
    logger.info("Trying alternative loading method...")
    try:
        # Alternative: Load using tf.keras
        import tensorflow as tf
        model = tf.keras.models.load_model(MODEL_PATH, compile=False)
        logger.info("Model loaded successfully using alternative method!")
    except Exception as e2:
        logger.error(f"Alternative loading also failed: {e2}")
        model = None

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def preprocess_image(image_path):
    """
    Preprocess image for kidney stone detection
    Args:
        image_path: Path to the ultrasound image
    Returns:
        Preprocessed image ready for model prediction
    """
    try:
        # Read image
        img = cv2.imread(image_path)

        if img is None:
            raise ValueError("Could not read image")

        # Resize to model input size
        img = cv2.resize(img, (IMG_SIZE, IMG_SIZE))

        # Normalize pixel values to [0, 1]
        img = img / 255.0

        # Add batch dimension
        img = np.expand_dims(img, axis=0)

        return img

    except Exception as e:
        logger.error(f"Error preprocessing image: {e}")
        raise

def predict_kidney_stone(image_path):
    """
    Predict kidney stone presence from ultrasound image
    Args:
        image_path: Path to ultrasound image
    Returns:
        dict with prediction results
    """
    if model is None:
        raise Exception("Model not loaded")

    try:
        # Preprocess image
        processed_img = preprocess_image(image_path)

        # Make prediction
        prediction = model.predict(processed_img, verbose=0)[0][0]

        # Determine result
        has_stone = prediction > 0.5
        confidence = float(prediction if has_stone else 1 - prediction)

        result = {
            'prediction': 'Stone Detected' if has_stone else 'Normal Kidney',
            'confidence': round(confidence * 100, 2),
            'confidence_score': round(confidence, 4),
            'raw_score': float(prediction),
            'has_kidney_stone': bool(has_stone)
        }

        logger.info(f"Prediction: {result['prediction']} (Confidence: {result['confidence']}%)")

        return result

    except Exception as e:
        logger.error(f"Error during prediction: {e}")
        raise

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'model_loaded': model is not None,
        'service': 'Kidney Stone Detection ML Service'
    }), 200

@app.route('/predict', methods=['POST'])
def predict():
    """
    Endpoint to predict kidney stone from uploaded image
    Expected: multipart/form-data with 'image' file
    Returns: JSON with prediction results
    """
    try:
        # Check if image file is present
        if 'image' not in request.files:
            return jsonify({'error': 'No image file provided'}), 400

        file = request.files['image']

        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400

        if not allowed_file(file.filename):
            return jsonify({'error': 'Invalid file type. Only PNG, JPG, JPEG allowed'}), 400

        # Save uploaded file temporarily
        filename = secure_filename(file.filename)
        filepath = os.path.join(UPLOAD_FOLDER, filename)
        file.save(filepath)

        logger.info(f"Processing image: {filename}")

        # Make prediction
        result = predict_kidney_stone(filepath)

        # Clean up temporary file
        try:
            os.remove(filepath)
        except:
            pass

        return jsonify({
            'success': True,
            'data': result
        }), 200

    except Exception as e:
        logger.error(f"Prediction error: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/', methods=['GET'])
def index():
    """Root endpoint"""
    return jsonify({
        'service': 'RayScan Kidney Stone Detection ML Service',
        'version': '1.0.0',
        'model': 'kidney_stone_cnn.h5',
        'endpoints': {
            '/health': 'Health check',
            '/predict': 'POST - Predict kidney stone from ultrasound image'
        }
    }), 200

if __name__ == '__main__':
    if model is None:
        logger.error("Cannot start service - model failed to load")
        exit(1)

    # Run Flask app
    port = int(os.environ.get('ML_SERVICE_PORT', 5000))
    logger.info(f"Starting ML Service on port {port}")
    app.run(host='0.0.0.0', port=port, debug=False)
