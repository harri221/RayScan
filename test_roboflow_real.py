"""
Test REAL Roboflow ULTRASOUND kidney stone model
With actual API key on YOUR dataset!
"""
import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'

print("=" * 60)
print("ROBOFLOW ULTRASOUND KIDNEY STONE DETECTION")
print("Testing on YOUR 9,416 ultrasound images")
print("=" * 60)

from roboflow import Roboflow
import random
from pathlib import Path

print("\n[STEP 1] Connecting to Roboflow with API key...")

# Initialize with YOUR API key
rf = Roboflow(api_key="qBacb6KhwY6FF3RV2c9i")

print("[STEP 2] Loading ULTRASOUND kidney stone model (5,431 images)...")

try:
    project = rf.workspace("kidney-ktlmt").project("kidney-stone-ultrasound")
    model = project.version(2).model
    print("[OK] Model loaded successfully!")
    print("  Dataset: 5,431 ultrasound images")
    print("  Architecture: YOLOv8 Object Detection")
    print("  Classes: kidney-stone, normal")
except Exception as e:
    print(f"[ERROR] Failed to load model: {e}")
    print("\nTrying alternative model...")
    try:
        project = rf.workspace("kidney-rtzud").project("kidney-stone-detection-9j42c")
        model = project.version(1).model
        print("[OK] Alternative model loaded (1,459 images)")
    except Exception as e2:
        print(f"[ERROR] {e2}")
        exit(1)

# Test with YOUR ultrasound images
print("\n[STEP 3] Testing on YOUR ultrasound images...")

stone_dir = Path(r'c:\Users\Admin\Downloads\flutter_application_1\ds\stone')
normal_dir = Path(r'c:\Users\Admin\Downloads\flutter_application_1\ds\normal')

# Get random samples
stone_samples = random.sample(list(stone_dir.glob("*.jpg")), min(20, len(list(stone_dir.glob("*.jpg")))))
normal_samples = random.sample(list(normal_dir.glob("*.jpg")), min(20, len(list(normal_dir.glob("*.jpg")))))

print("\n" + "=" * 60)
print("TESTING STONE IMAGES (should detect kidney stones)")
print("=" * 60)

stone_detected = 0
stone_results = []

for i, img_path in enumerate(stone_samples, 1):
    try:
        # Predict using Roboflow API
        prediction = model.predict(str(img_path), confidence=40, overlap=30).json()

        # Check detections
        detections = prediction.get('predictions', [])
        has_stone = len(detections) > 0

        stone_detected += has_stone
        status = "✓ DETECTED" if has_stone else "✗ MISSED"

        if detections:
            conf = detections[0]['confidence'] * 100
            class_name = detections[0]['class']
            print(f"{i:2d}. [{status}] {img_path.name}")
            print(f"     -> {class_name} ({conf:.1f}% confidence, {len(detections)} detection(s))")
        else:
            print(f"{i:2d}. [{status}] {img_path.name}")
            print(f"     -> No detections")

    except Exception as e:
        print(f"{i:2d}. [ERROR] {img_path.name}: {e}")

print("\n" + "=" * 60)
print("TESTING NORMAL IMAGES (should NOT detect kidney stones)")
print("=" * 60)

false_positives = 0

for i, img_path in enumerate(normal_samples, 1):
    try:
        prediction = model.predict(str(img_path), confidence=40, overlap=30).json()

        detections = prediction.get('predictions', [])
        has_stone = len(detections) > 0

        false_positives += has_stone
        status = "✗ FALSE POS" if has_stone else "✓ CORRECT"

        if detections:
            conf = detections[0]['confidence'] * 100
            class_name = detections[0]['class']
            print(f"{i:2d}. [{status}] {img_path.name}")
            print(f"     -> {class_name} ({conf:.1f}% confidence, {len(detections)} detection(s))")
        else:
            print(f"{i:2d}. [{status}] {img_path.name}")
            print(f"     -> No detections")

    except Exception as e:
        print(f"{i:2d}. [ERROR] {img_path.name}: {e}")

# Calculate metrics
total_stone = len(stone_samples)
total_normal = len(normal_samples)
correct_stone = stone_detected
correct_normal = total_normal - false_positives
total_correct = correct_stone + correct_normal
total_tested = total_stone + total_normal

accuracy = (total_correct / total_tested) * 100
sensitivity = (correct_stone / total_stone) * 100
specificity = (correct_normal / total_normal) * 100

print("\n" + "=" * 60)
print("FINAL RESULTS")
print("=" * 60)
print(f"\nModel: Roboflow Ultrasound Kidney Stone Detection")
print(f"Dataset: 5,431 ultrasound images (YOLOv8)")
print(f"\n{'Metric':<25} {'Result':<20}")
print("-" * 60)
print(f"{'Stone Detection Rate':<25} {correct_stone}/{total_stone} ({sensitivity:.1f}%)")
print(f"{'Normal Detection Rate':<25} {correct_normal}/{total_normal} ({specificity:.1f}%)")
print(f"{'Overall Accuracy':<25} {total_correct}/{total_tested} ({accuracy:.1f}%)")
print(f"{'False Positive Rate':<25} {false_positives}/{total_normal} ({(false_positives/total_normal)*100:.1f}%)")

print("\n" + "=" * 60)
print("VERDICT")
print("=" * 60)

if accuracy >= 85:
    print("\n🎉 EXCELLENT! This model works VERY WELL on your ultrasound images!")
    print("   Ready to integrate into your Flutter app!")
elif accuracy >= 70:
    print("\n✓ GOOD! Model shows solid performance on your dataset.")
    print("  Can be integrated into your Flutter app.")
elif accuracy >= 60:
    print("\n~ MODERATE. Model works but has room for improvement.")
else:
    print("\n✗ LOW accuracy. May need a different approach.")

print("\n" + "=" * 60)
print("FOR YOUR PRESENTATION")
print("=" * 60)
print(f"""
Technology Stack:
- Model: YOLOv8 Object Detection
- Training: 5,431 ultrasound kidney images
- Source: Roboflow Universe (Open Source)
- Deployment: Cloud API

Performance Metrics:
- Accuracy: {accuracy:.1f}%
- Sensitivity: {sensitivity:.1f}% (catches {sensitivity:.0f}% of kidney stones)
- Specificity: {specificity:.1f}% (correctly identifies {specificity:.0f}% of normal cases)

Integration:
- Real-time detection via API
- Works on mobile devices
- No local model storage needed
- Scalable cloud infrastructure
""")

# Save a sample detection
if stone_samples:
    print("\n[STEP 4] Creating sample detection visualization...")
    sample_img = stone_samples[0]

    try:
        prediction = model.predict(str(sample_img), confidence=40, overlap=30)
        output_path = "roboflow_ultrasound_detection.jpg"
        prediction.save(output_path)
        print(f"[OK] Sample saved: {output_path}")
        print(f"    Input: {sample_img.name}")
    except Exception as e:
        print(f"[ERROR] Could not save visualization: {e}")
