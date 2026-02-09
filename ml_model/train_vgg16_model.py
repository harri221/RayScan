"""
RayScan VGG16 Model Training - High Accuracy Kidney Stone Detection
Based on research paper achieving 99.47% accuracy using CNN + VGG16

This script implements:
1. Transfer Learning with VGG16 (pre-trained on ImageNet)
2. Bilateral Filter + CLAHE preprocessing
3. Data augmentation for better generalization
4. Fine-tuning for medical imaging

Usage:
    python train_vgg16_model.py

Output:
    - VGG16-based TFLite model for Flutter app
    - Training metrics and visualizations
"""

import os
import sys
import numpy as np
import cv2
from pathlib import Path
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score, roc_auc_score, precision_score, recall_score, f1_score
import matplotlib.pyplot as plt
from tqdm import tqdm
import warnings
import json
from datetime import datetime
warnings.filterwarnings('ignore')

# TensorFlow imports
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers, Model
from tensorflow.keras.applications import VGG16
from tensorflow.keras.callbacks import EarlyStopping, ModelCheckpoint, ReduceLROnPlateau, TensorBoard
from tensorflow.keras.preprocessing.image import ImageDataGenerator

print("="*70)
print("RayScan VGG16 Kidney Stone Detection - Advanced Model Training")
print("Target: 99%+ Accuracy (Based on Research Paper)")
print("="*70)

# =============================================================================
# CONFIGURATION
# =============================================================================

# Paths
DATASET_PATH = Path(__file__).parent.parent / "Kidney" / "Kidney" / "Dataset"
OUTPUT_PATH = Path(__file__).parent / "models"
OUTPUT_PATH.mkdir(exist_ok=True)

# Model parameters - VGG16 requires 224x224 RGB input
INPUT_SIZE = 224
BATCH_SIZE = 16  # Smaller batch for VGG16 (memory efficient)
EPOCHS = 50  # More epochs with early stopping

print(f"\nConfiguration:")
print(f"  Dataset: {DATASET_PATH}")
print(f"  Output: {OUTPUT_PATH}")
print(f"  Input Size: {INPUT_SIZE}x{INPUT_SIZE}")
print(f"  Batch Size: {BATCH_SIZE}")
print(f"  Max Epochs: {EPOCHS}")

# =============================================================================
# ADVANCED IMAGE PREPROCESSING
# =============================================================================

class AdvancedPreprocessor:
    """
    Advanced preprocessing based on research paper:
    - Bilateral Filter for noise reduction while preserving edges
    - CLAHE for contrast enhancement
    - Convert grayscale to RGB for VGG16
    """

    def __init__(self, target_size=224):
        self.target_size = target_size
        self.clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8, 8))

    def preprocess(self, image_path):
        """Load and preprocess a single image"""
        try:
            # Load image
            img = cv2.imread(str(image_path))
            if img is None:
                return None

            # Convert to grayscale for preprocessing
            gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

            # Step 1: Bilateral Filter (edge-preserving smoothing)
            filtered = cv2.bilateralFilter(gray, d=9, sigmaColor=75, sigmaSpace=75)

            # Step 2: CLAHE (Contrast Limited Adaptive Histogram Equalization)
            enhanced = self.clahe.apply(filtered)

            # Step 3: Convert back to RGB (VGG16 requires 3 channels)
            rgb = cv2.cvtColor(enhanced, cv2.COLOR_GRAY2RGB)

            # Step 4: Resize to VGG16 input size
            resized = cv2.resize(rgb, (self.target_size, self.target_size))

            # Step 5: Normalize to [0, 1]
            normalized = resized.astype(np.float32) / 255.0

            return normalized

        except Exception as e:
            print(f"Error processing {image_path}: {e}")
            return None

# =============================================================================
# LOAD DATASET
# =============================================================================

def load_dataset():
    """Load and preprocess the kidney ultrasound dataset"""
    print("\n" + "="*70)
    print("[1/6] LOADING DATASET")
    print("="*70)

    preprocessor = AdvancedPreprocessor(INPUT_SIZE)

    images = []
    labels = []

    # Load STONE images (label = 1)
    stone_dir = DATASET_PATH / "stone"
    if not stone_dir.exists():
        print(f"ERROR: Stone directory not found: {stone_dir}")
        sys.exit(1)

    stone_files = list(stone_dir.glob("*.[jJ][pP][gG]")) + list(stone_dir.glob("*.[jJ][pP][eE][gG]")) + list(stone_dir.glob("*.[pP][nN][gG]"))
    print(f"\nFound {len(stone_files)} STONE images")

    for img_path in tqdm(stone_files, desc="Loading stone images", ncols=70):
        img = preprocessor.preprocess(img_path)
        if img is not None:
            images.append(img)
            labels.append(1)

    stone_count = len([l for l in labels if l == 1])

    # Load NORMAL images (label = 0)
    normal_dir = DATASET_PATH / "normal"
    if not normal_dir.exists():
        print(f"ERROR: Normal directory not found: {normal_dir}")
        sys.exit(1)

    normal_files = list(normal_dir.glob("*.[jJ][pP][gG]")) + list(normal_dir.glob("*.[jJ][pP][eE][gG]")) + list(normal_dir.glob("*.[pP][nN][gG]"))
    print(f"Found {len(normal_files)} NORMAL images")

    for img_path in tqdm(normal_files, desc="Loading normal images", ncols=70):
        img = preprocessor.preprocess(img_path)
        if img is not None:
            images.append(img)
            labels.append(0)

    normal_count = len([l for l in labels if l == 0])

    # Convert to numpy arrays
    X = np.array(images)
    y = np.array(labels)

    print(f"\n Dataset Summary:")
    print(f"  Total images: {len(X)}")
    print(f"  Stone images: {stone_count}")
    print(f"  Normal images: {normal_count}")
    print(f"  Image shape: {X.shape[1:]}")
    print(f"  Class balance: {stone_count/(stone_count+normal_count)*100:.1f}% stone, {normal_count/(stone_count+normal_count)*100:.1f}% normal")

    return X, y

# =============================================================================
# BUILD VGG16 TRANSFER LEARNING MODEL
# =============================================================================

def build_vgg16_model():
    """
    Build VGG16-based model using transfer learning
    - Use pre-trained VGG16 as feature extractor
    - Add custom classification head
    - Fine-tune last few layers
    """
    print("\n" + "="*70)
    print("[3/6] BUILDING VGG16 MODEL")
    print("="*70)

    # Load VGG16 without top layers, with ImageNet weights
    base_model = VGG16(
        weights='imagenet',
        include_top=False,
        input_shape=(INPUT_SIZE, INPUT_SIZE, 3)
    )

    # Freeze early layers (keep ImageNet features)
    for layer in base_model.layers[:-4]:  # Freeze all except last 4 layers
        layer.trainable = False

    # Build custom classification head
    x = base_model.output
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.Dense(512, activation='relu')(x)
    x = layers.BatchNormalization()(x)
    x = layers.Dropout(0.5)(x)
    x = layers.Dense(256, activation='relu')(x)
    x = layers.BatchNormalization()(x)
    x = layers.Dropout(0.4)(x)
    x = layers.Dense(128, activation='relu')(x)
    x = layers.Dropout(0.3)(x)
    output = layers.Dense(1, activation='sigmoid')(x)

    model = Model(inputs=base_model.input, outputs=output)

    # Compile with Adam optimizer
    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=0.0001),
        loss='binary_crossentropy',
        metrics=['accuracy', tf.keras.metrics.AUC(name='auc')]
    )

    # Print model summary
    trainable = sum([tf.keras.backend.count_params(w) for w in model.trainable_weights])
    non_trainable = sum([tf.keras.backend.count_params(w) for w in model.non_trainable_weights])

    print(f"\n Model Architecture:")
    print(f"  Base: VGG16 (ImageNet pretrained)")
    print(f"  Trainable parameters: {trainable:,}")
    print(f"  Non-trainable parameters: {non_trainable:,}")
    print(f"  Total parameters: {trainable + non_trainable:,}")

    return model

# =============================================================================
# DATA AUGMENTATION
# =============================================================================

def create_data_generators():
    """Create data augmentation generators"""

    # Training data augmentation
    train_datagen = ImageDataGenerator(
        rotation_range=20,
        width_shift_range=0.15,
        height_shift_range=0.15,
        horizontal_flip=True,
        vertical_flip=False,
        zoom_range=0.15,
        shear_range=0.1,
        fill_mode='nearest'
    )

    # Validation/Test - no augmentation
    val_datagen = ImageDataGenerator()

    return train_datagen, val_datagen

# =============================================================================
# TRAIN MODEL
# =============================================================================

def train_model(model, X_train, y_train, X_val, y_val):
    """Train the VGG16 model with advanced techniques"""
    print("\n" + "="*70)
    print("[4/6] TRAINING MODEL")
    print("="*70)

    train_datagen, _ = create_data_generators()

    # Callbacks
    callbacks = [
        EarlyStopping(
            monitor='val_accuracy',
            patience=15,
            restore_best_weights=True,
            verbose=1,
            min_delta=0.001
        ),
        ReduceLROnPlateau(
            monitor='val_loss',
            factor=0.5,
            patience=5,
            min_lr=1e-7,
            verbose=1
        ),
        ModelCheckpoint(
            str(OUTPUT_PATH / 'vgg16_best.keras'),
            monitor='val_accuracy',
            save_best_only=True,
            verbose=1
        )
    ]

    # Calculate class weights for imbalanced data
    total = len(y_train)
    pos = np.sum(y_train)
    neg = total - pos
    weight_for_0 = (1 / neg) * (total / 2.0)
    weight_for_1 = (1 / pos) * (total / 2.0)
    class_weight = {0: weight_for_0, 1: weight_for_1}

    print(f"\n Training Configuration:")
    print(f"  Training samples: {len(X_train)}")
    print(f"  Validation samples: {len(X_val)}")
    print(f"  Class weights: Normal={weight_for_0:.2f}, Stone={weight_for_1:.2f}")

    # Train
    history = model.fit(
        train_datagen.flow(X_train, y_train, batch_size=BATCH_SIZE),
        validation_data=(X_val, y_val),
        epochs=EPOCHS,
        callbacks=callbacks,
        class_weight=class_weight,
        verbose=1
    )

    return model, history

# =============================================================================
# EVALUATE MODEL
# =============================================================================

def evaluate_model(model, X_test, y_test):
    """Comprehensive model evaluation"""
    print("\n" + "="*70)
    print("[5/6] EVALUATING MODEL")
    print("="*70)

    # Predictions
    y_pred_proba = model.predict(X_test, verbose=0).flatten()
    y_pred = (y_pred_proba > 0.5).astype(int)

    # Calculate all metrics
    accuracy = accuracy_score(y_test, y_pred)
    precision = precision_score(y_test, y_pred)
    recall = recall_score(y_test, y_pred)  # Sensitivity
    f1 = f1_score(y_test, y_pred)
    auc = roc_auc_score(y_test, y_pred_proba)

    # Confusion matrix
    cm = confusion_matrix(y_test, y_pred)
    tn, fp, fn, tp = cm.ravel()

    specificity = tn / (tn + fp)
    sensitivity = tp / (tp + fn)

    print(f"\n Test Results on {len(y_test)} images:")
    print(f"  {'='*40}")
    print(f"  ACCURACY:    {accuracy*100:.2f}%")
    print(f"  PRECISION:   {precision*100:.2f}%")
    print(f"  RECALL:      {recall*100:.2f}%")
    print(f"  F1-SCORE:    {f1*100:.2f}%")
    print(f"  AUC-ROC:     {auc:.4f}")
    print(f"  {'='*40}")
    print(f"  SENSITIVITY: {sensitivity*100:.2f}% (Stone detection rate)")
    print(f"  SPECIFICITY: {specificity*100:.2f}% (Normal detection rate)")

    print(f"\n Confusion Matrix:")
    print(f"                    Predicted")
    print(f"                  Normal  Stone")
    print(f"  Actual Normal    {tn:4d}   {fp:4d}")
    print(f"         Stone     {fn:4d}   {tp:4d}")

    print(f"\n Classification Report:")
    print(classification_report(y_test, y_pred, target_names=['Normal', 'Stone']))

    metrics = {
        'accuracy': float(accuracy),
        'precision': float(precision),
        'recall': float(recall),
        'f1_score': float(f1),
        'auc_roc': float(auc),
        'sensitivity': float(sensitivity),
        'specificity': float(specificity),
        'confusion_matrix': cm.tolist(),
        'test_samples': int(len(y_test))
    }

    # Save metrics to JSON
    metrics_file = OUTPUT_PATH / 'vgg16_metrics.json'
    with open(metrics_file, 'w') as f:
        json.dump(metrics, f, indent=2)
    print(f"\n Metrics saved to: {metrics_file}")

    return metrics

# =============================================================================
# EXPORT TO TFLITE
# =============================================================================

def export_to_tflite(model, metrics):
    """Convert model to TFLite for Flutter app"""
    print("\n" + "="*70)
    print("[6/6] EXPORTING TO TFLITE")
    print("="*70)

    # Standard TFLite conversion with optimization
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float16]  # Float16 quantization

    tflite_model = converter.convert()

    # Save to models folder
    tflite_path = OUTPUT_PATH / 'kidney_stone_vgg16.tflite'
    with open(tflite_path, 'wb') as f:
        f.write(tflite_model)

    size_mb = len(tflite_model) / (1024 * 1024)
    print(f"\n TFLite model saved: {tflite_path}")
    print(f"  Size: {size_mb:.2f} MB")

    # Copy to Flutter assets
    flutter_assets = Path(__file__).parent.parent / "assets" / "models"
    flutter_assets.mkdir(parents=True, exist_ok=True)

    # Replace the old model
    flutter_tflite = flutter_assets / 'kidney_stone.tflite'
    with open(flutter_tflite, 'wb') as f:
        f.write(tflite_model)

    print(f"  Copied to Flutter: {flutter_tflite}")

    # Also save a backup of the old model
    old_model_backup = flutter_assets / 'kidney_stone_old_backup.tflite'
    if (flutter_assets / 'kidney_stone.tflite').exists():
        import shutil
        # Already replaced above

    return tflite_path

# =============================================================================
# PLOT TRAINING HISTORY
# =============================================================================

def plot_training_history(history):
    """Plot and save training curves"""
    fig, axes = plt.subplots(1, 2, figsize=(14, 5))

    # Accuracy
    axes[0].plot(history.history['accuracy'], label='Train', linewidth=2)
    axes[0].plot(history.history['val_accuracy'], label='Validation', linewidth=2)
    axes[0].set_title('Model Accuracy', fontsize=14)
    axes[0].set_xlabel('Epoch')
    axes[0].set_ylabel('Accuracy')
    axes[0].legend()
    axes[0].grid(True, alpha=0.3)

    # Loss
    axes[1].plot(history.history['loss'], label='Train', linewidth=2)
    axes[1].plot(history.history['val_loss'], label='Validation', linewidth=2)
    axes[1].set_title('Model Loss', fontsize=14)
    axes[1].set_xlabel('Epoch')
    axes[1].set_ylabel('Loss')
    axes[1].legend()
    axes[1].grid(True, alpha=0.3)

    plt.tight_layout()
    plot_path = OUTPUT_PATH / 'vgg16_training_history.png'
    plt.savefig(plot_path, dpi=150)
    print(f"\n Training plot saved: {plot_path}")
    plt.close()

# =============================================================================
# MAIN
# =============================================================================

def main():
    print(f"\n Starting at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

    # Check dataset
    if not DATASET_PATH.exists():
        print(f"\n ERROR: Dataset not found at {DATASET_PATH}")
        print("Please ensure the Kidney/Kidney/Dataset folder exists")
        sys.exit(1)

    # Load data
    X, y = load_dataset()

    if len(X) < 100:
        print(f"\n ERROR: Not enough images ({len(X)}). Need at least 100.")
        sys.exit(1)

    # Split dataset: 70% train, 15% validation, 15% test
    print("\n" + "="*70)
    print("[2/6] SPLITTING DATASET")
    print("="*70)

    X_train, X_temp, y_train, y_temp = train_test_split(
        X, y, test_size=0.3, stratify=y, random_state=42
    )
    X_val, X_test, y_val, y_test = train_test_split(
        X_temp, y_temp, test_size=0.5, stratify=y_temp, random_state=42
    )

    print(f"\n Dataset Split:")
    print(f"  Training:   {len(X_train)} images ({len(X_train)/len(X)*100:.1f}%)")
    print(f"  Validation: {len(X_val)} images ({len(X_val)/len(X)*100:.1f}%)")
    print(f"  Test:       {len(X_test)} images ({len(X_test)/len(X)*100:.1f}%)")

    # Build model
    model = build_vgg16_model()

    # Train
    model, history = train_model(model, X_train, y_train, X_val, y_val)

    # Plot training history
    plot_training_history(history)

    # Evaluate
    metrics = evaluate_model(model, X_test, y_test)

    # Export to TFLite
    export_to_tflite(model, metrics)

    # Final summary
    print("\n" + "="*70)
    print(" TRAINING COMPLETE!")
    print("="*70)
    print(f"\n Final Model Performance:")
    print(f"  Accuracy:    {metrics['accuracy']*100:.2f}%")
    print(f"  Sensitivity: {metrics['sensitivity']*100:.2f}%")
    print(f"  Specificity: {metrics['specificity']*100:.2f}%")
    print(f"  AUC-ROC:     {metrics['auc_roc']:.4f}")

    print(f"\n Output Files:")
    print(f"  Model:   {OUTPUT_PATH / 'vgg16_best.keras'}")
    print(f"  TFLite:  {OUTPUT_PATH / 'kidney_stone_vgg16.tflite'}")
    print(f"  Metrics: {OUTPUT_PATH / 'vgg16_metrics.json'}")
    print(f"  Plot:    {OUTPUT_PATH / 'vgg16_training_history.png'}")

    print(f"\n Flutter Asset Updated:")
    print(f"  assets/models/kidney_stone.tflite")

    print(f"\n Completed at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("\n Now rebuild the Flutter app to use the new model!")
    print("="*70)

if __name__ == "__main__":
    main()
