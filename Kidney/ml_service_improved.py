"""
Enhanced Flask ML Service for Kidney Stone Detection
Uses Hybrid VGG16+XGBoost model with improved preprocessing
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
from pathlib import Path

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Configuration
MODEL_DIR = Path(__file__).parent / 'Kidney'
MODEL_PATH = MODEL_DIR / 'kidney_stone_hybrid.h5'
FALLBACK_MODEL_PATH = MODEL_DIR / 'kidney_stone_cnn.h5'

UPLOAD_FOLDER = 'uploads/ml_temp'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}
IMG_SIZE = 224

# Create upload folder if it doesn't exist
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# ============================================================================
# IMAGE PREPROCESSING (Enhanced - matches training)
# ============================================================================

def apply_clahe(image):
    """Apply CLAHE (Contrast Limited Adaptive Histogram Equalization)"""
    try:
        # Convert to LAB color space
        lab = cv2.cvtColor(image, cv2.COLOR_BGR2LAB)
        l, a, b = cv2.split(lab)

        # Apply CLAHE to L channel
        clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8, 8))
        cl = clahe.apply(l)

        # Merge channels
        enhanced = cv2.merge((cl, a, b))
        enhanced = cv2.cvtColor(enhanced, cv2.COLOR_LAB2BGR)

        return enhanced
    except Exception as e:
        logger.warning(f"CLAHE failed: {e}, returning original image")
        return image

def apply_bilateral_filter(image):
    """Apply bilateral filter for noise reduction while preserving edges"""
    try:
        return cv2.bilateralFilter(image, d=9, sigmaColor=75, sigmaSpace=75)
    except Exception as e:
        logger.warning(f"Bilateral filter failed: {e}, returning original image")
        return image

def preprocess_image_enhanced(image_path):
    """
    Enhanced preprocessing with CLAHE + Bilateral filtering
    Matches the training preprocessing pipeline
    """
    try:
        # Read image
        img = cv2.imread(str(image_path))

        if img is None:
            raise ValueError("Could not read image")

        # Step 1: Apply bilateral filter for denoising
        img = apply_bilateral_filter(img)

        # Step 2: Apply CLAHE for contrast enhancement
        img = apply_clahe(img)

        # Step 3: Resize to model input size
        img = cv2.resize(img, (IMG_SIZE, IMG_SIZE))

        # Step 4: Normalize pixel values to [0, 1]
        img = img / 255.0

        # Add batch dimension
        img = np.expand_dims(img, axis=0)

        return img

    except Exception as e:
        logger.error(f"Error preprocessing image: {e}")
        raise

def preprocess_image_basic(image_path):
    """
    Basic preprocessing (fallback for old model)
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

# ============================================================================
# MODEL LOADING
# ============================================================================

logger.info("=" * 60)
logger.info("  Kidney Stone Detection ML Service - Enhanced")
logger.info("=" * 60)

# Try loading hybrid model first
model = None
model_type = None
use_enhanced_preprocessing = False

logger.info(f"Attempting to load hybrid model from: {MODEL_PATH}")
if MODEL_PATH.exists():
    try:
        model = load_model(str(MODEL_PATH), compile=False)
        model_type = "Hybrid VGG16+XGBoost"
        use_enhanced_preprocessing = True
        logger.info("✅ Hybrid model loaded successfully!")
        logger.info(f"   Model input shape: {model.input_shape}")
        logger.info(f"   Model output shape: {model.output_shape}")
        logger.info(f"   Using enhanced preprocessing: CLAHE + Bilateral Filter")
    except Exception as e:
        logger.error(f"Failed to load hybrid model: {e}")
        model = None

# Fallback to old model if hybrid not available
if model is None:
    logger.info(f"Attempting to load fallback model from: {FALLBACK_MODEL_PATH}")
    if FALLBACK_MODEL_PATH.exists():
        try:
            model = load_model(str(FALLBACK_MODEL_PATH), compile=False)
            model_type = "CNN (Original)"
            use_enhanced_preprocessing = False
            logger.info("✅ Fallback model loaded successfully!")
            logger.info(f"   Model input shape: {model.input_shape}")
            logger.info(f"   Model output shape: {model.output_shape}")
            logger.info(f"   Using basic preprocessing")
        except Exception as e:
            logger.error(f"Failed to load fallback model: {e}")
            model = None

if model is None:
    logger.error("❌ No model could be loaded!")
    logger.info("\nPlease run one of the following:")
    logger.info("   1. python train_improved_model.py  (for hybrid model)")
    logger.info("   2. python retrain_model.py  (for basic CNN)")
else:
    logger.info(f"\n✅ Service ready with: {model_type}")

logger.info("=" * 60)

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def predict_kidney_stone(image_path):
    """
    Predict kidney stone presence from ultrasound image
    """
    if model is None:
        raise Exception("Model not loaded")

    try:
        # Preprocess image based on model type
        if use_enhanced_preprocessing:
            processed_img = preprocess_image_enhanced(image_path)
            logger.info("   Using enhanced preprocessing (CLAHE + Bilateral)")
        else:
            processed_img = preprocess_image_basic(image_path)
            logger.info("   Using basic preprocessing")

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
            'has_kidney_stone': bool(has_stone),
            'model_type': model_type,
            'preprocessing': 'enhanced' if use_enhanced_preprocessing else 'basic'
        }

        logger.info(f"✅ Prediction: {result['prediction']} (Confidence: {result['confidence']}%)")

        return result

    except Exception as e:
        logger.error(f"Error during prediction: {e}")
        raise

# ============================================================================
# API ENDPOINTS
# ============================================================================

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'model_loaded': model is not None,
        'model_type': model_type,
        'enhanced_preprocessing': use_enhanced_preprocessing,
        'service': 'RayScan Kidney Stone Detection - Enhanced'
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

        logger.info(f"📷 Processing image: {filename}")

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
        'service': 'RayScan Kidney Stone Detection - Enhanced',
        'version': '2.0.0',
        'model_type': model_type,
        'enhanced_preprocessing': use_enhanced_preprocessing,
        'model': 'kidney_stone_hybrid.h5' if use_enhanced_preprocessing else 'kidney_stone_cnn.h5',
        'endpoints': {
            '/health': 'GET - Health check',
            '/predict': 'POST - Predict kidney stone from ultrasound image'
        }
    }), 200

# ============================================================================
# MAIN
# ============================================================================

if __name__ == '__main__':
    if model is None:
        logger.error("❌ Cannot start service - no model loaded")
        logger.info("\nPlease train a model first:")
        logger.info("   python train_improved_model.py")
        exit(1)

    # Run Flask app
    port = int(os.environ.get('ML_SERVICE_PORT', 5000))
    logger.info(f"\n🚀 Starting ML Service on port {port}")
    logger.info(f"   Model: {model_type}")
    logger.info(f"   Preprocessing: {'Enhanced (CLAHE+Bilateral)' if use_enhanced_preprocessing else 'Basic'}")
    logger.info(f"\n✅ Service is ready!")

    app.run(host='0.0.0.0', port=port, debug=False)
