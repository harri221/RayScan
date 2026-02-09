"""
Thoroughly test the Random Forest model
Test on 100 random images to verify it REALLY works
"""
import pickle
import numpy as np
from pathlib import Path
from skimage.io import imread
from skimage.transform import resize
import random

print("=" * 60)
print("THOROUGH RANDOM FOREST MODEL TESTING")
print("Testing on 100 random images")
print("=" * 60)

# Load the trained model
print("\n[STEP 1] Loading trained model...")
with open('RF_Classifier_Ali_Method.pkl', 'rb') as f:
    rf = pickle.load(f)
print("[OK] Model loaded")

# Define categories
Categories = ['normal', 'stone']

def predict_image(img_path, model):
    """Predict kidney stone from image"""
    try:
        img = imread(img_path)
        img_resize = resize(img, (150, 150, 3))
        flat_img = img_resize.flatten().reshape(1, -1)
        prediction = model.predict(flat_img)[0]
        confidence = model.predict_proba(flat_img)[0]
        return Categories[prediction], confidence[prediction] * 100
    except Exception as e:
        return None, 0

# Get test images
stone_dir = Path(r'c:\Users\Admin\Downloads\flutter_application_1\ds\stone')
normal_dir = Path(r'c:\Users\Admin\Downloads\flutter_application_1\ds\normal')

# Get 50 random samples from each
stone_samples = random.sample(list(stone_dir.glob("*.jpg")), min(50, len(list(stone_dir.glob("*.jpg")))))
normal_samples = random.sample(list(normal_dir.glob("*.jpg")), min(50, len(list(normal_dir.glob("*.jpg")))))

print(f"\n[STEP 2] Testing on {len(stone_samples)} stone + {len(normal_samples)} normal images...")

# Test stone images
print("\n" + "=" * 60)
print("TESTING STONE IMAGES (should all predict 'stone')")
print("=" * 60)

stone_correct = 0
stone_confidences = []

for i, img_path in enumerate(stone_samples, 1):
    pred, conf = predict_image(img_path, rf)
    if pred:
        is_correct = (pred == 'stone')
        stone_correct += is_correct
        stone_confidences.append(conf)

        status = "CORRECT" if is_correct else "WRONG"

        if i <= 10 or not is_correct:  # Show first 10 and any errors
            print(f"{i:2d}. [{status}] {img_path.name}")
            print(f"     Prediction: {pred} ({conf:.1f}% confidence)")

if len(stone_samples) > 10:
    print(f"... ({len(stone_samples) - 10} more stone images tested)")

# Test normal images
print("\n" + "=" * 60)
print("TESTING NORMAL IMAGES (should all predict 'normal')")
print("=" * 60)

normal_correct = 0
normal_confidences = []

for i, img_path in enumerate(normal_samples, 1):
    pred, conf = predict_image(img_path, rf)
    if pred:
        is_correct = (pred == 'normal')
        normal_correct += is_correct
        normal_confidences.append(conf)

        status = "CORRECT" if is_correct else "WRONG"

        if i <= 10 or not is_correct:  # Show first 10 and any errors
            print(f"{i:2d}. [{status}] {img_path.name}")
            print(f"     Prediction: {pred} ({conf:.1f}% confidence)")

if len(normal_samples) > 10:
    print(f"... ({len(normal_samples) - 10} more normal images tested)")

# Calculate metrics
total_tested = len(stone_samples) + len(normal_samples)
total_correct = stone_correct + normal_correct
accuracy = (total_correct / total_tested) * 100
sensitivity = (stone_correct / len(stone_samples)) * 100
specificity = (normal_correct / len(normal_samples)) * 100

avg_stone_conf = np.mean(stone_confidences) if stone_confidences else 0
avg_normal_conf = np.mean(normal_confidences) if normal_confidences else 0

print("\n" + "=" * 60)
print("FINAL RESULTS")
print("=" * 60)

print(f"\n{'Metric':<30} {'Result':<20}")
print("-" * 60)
print(f"{'Total Images Tested':<30} {total_tested}")
print(f"{'Total Correct':<30} {total_correct}")
print(f"{'Overall Accuracy':<30} {accuracy:.2f}%")
print()
print(f"{'Stone Detection':<30} {stone_correct}/{len(stone_samples)} ({sensitivity:.2f}%)")
print(f"{'Average Stone Confidence':<30} {avg_stone_conf:.1f}%")
print()
print(f"{'Normal Detection':<30} {normal_correct}/{len(normal_samples)} ({specificity:.2f}%)")
print(f"{'Average Normal Confidence':<30} {avg_normal_conf:.1f}%")

# Show any errors
stone_errors = len(stone_samples) - stone_correct
normal_errors = len(normal_samples) - normal_correct

if stone_errors > 0:
    print(f"\n{'Stone Images Missed':<30} {stone_errors}")
if normal_errors > 0:
    print(f"{'Normal Images Missed':<30} {normal_errors}")

print("\n" + "=" * 60)
print("VERDICT")
print("=" * 60)

if accuracy == 100:
    print("\n🎉 PERFECT! Model has 100% accuracy on random test samples!")
    print("   This model REALLY WORKS!")
elif accuracy >= 95:
    print(f"\n✅ EXCELLENT! {accuracy:.1f}% accuracy on random samples")
    print("   Model works very well!")
elif accuracy >= 90:
    print(f"\n✓ GOOD! {accuracy:.1f}% accuracy")
    print("  Model works well with minor errors")
elif accuracy >= 80:
    print(f"\n~ MODERATE. {accuracy:.1f}% accuracy")
    print("  Model works but has some issues")
else:
    print(f"\n✗ POOR. Only {accuracy:.1f}% accuracy")
    print("  Model has significant problems")

print("\n" + "=" * 60)
print("CONFIDENCE ANALYSIS")
print("=" * 60)

if avg_stone_conf >= 95 and avg_normal_conf >= 95:
    print("\n✅ Model is VERY CONFIDENT in its predictions!")
    print(f"   Stone: {avg_stone_conf:.1f}% confidence")
    print(f"   Normal: {avg_normal_conf:.1f}% confidence")
elif avg_stone_conf >= 80 and avg_normal_conf >= 80:
    print("\n✓ Model is confident in most predictions")
    print(f"   Stone: {avg_stone_conf:.1f}% confidence")
    print(f"   Normal: {avg_normal_conf:.1f}% confidence")
else:
    print("\n⚠ Model has low confidence in some predictions")
    print(f"   Stone: {avg_stone_conf:.1f}% confidence")
    print(f"   Normal: {avg_normal_conf:.1f}% confidence")

print("\n" + "=" * 60)
print("NEXT STEPS")
print("=" * 60)

if accuracy >= 95:
    print("""
This Random Forest model WORKS on your ultrasound images!

Options for integration:
1. Python Backend + Flutter App (Recommended)
   - Host model on server (Flask/FastAPI)
   - Flutter app sends images via API
   - Server returns predictions
   - Pros: Works immediately, model stays on server
   - Cons: Requires internet connection

2. Convert to TensorFlow + TFLite
   - Train MobileNetV2 on same dataset
   - Use this RF model's predictions as validation
   - Convert to TFLite for offline use
   - Pros: Works offline in Flutter
   - Cons: Needs additional training time

3. Desktop/Web Demo
   - Create Streamlit/Gradio web app
   - Show model working in presentation
   - Use for demonstration purposes
""")
else:
    print("""
Model needs improvement before deployment.
Consider:
1. Review misclassified images
2. Check data quality
3. Try different training parameters
""")
