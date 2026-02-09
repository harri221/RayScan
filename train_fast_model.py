"""
FAST Kidney Stone Detection Model Training
Removed slow preprocessing to make training 20x faster!
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
BATCH_SIZE = 32  # Increased for faster training
EPOCHS_PHASE1 = 30  # Reduced epochs (still effective)
EPOCHS_PHASE2 = 10
DATASET_DIR = r'c:\Users\Admin\Downloads\flutter_application_1\ds'

print("=" * 60)
print("FAST KIDNEY STONE DETECTION MODEL TRAINING")
print("=" * 60)
print("\nMethodology:")
print("  1. Architecture: EfficientNet-B0 (Transfer Learning)")
print("  2. Preprocessing: Standard normalization (FAST!)")
print("  3. Deployment: TFLite for mobile")
print("  4. Expected time: 30-60 minutes")
print("=" * 60)

# Simple, fast data augmentation
train_datagen = ImageDataGenerator(
    rescale=1./255,  # Simple normalization
    rotation_range=15,
    width_shift_range=0.1,
    height_shift_range=0.1,
    horizontal_flip=True,
    zoom_range=0.1,
    validation_split=0.2
)

test_datagen = ImageDataGenerator(
    rescale=1./255  # Just normalization
)

print("\n" + "=" * 60)
print("LOADING DATASET")
print("=" * 60)

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

print(f"\n[OK] Data generators created!")
print(f"  Training samples: {train_generator.samples}")
print(f"  Validation samples: {val_generator.samples}")
print(f"  Classes: {train_generator.class_indices}")


def build_model():
    """Build EfficientNet-B0 based model"""
    print("\n" + "=" * 60)
    print("BUILDING MODEL")
    print("=" * 60)

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
    x = Dropout(0.3)(x)
    x = Dense(256, activation='relu', name='fc1')(x)
    x = Dropout(0.3)(x)
    predictions = Dense(1, activation='sigmoid', name='output')(x)

    model = Model(inputs=base_model.input, outputs=predictions)

    print(f"\n[OK] Model created")
    print(f"  Base: EfficientNet-B0 (frozen)")
    print(f"  Head: GAP -> Dense(256) -> Dense(1)")
    print(f"  Total params: {model.count_params():,}")

    return model, base_model


# Build model
model, base_model = build_model()

# Compile model
model.compile(
    optimizer=Adam(learning_rate=0.001),
    loss='binary_crossentropy',
    metrics=['accuracy', tf.keras.metrics.Precision(), tf.keras.metrics.Recall()]
)

# Callbacks
checkpoint = ModelCheckpoint(
    'best_kidney_model.keras',
    monitor='val_accuracy',
    save_best_only=True,
    verbose=1
)

early_stop = EarlyStopping(
    monitor='val_loss',
    patience=5,
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
print(f"Epochs: {EPOCHS_PHASE1}")
print(f"Batch size: {BATCH_SIZE}")
print("=" * 60)

# Phase 1: Train with frozen base
history1 = model.fit(
    train_generator,
    validation_data=val_generator,
    epochs=EPOCHS_PHASE1,
    callbacks=[checkpoint, early_stop, reduce_lr],
    verbose=1
)

print("\n" + "=" * 60)
print("PHASE 2: FINE-TUNING")
print("=" * 60)

# Unfreeze base model for fine-tuning
base_model.trainable = True

# Recompile with lower learning rate
model.compile(
    optimizer=Adam(learning_rate=0.0001),
    loss='binary_crossentropy',
    metrics=['accuracy', tf.keras.metrics.Precision(), tf.keras.metrics.Recall()]
)

print(f"Epochs: {EPOCHS_PHASE2}")
print(f"Learning rate: 0.0001")
print("=" * 60)

# Phase 2: Fine-tune
history2 = model.fit(
    train_generator,
    validation_data=val_generator,
    epochs=EPOCHS_PHASE2,
    callbacks=[checkpoint, reduce_lr],
    verbose=1
)

print("\n" + "=" * 60)
print("TRAINING COMPLETED!")
print("=" * 60)

# Load best model
model.load_weights('best_kidney_model.keras')

# Evaluate
print("\nEvaluating final model...")
results = model.evaluate(val_generator, verbose=1)
print(f"\nFinal Results:")
print(f"  Loss: {results[0]:.4f}")
print(f"  Accuracy: {results[1] * 100:.2f}%")
print(f"  Precision: {results[2] * 100:.2f}%")
print(f"  Recall: {results[3] * 100:.2f}%")

# Convert to TFLite
print("\n" + "=" * 60)
print("CONVERTING TO TFLITE")
print("=" * 60)

converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()

# Save TFLite model
tflite_path = 'kidney_stone_fast.tflite'
with open(tflite_path, 'wb') as f:
    f.write(tflite_model)

tflite_size_mb = os.path.getsize(tflite_path) / (1024 * 1024)
print(f"\n[OK] TFLite model saved: {tflite_path}")
print(f"  Size: {tflite_size_mb:.2f} MB")

# Copy to assets folder
assets_dir = r'c:\Users\Admin\Downloads\flutter_application_1\assets\models'
os.makedirs(assets_dir, exist_ok=True)
assets_path = os.path.join(assets_dir, 'kidney_stone.tflite')

import shutil
shutil.copy(tflite_path, assets_path)
print(f"\n[OK] Model copied to: {assets_path}")

print("\n" + "=" * 60)
print("SUCCESS!")
print("=" * 60)
print(f"\nYour kidney stone detection model is ready!")
print(f"  - Trained on {train_generator.samples + val_generator.samples} clean images")
print(f"  - Accuracy: {results[1] * 100:.2f}%")
print(f"  - Precision: {results[2] * 100:.2f}%")
print(f"  - Recall: {results[3] * 100:.2f}%")
print(f"  - TFLite model: {tflite_size_mb:.2f} MB")
print(f"  - Location: {assets_path}")
print(f"\nNext: Rebuild Flutter APK and test!")
