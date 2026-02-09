"""
Train Random Forest using Ali-Doostali's PROVEN 99.7% accuracy method
Uses YOUR 9,416 ultrasound images!
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
print("RANDOM FOREST - ALI-DOOSTALI METHOD")
print("99.7% Accuracy Approach on YOUR Dataset")
print("=" * 60)

# Configuration
datadir = r'c:\Users\Admin\Downloads\flutter_application_1\ds'
Categories = ['normal', 'stone']  # Changed order to match (0=normal, 1=stone)

# File paths for caching
flat_data_file = os.path.join(datadir, 'flat_data.npy')
target_file = os.path.join(datadir, 'target.npy')

print("\n[STEP 1] Loading and preprocessing images...")

if os.path.exists(flat_data_file) and os.path.exists(target_file):
    # Load cached data
    print("  Loading cached preprocessed data...")
    flat_data = np.load(flat_data_file)
    target = np.load(target_file)
    print(f"  [OK] Loaded from cache")
else:
    # Process images
    flat_data_arr = []
    target_arr = []

    for i, category in enumerate(Categories):
        print(f"\n  Processing category: {category}")
        path = os.path.join(datadir, category)

        # Get all image files
        image_files = [f for f in os.listdir(path) if f.lower().endswith(('.jpg', '.jpeg', '.png'))]

        for img_file in tqdm(image_files, desc=f"  Loading {category}"):
            img_path = os.path.join(path, img_file)
            try:
                # Read and resize to 150x150x3 (Ali-Doostali method)
                img_array = imread(img_path)
                img_resized = resize(img_array, (150, 150, 3))

                # Flatten and add
                flat_data_arr.append(img_resized.flatten())
                target_arr.append(i)  # 0=normal, 1=stone

            except Exception as e:
                print(f"    Error loading {img_file}: {e}")

    # Convert to arrays
    flat_data = np.array(flat_data_arr)
    target = np.array(target_arr)

    # Cache the preprocessed data
    print("\n  Saving preprocessed data for faster future runs...")
    np.save(flat_data_file, flat_data)
    np.save(target_file, target)
    print("  [OK] Cached to flat_data.npy and target.npy")

print(f"\n[Dataset Info]")
print(f"  Total images: {len(flat_data)}")
print(f"  Image shape after flattening: {flat_data.shape}")
print(f"  Normal images (0): {np.sum(target == 0)}")
print(f"  Stone images (1): {np.sum(target == 1)}")

# Split dataset (60/40 split like Ali-Doostali)
print(f"\n[STEP 2] Splitting dataset (60% train, 40% test)...")
x_train, x_test, y_train, y_test = train_test_split(
    flat_data, target, test_size=0.40, random_state=77
)

print(f"  Training samples: {len(x_train)}")
print(f"  Testing samples: {len(x_test)}")

# Train Random Forest
print(f"\n[STEP 3] Training Random Forest Classifier...")
print("  Using Ali-Doostali's exact configuration:")
print("    n_estimators=100")
print("    criterion='gini'")
print("    random_state=77")

rf = RandomForestClassifier(
    n_estimators=100,
    random_state=77,
    verbose=1
)

rf.fit(x_train, y_train)
print("[OK] Training completed!")

# Test model
print(f"\n[STEP 4] Evaluating model...")
y_pred = rf.predict(x_test)
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
model_filename = 'RF_Classifier_Ali_Method.pkl'
with open(model_filename, 'wb') as f:
    pickle.dump(rf, f)

model_size = os.path.getsize(model_filename) / (1024*1024)
print(f"[OK] Model saved as {model_filename}")
print(f"  Model size: {model_size:.2f} MB")

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
stone_dir = os.path.join(datadir, 'stone')
normal_dir = os.path.join(datadir, 'normal')

stone_test = [f for f in os.listdir(stone_dir) if f.lower().endswith('.jpg')][:5]
normal_test = [f for f in os.listdir(normal_dir) if f.lower().endswith('.jpg')][:5]

print("\nStone images:")
for img_file in stone_test:
    img_path = os.path.join(stone_dir, img_file)
    pred = predict_single_image(img_path, rf)
    status = "CORRECT" if pred == 'stone' else "WRONG"
    print(f"  [{status}] {img_file}: {pred}")

print("\nNormal images:")
for img_file in normal_test:
    img_path = os.path.join(normal_dir, img_file)
    pred = predict_single_image(img_path, rf)
    status = "CORRECT" if pred == 'normal' else "WRONG"
    print(f"  [{status}] {img_file}: {pred}")

print("\n" + "=" * 60)
print("SUCCESS!")
print("=" * 60)
print(f"\nModel trained with {accuracy:.2f}% accuracy")
print(f"Using Ali-Doostali's proven 99.7% accuracy method")
print(f"\nModel ready: {model_filename}")
print(f"\nNext: Convert to TFLite for Flutter integration")
