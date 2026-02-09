"""
Test the trained model to verify it's actually working
"""

import os
import numpy as np
import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator
import random

print("=" * 60)
print("TESTING TRAINED MODEL")
print("=" * 60)

# Configuration
IMG_SIZE = 224
BATCH_SIZE = 32
DATASET_DIR = r'c:\Users\Admin\Downloads\flutter_application_1\ds'

# Load the trained model
print("\nLoading model...")
try:
    model = tf.keras.models.load_model('best_kidney_model.keras')
    print("[OK] Model loaded successfully")
except Exception as e:
    print(f"[ERROR] Failed to load model: {e}")
    exit(1)

# Check model architecture
print("\nModel Summary:")
print(f"Input shape: {model.input_shape}")
print(f"Output shape: {model.output_shape}")

# Create test data generator
test_datagen = ImageDataGenerator(rescale=1./255)

test_generator = test_datagen.flow_from_directory(
    DATASET_DIR,
    target_size=(IMG_SIZE, IMG_SIZE),
    batch_size=BATCH_SIZE,
    class_mode='binary',
    shuffle=True,
    seed=42
)

print(f"\n[OK] Test generator created")
print(f"  Total samples: {test_generator.samples}")
print(f"  Classes: {test_generator.class_indices}")
print(f"  Class 0 (normal): {test_generator.class_indices.get('normal', 'NOT FOUND')}")
print(f"  Class 1 (stone): {test_generator.class_indices.get('stone', 'NOT FOUND')}")

# Evaluate on a subset
print("\n" + "=" * 60)
print("RUNNING PREDICTIONS ON SAMPLE IMAGES")
print("=" * 60)

# Get one batch
images, labels = next(test_generator)
print(f"\nBatch size: {len(labels)}")
print(f"Labels in batch: {labels}")

# Predict
predictions = model.predict(images, verbose=0)
print(f"\nRaw predictions (first 10):")
for i in range(min(10, len(predictions))):
    pred_prob = predictions[i][0]
    true_label = int(labels[i])
    pred_label = 1 if pred_prob > 0.5 else 0
    status = "CORRECT" if pred_label == true_label else "WRONG"
    print(f"  [{status}] True: {true_label} | Pred prob: {pred_prob:.4f} | Pred class: {pred_label}")

# Check if model is stuck
unique_preds = np.unique(predictions.round(4))
print(f"\nUnique prediction values: {unique_preds}")
if len(unique_preds) == 1:
    print("[ERROR] Model is stuck! Always predicting same value!")
    print("This means the model didn't learn anything.")
else:
    print("[OK] Model is making different predictions")

# Overall accuracy on this batch
predicted_classes = (predictions > 0.5).astype(int).flatten()
correct = np.sum(predicted_classes == labels)
accuracy = correct / len(labels) * 100
print(f"\nBatch accuracy: {accuracy:.2f}%")

# Check predictions distribution
num_pred_normal = np.sum(predictions <= 0.5)
num_pred_stone = np.sum(predictions > 0.5)
print(f"\nPredictions distribution:")
print(f"  Predicted as normal (prob <= 0.5): {num_pred_normal}")
print(f"  Predicted as stone (prob > 0.5): {num_pred_stone}")

# Evaluate on larger set
print("\n" + "=" * 60)
print("EVALUATING ON FULL DATASET")
print("=" * 60)

results = model.evaluate(test_generator, verbose=1)
print(f"\nFull dataset results:")
print(f"  Loss: {results[0]:.4f}")
print(f"  Accuracy: {results[1] * 100:.2f}%")
print(f"  Precision: {results[2] * 100:.2f}%")
print(f"  Recall: {results[3] * 100:.2f}%")

print("\n" + "=" * 60)
print("DIAGNOSIS")
print("=" * 60)

if results[1] < 0.6:
    print("\n[CRITICAL] Model accuracy is very low!")
    print("The model did NOT train properly.")
elif len(unique_preds) == 1:
    print("\n[CRITICAL] Model is stuck at one prediction!")
    print("The model learned to always predict the same class.")
else:
    print("\n[OK] Model appears to be working correctly!")
