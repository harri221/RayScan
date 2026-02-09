"""
Test Roboflow with LOWER confidence threshold
To catch more kidney stones
"""
import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'

print("=" * 60)
print("ROBOFLOW - TESTING DIFFERENT CONFIDENCE LEVELS")
print("=" * 60)

from roboflow import Roboflow
import random
from pathlib import Path

rf = Roboflow(api_key="qBacb6KhwY6FF3RV2c9i")

print("\n[Loading model...]")
project = rf.workspace("kidney-rtzud").project("kidney-stone-detection-9j42c")
model = project.version(1).model
print("[OK] Model loaded (1,459 ultrasound images)")

stone_dir = Path(r'c:\Users\Admin\Downloads\flutter_application_1\ds\stone')
normal_dir = Path(r'c:\Users\Admin\Downloads\flutter_application_1\ds\normal')

# Test samples
stone_samples = random.sample(list(stone_dir.glob("*.jpg")), min(20, len(list(stone_dir.glob("*.jpg")))))
normal_samples = random.sample(list(normal_dir.glob("*.jpg")), min(20, len(list(normal_dir.glob("*.jpg")))))

# Test different confidence levels
confidence_levels = [20, 30, 40, 50]

print("\n" + "=" * 60)
print("TESTING DIFFERENT CONFIDENCE THRESHOLDS")
print("=" * 60)

best_accuracy = 0
best_conf = 40
best_results = None

for conf_level in confidence_levels:
    print(f"\n--- Testing with confidence = {conf_level}% ---")

    stone_detected = 0
    false_positives = 0

    # Test stone images
    for img_path in stone_samples:
        try:
            prediction = model.predict(str(img_path), confidence=conf_level, overlap=30).json()
            detections = prediction.get('predictions', [])
            if len(detections) > 0:
                stone_detected += 1
        except:
            pass

    # Test normal images
    for img_path in normal_samples:
        try:
            prediction = model.predict(str(img_path), confidence=conf_level, overlap=30).json()
            detections = prediction.get('predictions', [])
            if len(detections) > 0:
                false_positives += 1
        except:
            pass

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

    print(f"  Stone Detection: {correct_stone}/{total_stone} ({sensitivity:.1f}%)")
    print(f"  Normal Detection: {correct_normal}/{total_normal} ({specificity:.1f}%)")
    print(f"  Overall Accuracy: {accuracy:.1f}%")

    if accuracy > best_accuracy:
        best_accuracy = accuracy
        best_conf = conf_level
        best_results = {
            'sensitivity': sensitivity,
            'specificity': specificity,
            'stone_detected': correct_stone,
            'total_stone': total_stone,
            'normal_correct': correct_normal,
            'total_normal': total_normal
        }

print("\n" + "=" * 60)
print("BEST CONFIGURATION")
print("=" * 60)
print(f"\nOptimal Confidence Threshold: {best_conf}%")
print(f"Best Accuracy: {best_accuracy:.1f}%")
print(f"\nDetailed Metrics:")
print(f"  Sensitivity: {best_results['sensitivity']:.1f}% ({best_results['stone_detected']}/{best_results['total_stone']} stones detected)")
print(f"  Specificity: {best_results['specificity']:.1f}% ({best_results['normal_correct']}/{best_results['total_normal']} normals correct)")

print("\n" + "=" * 60)
print("VERDICT")
print("=" * 60)

if best_accuracy >= 75:
    print("\nGOOD! This model can work for your app!")
    print(f"Use confidence threshold: {best_conf}%")
elif best_accuracy >= 60:
    print("\nMODERATE. Model shows promise.")
    print(f"Recommended confidence: {best_conf}%")
else:
    print("\nLOW accuracy. May need different approach.")

print(f"\nRecommendation: Use confidence={best_conf}% in your Flutter app")
