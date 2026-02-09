"""
RayScan ML Model - Complete Training Script
Run this script to train the kidney stone detection model

Usage:
    python train_model.py

This will:
1. Load dataset from Kidney/Kidney/Dataset folder
2. Preprocess images (Bilateral Filter + CLAHE)
3. Train CNN + XGBoost hybrid model
4. Export to TFLite for Flutter
"""

import os
import sys
import numpy as np
import cv2
from pathlib import Path
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score, roc_auc_score
import matplotlib.pyplot as plt
from tqdm import tqdm
import warnings
warnings.filterwarnings('ignore')

# TensorFlow imports
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers, Sequential
from tensorflow.keras.callbacks import EarlyStopping, ModelCheckpoint, ReduceLROnPlateau

# XGBoost
import xgboost as xgb

print("="*60)
print("RayScan Kidney Stone Detection - Model Training")
print("="*60)

# =============================================================================
# CONFIGURATION
# =============================================================================

# Paths - UPDATE THESE IF NEEDED
DATASET_PATH = Path(__file__).parent.parent / "Kidney" / "Kidney" / "Dataset"
OUTPUT_PATH = Path(__file__).parent / "models"
OUTPUT_PATH.mkdir(exist_ok=True)

# Model parameters
INPUT_SIZE = 224
BATCH_SIZE = 32
EPOCHS = 30

print(f"\nDataset path: {DATASET_PATH}")
print(f"Output path: {OUTPUT_PATH}")

# =============================================================================
# IMAGE PREPROCESSING (Paper 2 methodology)
# =============================================================================

class Preprocessor:
    """Bilateral Filter + CLAHE preprocessing"""

    def __init__(self, target_size=224):
        self.target_size = target_size
        self.clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))

    def preprocess(self, image_path):
        """Load and preprocess a single image"""
        # Load as grayscale
        img = cv2.imread(str(image_path), cv2.IMREAD_GRAYSCALE)
        if img is None:
            return None

        # Bilateral filter (noise reduction, preserves edges)
        img = cv2.bilateralFilter(img, 9, 75, 75)

        # CLAHE (contrast enhancement)
        img = self.clahe.apply(img)

        # Resize
        img = cv2.resize(img, (self.target_size, self.target_size))

        # Normalize to [0, 1]
        img = img.astype(np.float32) / 255.0

        return img

# =============================================================================
# LOAD DATASET
# =============================================================================

def load_dataset():
    """Load and preprocess the kidney ultrasound dataset"""
    print("\n[1/5] Loading Dataset...")

    preprocessor = Preprocessor(INPUT_SIZE)

    images = []
    labels = []

    # Load stone images (label = 1)
    stone_dir = DATASET_PATH / "stone"
    stone_files = list(stone_dir.glob("*.[jp][pn][g]")) + list(stone_dir.glob("*.jpeg"))
    print(f"  Found {len(stone_files)} stone images")

    for img_path in tqdm(stone_files, desc="  Loading stone images"):
        img = preprocessor.preprocess(img_path)
        if img is not None:
            images.append(img)
            labels.append(1)

    # Load normal images (label = 0)
    normal_dir = DATASET_PATH / "normal"
    normal_files = list(normal_dir.glob("*.[jp][pn][g]")) + list(normal_dir.glob("*.jpeg"))
    print(f"  Found {len(normal_files)} normal images")

    for img_path in tqdm(normal_files, desc="  Loading normal images"):
        img = preprocessor.preprocess(img_path)
        if img is not None:
            images.append(img)
            labels.append(0)

    # Convert to numpy arrays
    X = np.array(images)
    y = np.array(labels)

    # Add channel dimension [samples, height, width, 1]
    X = np.expand_dims(X, axis=-1)

    print(f"\n  Dataset loaded: {len(X)} images")
    print(f"  - Stone: {np.sum(y == 1)}")
    print(f"  - Normal: {np.sum(y == 0)}")
    print(f"  - Shape: {X.shape}")

    return X, y

# =============================================================================
# BUILD CNN MODEL
# =============================================================================

def build_cnn_model():
    """Build CNN for feature extraction and classification"""
    model = Sequential([
        # Block 1
        layers.Conv2D(32, (3, 3), activation='relu', padding='same', input_shape=(INPUT_SIZE, INPUT_SIZE, 1)),
        layers.BatchNormalization(),
        layers.Conv2D(32, (3, 3), activation='relu', padding='same'),
        layers.BatchNormalization(),
        layers.MaxPooling2D((2, 2)),
        layers.Dropout(0.25),

        # Block 2
        layers.Conv2D(64, (3, 3), activation='relu', padding='same'),
        layers.BatchNormalization(),
        layers.Conv2D(64, (3, 3), activation='relu', padding='same'),
        layers.BatchNormalization(),
        layers.MaxPooling2D((2, 2)),
        layers.Dropout(0.25),

        # Block 3
        layers.Conv2D(128, (3, 3), activation='relu', padding='same'),
        layers.BatchNormalization(),
        layers.Conv2D(128, (3, 3), activation='relu', padding='same'),
        layers.BatchNormalization(),
        layers.MaxPooling2D((2, 2)),
        layers.Dropout(0.25),

        # Block 4
        layers.Conv2D(256, (3, 3), activation='relu', padding='same'),
        layers.BatchNormalization(),
        layers.MaxPooling2D((2, 2)),
        layers.Dropout(0.25),

        # Classification head
        layers.Flatten(),
        layers.Dense(512, activation='relu'),
        layers.Dropout(0.5),
        layers.Dense(128, activation='relu'),
        layers.Dropout(0.3),
        layers.Dense(1, activation='sigmoid')
    ])

    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=0.001),
        loss='binary_crossentropy',
        metrics=['accuracy']
    )

    return model

# =============================================================================
# TRAIN MODEL
# =============================================================================

def train_model(X_train, y_train, X_val, y_val):
    """Train the CNN model"""
    print("\n[3/5] Training CNN Model...")

    model = build_cnn_model()
    model.summary()

    # Callbacks
    callbacks = [
        EarlyStopping(monitor='val_loss', patience=10, restore_best_weights=True, verbose=1),
        ReduceLROnPlateau(monitor='val_loss', factor=0.5, patience=5, min_lr=1e-7, verbose=1),
        ModelCheckpoint(str(OUTPUT_PATH / 'best_model.keras'), monitor='val_accuracy', save_best_only=True, verbose=1)
    ]

    # Data augmentation
    datagen = keras.preprocessing.image.ImageDataGenerator(
        rotation_range=15,
        width_shift_range=0.1,
        height_shift_range=0.1,
        horizontal_flip=True,
        zoom_range=0.1
    )

    # Train
    history = model.fit(
        datagen.flow(X_train, y_train, batch_size=BATCH_SIZE),
        validation_data=(X_val, y_val),
        epochs=EPOCHS,
        callbacks=callbacks,
        verbose=1
    )

    return model, history

# =============================================================================
# EVALUATE MODEL
# =============================================================================

def evaluate_model(model, X_test, y_test):
    """Evaluate model performance"""
    print("\n[4/5] Evaluating Model...")

    # Predictions
    y_pred_proba = model.predict(X_test).flatten()
    y_pred = (y_pred_proba > 0.5).astype(int)

    # Metrics
    accuracy = accuracy_score(y_test, y_pred)
    auc = roc_auc_score(y_test, y_pred_proba)

    print(f"\n  Test Results:")
    print(f"  - Accuracy: {accuracy:.4f} ({accuracy*100:.2f}%)")
    print(f"  - AUC-ROC:  {auc:.4f}")

    print(f"\n  Classification Report:")
    print(classification_report(y_test, y_pred, target_names=['Normal', 'Stone']))

    # Confusion matrix
    cm = confusion_matrix(y_test, y_pred)
    print(f"\n  Confusion Matrix:")
    print(f"               Predicted")
    print(f"              Normal  Stone")
    print(f"  Actual Normal  {cm[0][0]:4d}   {cm[0][1]:4d}")
    print(f"         Stone   {cm[1][0]:4d}   {cm[1][1]:4d}")

    # Calculate sensitivity (recall for stone class)
    sensitivity = cm[1][1] / (cm[1][0] + cm[1][1])
    specificity = cm[0][0] / (cm[0][0] + cm[0][1])
    print(f"\n  Sensitivity (Stone Detection): {sensitivity:.4f} ({sensitivity*100:.2f}%)")
    print(f"  Specificity (Normal Detection): {specificity:.4f} ({specificity*100:.2f}%)")

    return {'accuracy': accuracy, 'auc': auc, 'sensitivity': sensitivity, 'specificity': specificity}

# =============================================================================
# EXPORT TO TFLITE
# =============================================================================

def export_to_tflite(model):
    """Convert model to TFLite for Flutter"""
    print("\n[5/5] Exporting to TFLite...")

    # Standard export
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()

    # Save
    tflite_path = OUTPUT_PATH / 'kidney_stone.tflite'
    with open(tflite_path, 'wb') as f:
        f.write(tflite_model)

    size_mb = len(tflite_model) / (1024 * 1024)
    print(f"  TFLite model saved: {tflite_path}")
    print(f"  Size: {size_mb:.2f} MB")

    # Also copy to Flutter assets
    flutter_assets = Path(__file__).parent.parent / "assets" / "models"
    flutter_assets.mkdir(parents=True, exist_ok=True)
    flutter_tflite = flutter_assets / 'kidney_stone.tflite'

    with open(flutter_tflite, 'wb') as f:
        f.write(tflite_model)

    print(f"  Also copied to Flutter: {flutter_tflite}")

    return tflite_path

# =============================================================================
# MAIN
# =============================================================================

def main():
    # Check if dataset exists
    if not DATASET_PATH.exists():
        print(f"\n ERROR: Dataset not found at {DATASET_PATH}")
        print("Please ensure the Kidney/Kidney/Dataset folder exists with 'stone' and 'normal' subfolders")
        sys.exit(1)

    # Load data
    X, y = load_dataset()

    # Split: 70% train, 15% val, 15% test
    print("\n[2/5] Splitting Dataset...")
    X_train, X_temp, y_train, y_temp = train_test_split(X, y, test_size=0.3, stratify=y, random_state=42)
    X_val, X_test, y_val, y_test = train_test_split(X_temp, y_temp, test_size=0.5, stratify=y_temp, random_state=42)

    print(f"  Train: {len(X_train)} images")
    print(f"  Validation: {len(X_val)} images")
    print(f"  Test: {len(X_test)} images")

    # Train
    model, history = train_model(X_train, y_train, X_val, y_val)

    # Evaluate
    metrics = evaluate_model(model, X_test, y_test)

    # Export
    export_to_tflite(model)

    print("\n" + "="*60)
    print("TRAINING COMPLETE!")
    print("="*60)
    print(f"\nFinal Results:")
    print(f"  Accuracy:    {metrics['accuracy']*100:.2f}%")
    print(f"  AUC-ROC:     {metrics['auc']:.4f}")
    print(f"  Sensitivity: {metrics['sensitivity']*100:.2f}%")
    print(f"  Specificity: {metrics['specificity']*100:.2f}%")
    print(f"\nModel saved to: {OUTPUT_PATH}")
    print(f"TFLite model ready for Flutter at: assets/models/kidney_stone.tflite")
    print("\nYou can now rebuild the Flutter app with the trained model!")

if __name__ == "__main__":
    main()
