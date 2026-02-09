"""
Simple CNN from scratch - Sometimes simpler is better!
"""

import os
import numpy as np
import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Conv2D, MaxPooling2D, Dense, Flatten, Dropout, BatchNormalization
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.callbacks import ModelCheckpoint, EarlyStopping, ReduceLROnPlateau
from tensorflow.keras.preprocessing.image import ImageDataGenerator

# Configuration
IMG_SIZE = 224
BATCH_SIZE = 32
EPOCHS = 50
DATASET_DIR = r'c:\Users\Admin\Downloads\flutter_application_1\ds'

print("=" * 60)
print("SIMPLE CNN TRAINING - FROM SCRATCH")
print("=" * 60)

# Data augmentation
train_datagen = ImageDataGenerator(
    rescale=1./255,
    rotation_range=20,
    width_shift_range=0.2,
    height_shift_range=0.2,
    horizontal_flip=True,
    vertical_flip=True,
    zoom_range=0.2,
    validation_split=0.2
)

# Training generator
train_generator = train_datagen.flow_from_directory(
    DATASET_DIR,
    target_size=(IMG_SIZE, IMG_SIZE),
    batch_size=BATCH_SIZE,
    class_mode='binary',
    subset='training',
    shuffle=True
)

# Validation generator
val_generator = train_datagen.flow_from_directory(
    DATASET_DIR,
    target_size=(IMG_SIZE, IMG_SIZE),
    batch_size=BATCH_SIZE,
    class_mode='binary',
    subset='validation',
    shuffle=False
)

print(f"\n[OK] Data loaded!")
print(f"  Training: {train_generator.samples} images")
print(f"  Validation: {val_generator.samples} images")
print(f"  Classes: {train_generator.class_indices}")

# Build simple CNN
model = Sequential([
    # Block 1
    Conv2D(32, (3, 3), activation='relu', input_shape=(IMG_SIZE, IMG_SIZE, 3)),
    BatchNormalization(),
    MaxPooling2D((2, 2)),

    # Block 2
    Conv2D(64, (3, 3), activation='relu'),
    BatchNormalization(),
    MaxPooling2D((2, 2)),

    # Block 3
    Conv2D(128, (3, 3), activation='relu'),
    BatchNormalization(),
    MaxPooling2D((2, 2)),

    # Block 4
    Conv2D(256, (3, 3), activation='relu'),
    BatchNormalization(),
    MaxPooling2D((2, 2)),

    # Dense layers
    Flatten(),
    Dense(512, activation='relu'),
    Dropout(0.5),
    Dense(256, activation='relu'),
    Dropout(0.5),
    Dense(1, activation='sigmoid')
])

print("\n[OK] Model created")
model.summary()

# Compile
model.compile(
    optimizer=Adam(learning_rate=0.0001),
    loss='binary_crossentropy',
    metrics=['accuracy', tf.keras.metrics.Precision(), tf.keras.metrics.Recall()]
)

# Callbacks
checkpoint = ModelCheckpoint(
    'simple_cnn_best.keras',
    monitor='val_accuracy',
    save_best_only=True,
    mode='max',
    verbose=1
)

early_stop = EarlyStopping(
    monitor='val_loss',
    patience=10,
    restore_best_weights=True,
    verbose=1
)

reduce_lr = ReduceLROnPlateau(
    monitor='val_loss',
    factor=0.5,
    patience=5,
    min_lr=1e-7,
    verbose=1
)

print("\n" + "=" * 60)
print("TRAINING")
print("=" * 60)

# Train
history = model.fit(
    train_generator,
    validation_data=val_generator,
    epochs=EPOCHS,
    callbacks=[checkpoint, early_stop, reduce_lr],
    verbose=1
)

print("\n" + "=" * 60)
print("TRAINING COMPLETED!")
print("=" * 60)

# Load best model
model.load_weights('simple_cnn_best.keras')

# Evaluate
print("\n[Evaluating model...]")
results = model.evaluate(val_generator, verbose=1)
print(f"\nFinal Results:")
print(f"  Loss: {results[0]:.4f}")
print(f"  Accuracy: {results[1] * 100:.2f}%")
print(f"  Precision: {results[2] * 100:.2f}%")
print(f"  Recall: {results[3] * 100:.2f}%")

# Test predictions
print("\n[Testing predictions...]")
val_generator.reset()
test_images, test_labels = next(val_generator)
predictions = model.predict(test_images[:20], verbose=0)

print("\nSample predictions:")
stone_count = 0
normal_count = 0
for i in range(20):
    true_label = int(test_labels[i])
    pred_prob = predictions[i][0]
    pred_label = 1 if pred_prob > 0.5 else 0
    status = "CORRECT" if pred_label == true_label else "WRONG"
    label_name = "stone" if true_label == 1 else "normal"
    print(f"  [{status}] True: {label_name} | Pred prob: {pred_prob:.4f} -> {('normal' if pred_label==0 else 'stone')}")

    if pred_label == 1:
        stone_count += 1
    else:
        normal_count += 1

print(f"\nPrediction distribution:")
print(f"  Predicted as normal: {normal_count}/20")
print(f"  Predicted as stone: {stone_count}/20")

if stone_count == 0:
    print("\n[ERROR] Model never predicts stones! Training failed!")
    exit(1)

# Convert to TFLite
print("\n[Converting to TFLite...]")

converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()

# Save TFLite model
tflite_path = 'kidney_stone_simple_cnn.tflite'
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
print("SUCCESS!")
print("=" * 60)
print(f"\nAccuracy: {results[1] * 100:.2f}%")
print(f"Model size: {tflite_size_mb:.2f} MB")
print(f"\nNow run: python quick_test.py")
