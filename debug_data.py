"""Debug data loading to find the issue"""
import os
from tensorflow.keras.preprocessing.image import ImageDataGenerator

DATASET_DIR = r'c:\Users\Admin\Downloads\flutter_application_1\ds'
IMG_SIZE = 224
BATCH_SIZE = 32

# Check dataset structure
print("Dataset structure:")
print(f"  Dataset dir: {DATASET_DIR}")
print(f"  Subdirs: {os.listdir(DATASET_DIR)}")

for subdir in ['normal', 'stone']:
    path = os.path.join(DATASET_DIR, subdir)
    if os.path.exists(path):
        files = [f for f in os.listdir(path) if f.lower().endswith(('.jpg', '.jpeg', '.png'))]
        print(f"  {subdir}: {len(files)} images")

# Test data generator
train_datagen = ImageDataGenerator(rescale=1./255, validation_split=0.2)

train_gen = train_datagen.flow_from_directory(
    DATASET_DIR,
    target_size=(IMG_SIZE, IMG_SIZE),
    batch_size=BATCH_SIZE,
    class_mode='binary',
    subset='training',
    shuffle=True,
    seed=42
)

val_gen = train_datagen.flow_from_directory(
    DATASET_DIR,
    target_size=(IMG_SIZE, IMG_SIZE),
    batch_size=BATCH_SIZE,
    class_mode='binary',
    subset='validation',
    shuffle=False,
    seed=42
)

print(f"\nClass indices: {train_gen.class_indices}")
print(f"\nTraining set:")
print(f"  Total: {train_gen.samples}")
print(f"  Class 0: {sum(train_gen.classes == 0)}")
print(f"  Class 1: {sum(train_gen.classes == 1)}")

print(f"\nValidation set:")
print(f"  Total: {val_gen.samples}")
print(f"  Class 0: {sum(val_gen.classes == 0)}")
print(f"  Class 1: {sum(val_gen.classes == 1)}")

# Check first batch
print("\n=== CHECKING FIRST FEW BATCHES ===")
for i in range(3):
    images, labels = next(val_gen)
    unique, counts = np.unique(labels, return_counts=True)
    print(f"Validation Batch {i+1}: {dict(zip(unique, counts))}")

import numpy as np
val_gen.reset()
for i in range(3):
    images, labels = next(train_gen)
    unique, counts = np.unique(labels, return_counts=True)
    print(f"Training Batch {i+1}: {dict(zip(unique, counts))}")
