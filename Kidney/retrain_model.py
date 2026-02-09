"""
Retrain Kidney Stone Detection CNN Model
Compatible with TensorFlow 2.15
"""

import os
import tensorflow as tf
from tensorflow.keras import layers, models
from tensorflow.keras.preprocessing.image import ImageDataGenerator
import numpy as np

print("=" * 60)
print("  Kidney Stone CNN Model Training")
print("=" * 60)
print(f"TensorFlow version: {tf.__version__}")
print()

# Paths
SCRIPT_DIR = os.path.dirname(__file__)
DATA_DIR = os.path.join(SCRIPT_DIR, 'Kidney', 'Dataset')
MODEL_PATH = os.path.join(SCRIPT_DIR, 'Kidney', 'kidney_stone_cnn.h5')

print(f"Dataset directory: {DATA_DIR}")
print(f"Model will be saved to: {MODEL_PATH}")
print()

# Check if dataset exists
if not os.path.exists(DATA_DIR):
    print(f"Error: Dataset not found at {DATA_DIR}")
    print("\nExpected structure:")
    print("   Kidney/Dataset/")
    print("   +-- normal/")
    print("   |   +-- Normal_1.JPG")
    print("   |   +-- Normal_2.JPG")
    print("   |   +-- ...")
    print("   +-- stone/")
    print("       +-- Stone_1.JPG")
    print("       +-- Stone_2.JPG")
    print("       +-- ...")
    exit(1)

# Parameters
IMG_SIZE = (224, 224)
BATCH_SIZE = 32
EPOCHS = 25  # Increased epochs with better early stopping

print("Training Parameters:")
print(f"   Image size: {IMG_SIZE}")
print(f"   Batch size: {BATCH_SIZE}")
print(f"   Epochs: {EPOCHS}")
print()

# Data Augmentation + Normalization
print("Setting up data generators...")
datagen = ImageDataGenerator(
    rescale=1./255,
    validation_split=0.2,
    rotation_range=20,
    width_shift_range=0.2,
    height_shift_range=0.2,
    zoom_range=0.15,
    horizontal_flip=True,
    fill_mode='nearest'
)

train_gen = datagen.flow_from_directory(
    DATA_DIR,
    target_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    class_mode='binary',
    subset='training',
    shuffle=True
)

val_gen = datagen.flow_from_directory(
    DATA_DIR,
    target_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    class_mode='binary',
    subset='validation',
    shuffle=False
)

print(f"Training samples: {train_gen.samples}")
print(f"Validation samples: {val_gen.samples}")
print(f"Classes: {train_gen.class_indices}")
print()

# Build CNN Model (Reduced complexity to prevent overfitting)
print("Building CNN model...")
model = models.Sequential([
    layers.Input(shape=(*IMG_SIZE, 3)),  # Explicit input layer

    layers.Conv2D(32, (3, 3), activation='relu', padding='same'),
    layers.BatchNormalization(),
    layers.MaxPooling2D(2, 2),
    layers.Dropout(0.3),

    layers.Conv2D(64, (3, 3), activation='relu', padding='same'),
    layers.BatchNormalization(),
    layers.MaxPooling2D(2, 2),
    layers.Dropout(0.4),

    layers.Conv2D(128, (3, 3), activation='relu', padding='same'),
    layers.BatchNormalization(),
    layers.MaxPooling2D(2, 2),
    layers.Dropout(0.5),

    layers.Flatten(),
    layers.Dense(128, activation='relu'),  # Reduced from 256
    layers.BatchNormalization(),
    layers.Dropout(0.6),  # Increased dropout
    layers.Dense(1, activation='sigmoid')
], name='kidney_stone_cnn')

# Compile model with lower learning rate
model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=0.00005),  # Reduced LR
    loss='binary_crossentropy',
    metrics=['accuracy', tf.keras.metrics.Precision(), tf.keras.metrics.Recall()]
)

print("Model built successfully!")
print()
model.summary()
print()

# Callbacks (Improved for better generalization)
callbacks = [
    tf.keras.callbacks.EarlyStopping(
        monitor='val_loss',
        patience=7,  # Increased patience
        restore_best_weights=True,
        verbose=1,
        min_delta=0.001  # Minimum change to qualify as improvement
    ),
    tf.keras.callbacks.ReduceLROnPlateau(
        monitor='val_loss',
        factor=0.5,
        patience=4,  # Increased patience
        min_lr=1e-7,
        verbose=1
    ),
    tf.keras.callbacks.ModelCheckpoint(
        MODEL_PATH,
        monitor='val_accuracy',
        save_best_only=True,
        verbose=1
    )
]

# Train model
print("Starting training...")
print("=" * 60)

history = model.fit(
    train_gen,
    validation_data=val_gen,
    epochs=EPOCHS,
    callbacks=callbacks,
    verbose=1
)

print()
print("=" * 60)
print("Training complete!")
print("=" * 60)
print()

# Final metrics
final_train_acc = history.history['accuracy'][-1]
final_val_acc = history.history['val_accuracy'][-1]
final_train_loss = history.history['loss'][-1]
final_val_loss = history.history['val_loss'][-1]

print("Final Metrics:")
print(f"   Training Accuracy: {final_train_acc:.4f}")
print(f"   Validation Accuracy: {final_val_acc:.4f}")
print(f"   Training Loss: {final_train_loss:.4f}")
print(f"   Validation Loss: {final_val_loss:.4f}")
print()

# Save final model
print(f"Saving final model to: {MODEL_PATH}")
model.save(MODEL_PATH)
print("Model saved successfully!")
print()

# Test loading
print("Testing model loading...")
try:
    test_model = tf.keras.models.load_model(MODEL_PATH, compile=False)
    print("Model loads successfully!")
    print(f"   Input shape: {test_model.input_shape}")
    print(f"   Output shape: {test_model.output_shape}")
except Exception as e:
    print(f"Error loading model: {e}")

print()
print("=" * 60)
print("  All Done!")
print("=" * 60)
print()
print("Next steps:")
print("1. Run: python ml_service.py")
print("2. ML service will start on port 5000")
print("3. Test with Flutter app!")
print()
