"""
Test UroVision YOLOv8 model on our kidney stone dataset
"""
import os
from ultralytics import YOLO
from PIL import Image
import random

print("=" * 60)
print("TESTING UROVISION YOLOv8 MODEL")
print("=" * 60)

# Load the pretrained model
MODEL_PATH = r'c:\Users\Admin\Downloads\UroVision\Model\weights\best.pt'
DATASET_DIR = r'c:\Users\Admin\Downloads\flutter_application_1\ds'

print(f"\n[STEP 1] Loading YOLOv8 model...")
model = YOLO(MODEL_PATH)
print(f"[OK] Model loaded: {MODEL_PATH}")

# Test on stone images
stone_dir = os.path.join(DATASET_DIR, 'stone')
normal_dir = os.path.join(DATASET_DIR, 'normal')

stone_images = [f for f in os.listdir(stone_dir) if f.lower().endswith(('.jpg', '.jpeg', '.png'))]
normal_images = [f for f in os.listdir(normal_dir) if f.lower().endswith(('.jpg', '.jpeg', '.png'))]

# Sample 10 random images from each class
stone_samples = random.sample(stone_images, min(10, len(stone_images)))
normal_samples = random.sample(normal_images, min(10, len(normal_images)))

print(f"\n[STEP 2] Testing on STONE images...")
stone_detections = 0
for img_name in stone_samples:
    img_path = os.path.join(stone_dir, img_name)
    results = model.predict(img_path, conf=0.25, verbose=False)

    # Check if stones detected
    detected = len(results[0].boxes) > 0
    if detected:
        stone_detections += 1
        conf = results[0].boxes.conf[0].item() if len(results[0].boxes) > 0 else 0
        print(f"  [DETECTED] {img_name} - Confidence: {conf:.2f}")
    else:
        print(f"  [MISSED] {img_name} - No detection")

print(f"\n  Stone Detection Rate: {stone_detections}/10 = {stone_detections*10}%")

print(f"\n[STEP 3] Testing on NORMAL images...")
normal_detections = 0
for img_name in normal_samples:
    img_path = os.path.join(normal_dir, img_name)
    results = model.predict(img_path, conf=0.25, verbose=False)

    # Check if stones detected (should be FALSE for normal images)
    detected = len(results[0].boxes) > 0
    if detected:
        normal_detections += 1
        conf = results[0].boxes.conf[0].item() if len(results[0].boxes) > 0 else 0
        print(f"  [FALSE POSITIVE] {img_name} - Confidence: {conf:.2f}")
    else:
        print(f"  [CORRECT] {img_name} - No detection")

print(f"\n  False Positive Rate: {normal_detections}/10 = {normal_detections*10}%")

print("\n" + "=" * 60)
print("SUMMARY")
print("=" * 60)
print(f"\nModel: YOLOv8n (UroVision)")
print(f"Trained on: Roboflow kidney stone dataset")
print(f"Model Metrics (from training):")
print(f"  Precision: 84.4%")
print(f"  Recall: 70.3%")
print(f"  F1-Score: 0.77")

print(f"\nPerformance on YOUR dataset:")
print(f"  Stone images detected: {stone_detections}/10 ({stone_detections*10}%)")
print(f"  Normal images (correctly no detection): {10-normal_detections}/10 ({(10-normal_detections)*10}%)")

accuracy = ((stone_detections + (10-normal_detections)) / 20) * 100
print(f"  Overall accuracy: {accuracy:.1f}%")

if stone_detections < 5:
    print("\n[WARNING] Low detection rate on stone images!")
    print("Possible reasons:")
    print("  1. Your ultrasound images look different from training data")
    print("  2. Model trained on CT/MRI, not ultrasound")
    print("  3. Stones in your images are too small/subtle")
else:
    print("\n[OK] Model is detecting stones reasonably well!")

print("\n" + "=" * 60)
print("NEXT STEPS")
print("=" * 60)
print("\nIf results are good (>70% accuracy):")
print("  1. Convert to TFLite: python convert_yolo_to_tflite.py")
print("  2. Integrate into Flutter app")
print("\nIf results are poor (<50% accuracy):")
print("  1. Fix dataset format issue (python fix_dataset.py)")
print("  2. Retrain custom model on your data")
