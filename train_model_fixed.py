"""
FIXED Kidney Stone Detection Model Training
With proper validation and monitoring
"""

import os
import numpy as np
import tensorflow as tf
from tensorflow.keras.applications import EfficientNetB0
from tensorflow.keras.models import Model
from tensorflow.keras.layers import Dense, GlobalAveragePooling2D, Dropout
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.callbacks import ModelCheckpoint, EarlyStopping, ReduceLROnPlateau
from tensorflow.keras.preprocessing.image import ImageDataGenerator

# Configuration
IMG_SIZE = 224
BATCH_SIZE = 32
EPOCHS_PHASE1 = 20  # Reduced to avoid overfitting
EPOCHS_PHASE2 = 10
DATASET_DIR = r'c:\Users\Admin\Downloads\flutter_application_1\ds'

print("=" * 60)
print("FIXED KIDNEY STONE DETECTION MODEL TRAINING")
print("=" * 60)

# Data augmentation
train_datagen = ImageDataGenerator(
    rescale=1./255,
    rotation_range=20,
    width_shift_range=0.2,
    height_shift_range=0.2,
    horizontal_flip=True,
    vertical_flip=True,  # Medical images can be flipped
    zoom_range=0.2,
    shear_range=0.1,
    fill_mode='nearest',
    validation_split=0.2
)

test_datagen = ImageDataGenerator(rescale=1./255)

print("\n[STEP 1] Loading dataset...")

# Training generator
train_generator = train_datagen.flow_from_directory(
    DATASET_DIR,
    target_size=(IMG_SIZE, IMG_SIZE),
    batch_size=BATCH_SIZE,
    class_mode='binary',
    subset='training',
    shuffle=True,
    seed=42
)

# Validation generator
val_generator = train_datagen.flow_from_directory(
    DATASET_DIR,
    target_size=(IMG_SIZE, IMG_SIZE),
    batch_size=BATCH_SIZE,
    class_mode='binary',
    subset='validation',
    shuffle=False,
    seed=42
)

print(f"\n[OK] Data loaded!")
print(f"  Training samples: {train_generator.samples}")
print(f"  Validation samples: {val_generator.samples}")
print(f"  Class indices: {train_generator.class_indices}")
print(f"  -> 'normal' = class {train_generator.class_indices['normal']}")
print(f"  -> 'stone' = class {train_generator.class_indices['stone']}")

# Verify we have both classes
train_labels = train_generator.classes
val_labels = val_generator.classes
print(f"\n[Verification] Training set:")
print(f"  Class 0 (normal): {np.sum(train_labels == 0)} images")
print(f"  Class 1 (stone): {np.sum(train_labels == 1)} images")
print(f"[Verification] Validation set:")
print(f"  Class 0 (normal): {np.sum(val_labels == 0)} images")
print(f"  Class 1 (stone): {np.sum(val_labels == 1)} images")

def build_model():
    """Build EfficientNet-B0 based model"""
    print("\n[STEP 2] Building model...")

    # Load pre-trained EfficientNet-B0
    base_model = EfficientNetB0(
        include_top=False,
        weights='imagenet',
        input_shape=(IMG_SIZE, IMG_SIZE, 3)
    )

    # Freeze base model initially
    base_model.trainable = False

    # Add custom classification head
    x = base_model.output
    x = GlobalAveragePooling2D()(x)
    x = Dropout(0.4)(x)  # Increased dropout
    x = Dense(128, activation='relu', kernel_regularizer=tf.keras.regularizers.l2(0.01))(x)
    x = Dropout(0.4)(x)
    predictions = Dense(1, activation='sigmoid', name='output')(x)

    model = Model(inputs=base_model.input, outputs=predictions)

    print(f"[OK] Model created")
    print(f"  Total params: {model.count_params():,}")

    return model, base_model

# Build model
model, base_model = build_model()

# Compile model with class weights to handle any imbalance
class_weight = {0: 1.0, 1: 1.0}  # Equal weights

model.compile(
    optimizer=Adam(learning_rate=0.0001),  # Lower initial LR
    loss='binary_crossentropy',
    metrics=['accuracy', tf.keras.metrics.Precision(), tf.keras.metrics.Recall()]
)

# Callbacks
checkpoint = ModelCheckpoint(
    'best_kidney_model_fixed.keras',
    monitor='val_loss',  # Monitor loss, not accuracy
    save_best_only=True,
    mode='min',
    verbose=1
)

early_stop = EarlyStopping(
    monitor='val_loss',
    patience=7,
    restore_best_weights=True,
    verbose=1
)

reduce_lr = ReduceLROnPlateau(
    monitor='val_loss',
    factor=0.5,
    patience=3,
    min_lr=1e-7,
    verbose=1
)

print("\n" + "=" * 60)
print("PHASE 1: TRAINING WITH FROZEN BASE")
print("=" * 60)

# Phase 1: Train with frozen base
history1 = model.fit(
    train_generator,
    validation_data=val_generator,
    epochs=EPOCHS_PHASE1,
    callbacks=[checkpoint, early_stop, reduce_lr],
    class_weight=class_weight,
    verbose=1
)

print("\n" + "=" * 60)
print("PHASE 2: FINE-TUNING")
print("=" * 60)

# Unfreeze base model for fine-tuning
base_model.trainable = True

# Recompile with lower learning rate
model.compile(
    optimizer=Adam(learning_rate=0.00001),  # Very low LR for fine-tuning
    loss='binary_crossentropy',
    metrics=['accuracy', tf.keras.metrics.Precision(), tf.keras.metrics.Recall()]
)

# Phase 2: Fine-tune
history2 = model.fit(
    train_generator,
    validation_data=val_generator,
    epochs=EPOCHS_PHASE2,
    callbacks=[checkpoint, reduce_lr],
    class_weight=class_weight,
    verbose=1
)

print("\n" + "=" * 60)
print("TRAINING COMPLETED!")
print("=" * 60)

# Load best model
model.load_weights('best_kidney_model_fixed.keras')

# Evaluate
print("\n[STEP 3] Evaluating model...")
results = model.evaluate(val_generator, verbose=1)
print(f"\nFinal Results:")
print(f"  Loss: {results[0]:.4f}")
print(f"  Accuracy: {results[1] * 100:.2f}%")
print(f"  Precision: {results[2] * 100:.2f}%")
print(f"  Recall: {results[3] * 100:.2f}%")

# Test on a few samples to ensure it's working
print("\n[STEP 4] Testing on sample images...")
val_generator.reset()
test_images, test_labels = next(val_generator)
predictions = model.predict(test_images[:10], verbose=0)

print("\nSample predictions:")
for i in range(10):
    true_label = int(test_labels[i])
    pred_prob = predictions[i][0]
    pred_label = 1 if pred_prob > 0.5 else 0
    status = "CORRECT" if pred_label == true_label else "WRONG"
    print(f"  [{status}] True: {true_label} | Pred: {pred_prob:.4f} -> class {pred_label}")

# Check if model is stuck
unique_preds = len(np.unique(predictions.round(2)))
if unique_preds < 3:
    print("\n[WARNING] Model might be stuck! Very few unique predictions.")
else:
    print(f"\n[OK] Model is making varied predictions ({unique_preds} unique values)")

# Convert to TFLite
print("\n[STEP 5] Converting to TFLite...")

converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()

# Save TFLite model
tflite_path = 'kidney_stone_fixed.tflite'
with open(tflite_path, 'wb') as f:
    f.write(tflite_model)

tflite_size_mb = os.path.getsize(tflite_path) / (1024 * 1024)
print(f"[OK] TFLite model saved: {tflite_path} ({tflite_size_mb:.2f} MB)")

# Copy to assets folder
assets_dir = r'c:\Users\Admin\Downloads\flutter_application_1\assets\models'
os.makedirs(assets_dir, exist_ok=True)
assets_path = os.path.join(assets_dir, 'kidney_stone.tflite')

import shutil
shutil.copy(tflite_path, assets_path)
print(f"[OK] Model copied to: {assets_path}")

print("\n" + "=" * 60)
print("DONE!")
print("=" * 60)
print(f"\nNext: Run 'python quick_test.py' to verify the model works!")
