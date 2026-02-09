"""
Enhanced Kidney Stone Detection Model
Hybrid Approach: VGG16 Feature Extraction + XGBoost Classification
Based on research papers with improved preprocessing
"""

import os
import numpy as np
import cv2
import tensorflow as tf
from tensorflow.keras.applications import VGG16
from tensorflow.keras.models import Model, Sequential
from tensorflow.keras.layers import Dense, Dropout, GlobalAveragePooling2D, BatchNormalization
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score
import xgboost as xgb
import pickle
from pathlib import Path
import matplotlib.pyplot as plt

print("=" * 70)
print("  ENHANCED KIDNEY STONE DETECTION MODEL TRAINING")
print("  Hybrid: VGG16 Feature Extraction + XGBoost Classification")
print("=" * 70)
print(f"TensorFlow version: {tf.__version__}")
print(f"XGBoost version: {xgb.__version__}")
print()

# ============================================================================
# CONFIGURATION
# ============================================================================

SCRIPT_DIR = Path(__file__).parent
DATA_DIR = SCRIPT_DIR / 'Kidney' / 'Dataset'
MODEL_DIR = SCRIPT_DIR / 'Kidney'
MODEL_DIR.mkdir(exist_ok=True)

# Model paths
VGG_FEATURES_MODEL_PATH = MODEL_DIR / 'vgg16_feature_extractor.h5'
XGBOOST_MODEL_PATH = MODEL_DIR / 'xgboost_classifier.pkl'
HYBRID_MODEL_PATH = MODEL_DIR / 'kidney_stone_hybrid.h5'

IMG_SIZE = (224, 224)
BATCH_SIZE = 32

print(f"📁 Dataset directory: {DATA_DIR}")
print(f"💾 Models will be saved to: {MODEL_DIR}")
print()

# Check dataset
if not DATA_DIR.exists():
    print(f"❌ Error: Dataset not found at {DATA_DIR}")
    print("\n📂 Expected structure:")
    print("   Kidney/Dataset/")
    print("   ├── normal/")
    print("   │   ├── Normal_1.JPG")
    print("   │   └── ...")
    print("   └── stone/")
    print("       ├── Stone_1.JPG")
    print("       └── ...")
    exit(1)

# ============================================================================
# IMAGE PREPROCESSING WITH ENHANCEMENT
# ============================================================================

def apply_clahe(image):
    """Apply CLAHE (Contrast Limited Adaptive Histogram Equalization)"""
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

def apply_bilateral_filter(image):
    """Apply bilateral filter for noise reduction while preserving edges"""
    return cv2.bilateralFilter(image, d=9, sigmaColor=75, sigmaSpace=75)

def preprocess_image_enhanced(image_path):
    """Enhanced preprocessing with CLAHE + Bilateral filtering"""
    img = cv2.imread(str(image_path))

    if img is None:
        raise ValueError(f"Could not read image: {image_path}")

    # Step 1: Apply bilateral filter for denoising
    img = apply_bilateral_filter(img)

    # Step 2: Apply CLAHE for contrast enhancement
    img = apply_clahe(img)

    # Step 3: Resize to target size
    img = cv2.resize(img, IMG_SIZE)

    # Step 4: Normalize to [0, 1]
    img = img / 255.0

    return img

# ============================================================================
# DATA LOADING
# ============================================================================

print("📊 Loading and preprocessing dataset...")

normal_dir = DATA_DIR / 'normal'
stone_dir = DATA_DIR / 'stone'

normal_images = list(normal_dir.glob('*.[jJ][pP][gG]')) + list(normal_dir.glob('*.[jJ][pP][eE][gG]')) + list(normal_dir.glob('*.[pP][nN][gG]'))
stone_images = list(stone_dir.glob('*.[jJ][pP][gG]')) + list(stone_dir.glob('*.[jJ][pP][eE][gG]')) + list(stone_dir.glob('*.[pP][nN][gG]'))

print(f"   Normal images: {len(normal_images)}")
print(f"   Stone images: {len(stone_images)}")
print(f"   Total: {len(normal_images) + len(stone_images)}")
print()

# Load all images with enhanced preprocessing
X_data = []
y_data = []

print("🔄 Preprocessing images (CLAHE + Bilateral Filter)...")
for img_path in normal_images:
    try:
        img = preprocess_image_enhanced(img_path)
        X_data.append(img)
        y_data.append(0)  # Normal = 0
    except Exception as e:
        print(f"   ⚠️  Skipping {img_path.name}: {e}")

for img_path in stone_images:
    try:
        img = preprocess_image_enhanced(img_path)
        X_data.append(img)
        y_data.append(1)  # Stone = 1
    except Exception as e:
        print(f"   ⚠️  Skipping {img_path.name}: {e}")

X_data = np.array(X_data)
y_data = np.array(y_data)

print(f"✅ Loaded {len(X_data)} images successfully")
print(f"   Shape: {X_data.shape}")
print(f"   Labels: {len(y_data)} (Normal: {np.sum(y_data==0)}, Stone: {np.sum(y_data==1)})")
print()

# Split data
X_train, X_test, y_train, y_test = train_test_split(
    X_data, y_data, test_size=0.2, random_state=42, stratify=y_data
)

X_train, X_val, y_train, y_val = train_test_split(
    X_train, y_train, test_size=0.15, random_state=42, stratify=y_train
)

print(f"📊 Data split:")
print(f"   Training: {len(X_train)} samples")
print(f"   Validation: {len(X_val)} samples")
print(f"   Testing: {len(X_test)} samples")
print()

# ============================================================================
# PART 1: VGG16 FEATURE EXTRACTION
# ============================================================================

print("=" * 70)
print("  STEP 1: VGG16 Feature Extraction")
print("=" * 70)

# Load pretrained VGG16 (without top classification layer)
base_vgg = VGG16(
    weights='imagenet',
    include_top=False,
    input_shape=(*IMG_SIZE, 3)
)

# Freeze VGG16 layers
for layer in base_vgg.layers:
    layer.trainable = False

print("✅ VGG16 base model loaded (ImageNet weights)")
print(f"   Input shape: {base_vgg.input_shape}")
print(f"   Output shape: {base_vgg.output_shape}")
print()

# Create feature extractor model
vgg_feature_extractor = Sequential([
    base_vgg,
    GlobalAveragePooling2D(),
], name='vgg16_feature_extractor')

vgg_feature_extractor.compile(optimizer='adam', loss='binary_crossentropy')

print("🔍 Extracting features from training data...")
train_features = vgg_feature_extractor.predict(X_train, batch_size=BATCH_SIZE, verbose=1)
print(f"   Train features shape: {train_features.shape}")

print("🔍 Extracting features from validation data...")
val_features = vgg_feature_extractor.predict(X_val, batch_size=BATCH_SIZE, verbose=1)
print(f"   Validation features shape: {val_features.shape}")

print("🔍 Extracting features from test data...")
test_features = vgg_feature_extractor.predict(X_test, batch_size=BATCH_SIZE, verbose=1)
print(f"   Test features shape: {test_features.shape}")
print()

# Save VGG16 feature extractor
print(f"💾 Saving VGG16 feature extractor to: {VGG_FEATURES_MODEL_PATH}")
vgg_feature_extractor.save(VGG_FEATURES_MODEL_PATH)
print("✅ Feature extractor saved")
print()

# ============================================================================
# PART 2: XGBOOST CLASSIFICATION
# ============================================================================

print("=" * 70)
print("  STEP 2: XGBoost Classification on VGG16 Features")
print("=" * 70)

# Train XGBoost classifier
xgb_params = {
    'max_depth': 6,
    'learning_rate': 0.1,
    'n_estimators': 200,
    'objective': 'binary:logistic',
    'eval_metric': 'logloss',
    'random_state': 42,
    'use_label_encoder': False
}

print("⚙️  XGBoost Parameters:")
for key, value in xgb_params.items():
    print(f"   {key}: {value}")
print()

print("🚀 Training XGBoost classifier...")
xgb_classifier = xgb.XGBClassifier(**xgb_params)

xgb_classifier.fit(
    train_features,
    y_train,
    eval_set=[(val_features, y_val)],
    verbose=True
)

print("✅ XGBoost training complete")
print()

# Evaluate XGBoost
print("📈 Evaluating XGBoost on test set...")
y_pred = xgb_classifier.predict(test_features)
y_pred_proba = xgb_classifier.predict_proba(test_features)[:, 1]

test_accuracy = accuracy_score(y_test, y_pred)
print(f"   Test Accuracy: {test_accuracy * 100:.2f}%")
print()

print("📊 Classification Report:")
print(classification_report(y_test, y_pred, target_names=['Normal', 'Stone']))

print("🔢 Confusion Matrix:")
cm = confusion_matrix(y_test, y_pred)
print(cm)
print()

# Save XGBoost model
print(f"💾 Saving XGBoost classifier to: {XGBOOST_MODEL_PATH}")
with open(XGBOOST_MODEL_PATH, 'wb') as f:
    pickle.dump(xgb_classifier, f)
print("✅ XGBoost classifier saved")
print()

# ============================================================================
# PART 3: CREATE END-TO-END HYBRID MODEL (FOR DEPLOYMENT)
# ============================================================================

print("=" * 70)
print("  STEP 3: Creating Hybrid End-to-End Model for Deployment")
print("=" * 70)

# Fine-tune: Add a simple neural network head for end-to-end deployment
# This allows us to save a single .h5 model file

# Unfreeze last few VGG16 layers for fine-tuning
for layer in base_vgg.layers[-4:]:
    layer.trainable = True

# Build hybrid model
hybrid_model = Sequential([
    base_vgg,
    GlobalAveragePooling2D(),
    Dense(512, activation='relu'),
    BatchNormalization(),
    Dropout(0.5),
    Dense(256, activation='relu'),
    BatchNormalization(),
    Dropout(0.4),
    Dense(1, activation='sigmoid')
], name='kidney_stone_hybrid')

# Compile with lower learning rate for fine-tuning
hybrid_model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=0.0001),
    loss='binary_crossentropy',
    metrics=['accuracy', tf.keras.metrics.Precision(), tf.keras.metrics.Recall()]
)

print("✅ Hybrid model architecture:")
hybrid_model.summary()
print()

# Create data augmentation generator for training
train_datagen = ImageDataGenerator(
    rotation_range=15,
    width_shift_range=0.15,
    height_shift_range=0.15,
    zoom_range=0.1,
    horizontal_flip=True,
    fill_mode='nearest'
)

# Train hybrid model
print("🚀 Training hybrid model (fine-tuning)...")
callbacks = [
    tf.keras.callbacks.EarlyStopping(
        monitor='val_accuracy',
        patience=10,
        restore_best_weights=True,
        verbose=1
    ),
    tf.keras.callbacks.ReduceLROnPlateau(
        monitor='val_loss',
        factor=0.5,
        patience=5,
        min_lr=1e-7,
        verbose=1
    ),
    tf.keras.callbacks.ModelCheckpoint(
        str(HYBRID_MODEL_PATH),
        monitor='val_accuracy',
        save_best_only=True,
        verbose=1
    )
]

history = hybrid_model.fit(
    train_datagen.flow(X_train, y_train, batch_size=BATCH_SIZE),
    validation_data=(X_val, y_val),
    epochs=50,
    callbacks=callbacks,
    verbose=1
)

print("✅ Hybrid model training complete")
print()

# Evaluate hybrid model
print("📈 Evaluating hybrid model on test set...")
test_loss, test_acc, test_precision, test_recall = hybrid_model.evaluate(
    X_test, y_test, verbose=0
)

print(f"   Test Accuracy: {test_acc * 100:.2f}%")
print(f"   Test Precision: {test_precision * 100:.2f}%")
print(f"   Test Recall: {test_recall * 100:.2f}%")
print(f"   F1-Score: {2 * (test_precision * test_recall) / (test_precision + test_recall):.4f}")
print()

# Save final hybrid model
print(f"💾 Saving hybrid model to: {HYBRID_MODEL_PATH}")
hybrid_model.save(HYBRID_MODEL_PATH)
print("✅ Hybrid model saved")
print()

# ============================================================================
# MODEL COMPARISON
# ============================================================================

print("=" * 70)
print("  MODEL PERFORMANCE COMPARISON")
print("=" * 70)

print(f"🔵 XGBoost on VGG16 Features:")
print(f"   Test Accuracy: {test_accuracy * 100:.2f}%")
print()

print(f"🟢 Hybrid End-to-End Model:")
print(f"   Test Accuracy: {test_acc * 100:.2f}%")
print(f"   Precision: {test_precision * 100:.2f}%")
print(f"   Recall: {test_recall * 100:.2f}%")
print()

# ============================================================================
# SUMMARY
# ============================================================================

print("=" * 70)
print("  🎉 TRAINING COMPLETE!")
print("=" * 70)
print()
print("📦 Generated Models:")
print(f"   1. VGG16 Feature Extractor: {VGG_FEATURES_MODEL_PATH.name}")
print(f"   2. XGBoost Classifier: {XGBOOST_MODEL_PATH.name}")
print(f"   3. Hybrid End-to-End Model: {HYBRID_MODEL_PATH.name}")
print()
print("🚀 Next Steps:")
print("   1. Use hybrid model for deployment (single .h5 file)")
print("   2. Update ml_service.py to use the new hybrid model")
print("   3. Test predictions with ultrasound images")
print()
print("=" * 70)
