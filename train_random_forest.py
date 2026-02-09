"""
Train Random Forest model - 99.7% accuracy approach
Based on pranavikolluru's successful implementation
"""
import pandas as pd
import os
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
import pickle
from skimage.transform import resize
from skimage.io import imread
from tqdm import tqdm

print("=" * 60)
print("RANDOM FOREST KIDNEY STONE DETECTION")
print("99.7% Accuracy Method - No PyTorch!")
print("=" * 60)

# Configuration
DATASET_DIR = r'c:\Users\Admin\Downloads\flutter_application_1\ds'
Categories = ['normal', 'stone']

print(f"\n[STEP 1] Loading images from {DATASET_DIR}...")

flat_data_arr = []
target_arr = []

for category_idx, category in enumerate(Categories):
    print(f"\nProcessing {category} images...")
    category_path = os.path.join(DATASET_DIR, category)

    image_files = [f for f in os.listdir(category_path) if f.lower().endswith(('.jpg', '.jpeg', '.png'))]

    for img_file in tqdm(image_files, desc=f"Loading {category}"):
        img_path = os.path.join(category_path, img_file)
        try:
            # Read and resize image
            img_array = imread(img_path)
            img_resized = resize(img_array, (150, 150, 3))

            # Flatten and add to dataset
            flat_data_arr.append(img_resized.flatten())
            target_arr.append(category_idx)
        except Exception as e:
            print(f"  Error loading {img_file}: {e}")

# Convert to numpy arrays
flat_data = np.array(flat_data_arr)
target = np.array(target_arr)

print(f"\n[OK] Dataset loaded!")
print(f"  Total images: {len(flat_data)}")
print(f"  Image shape: {flat_data.shape}")
print(f"  Normal images (0): {np.sum(target == 0)}")
print(f"  Stone images (1): {np.sum(target == 1)}")

# Split dataset
print(f"\n[STEP 2] Splitting dataset (60% train, 40% test)...")
X_train, X_test, y_train, y_test = train_test_split(
    flat_data, target, test_size=0.40, random_state=77
)

print(f"  Training samples: {len(X_train)}")
print(f"  Testing samples: {len(X_test)}")

# Train Random Forest
print(f"\n[STEP 3] Training Random Forest Classifier...")
rf = RandomForestClassifier(
    n_estimators=100,
    random_state=77,
    verbose=1
)

rf.fit(X_train, y_train)
print("[OK] Training completed!")

# Test model
print(f"\n[STEP 4] Testing model...")
y_pred = rf.predict(X_test)
accuracy = accuracy_score(y_test, y_pred) * 100

print(f"\n" + "=" * 60)
print("RESULTS")
print("=" * 60)
print(f"\nAccuracy: {accuracy:.2f}%")

# Confusion Matrix
cm = confusion_matrix(y_test, y_pred)
print(f"\nConfusion Matrix:")
print(f"                Predicted")
print(f"              Normal  Stone")
print(f"Actual Normal   {cm[0][0]:4d}   {cm[0][1]:4d}")
print(f"       Stone    {cm[1][0]:4d}   {cm[1][1]:4d}")

# Classification Report
print(f"\nClassification Report:")
print(classification_report(y_test, y_pred, target_names=['Normal', 'Stone']))

# Save model
print(f"\n[STEP 5] Saving model...")
model_filename = 'RF_Classifier.pkl'
with open(model_filename, 'wb') as f:
    pickle.dump(rf, f)

print(f"[OK] Model saved as {model_filename}")
print(f"  Model size: {os.path.getsize(model_filename) / (1024*1024):.2f} MB")

# Test on sample images
print(f"\n[STEP 6] Testing on sample images...")

def predict_single_image(img_path, model):
    """Predict kidney stone from image"""
    img = imread(img_path)
    img_resize = resize(img, (150, 150, 3))
    flat_img = img_resize.flatten().reshape(1, -1)
    prediction = model.predict(flat_img)[0]
    return Categories[prediction]

# Test a few images
stone_dir = os.path.join(DATASET_DIR, 'stone')
normal_dir = os.path.join(DATASET_DIR, 'normal')

stone_test = [f for f in os.listdir(stone_dir) if f.lower().endswith('.jpg')][:3]
normal_test = [f for f in os.listdir(normal_dir) if f.lower().endswith('.jpg')][:3]

print("\nStone images:")
for img_file in stone_test:
    img_path = os.path.join(stone_dir, img_file)
    pred = predict_single_image(img_path, rf)
    status = "✓" if pred == 'stone' else "✗"
    print(f"  {status} {img_file}: {pred}")

print("\nNormal images:")
for img_file in normal_test:
    img_path = os.path.join(normal_dir, img_file)
    pred = predict_single_image(img_path, rf)
    status = "✓" if pred == 'normal' else "✗"
    print(f"  {status} {img_file}: {pred}")

print("\n" + "=" * 60)
print("SUCCESS!")
print("=" * 60)
print(f"\nModel trained with {accuracy:.2f}% accuracy")
print(f"Ready to integrate into Flutter app!")
print(f"\nNext step: Convert to TFLite or use as Python backend")
