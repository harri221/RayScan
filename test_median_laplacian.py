"""
Test MedianLaplacian preprocessing on your ultrasound images
This is an IMAGE PREPROCESSING technique (not ML model)
"""
import cv2
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path
import random

print("=" * 60)
print("MEDIAN LAPLACIAN PREPROCESSING TEST")
print("From Tanyaborges/Kidney-Stone-Detection")
print("=" * 60)

def median_laplacian_process(img_path):
    """
    Apply Median Laplacian preprocessing

    Steps:
    1. Median blur (noise reduction)
    2. Laplacian edge detection
    3. Sharpening
    4. Normalization
    5. Histogram equalization
    """
    # Read as grayscale
    img = cv2.imread(str(img_path), 0)
    if img is None:
        return None, None

    # Median blur with kernel size 5
    dst = cv2.medianBlur(img, 5)

    # Calculate the Laplacian (edge detection)
    lap = cv2.Laplacian(dst, cv2.CV_64F)

    # Calculate the sharpened image
    sharp = dst - 0.3*lap

    # Normalize to 0-255 range
    sharp = np.uint8(cv2.normalize(sharp, None, 0, 255, cv2.NORM_MINMAX))

    # Histogram equalization (contrast enhancement)
    equ = cv2.equalizeHist(sharp)

    return img, equ

# Get test images from your dataset
stone_dir = Path(r'c:\Users\Admin\Downloads\flutter_application_1\ds\stone')
normal_dir = Path(r'c:\Users\Admin\Downloads\flutter_application_1\ds\normal')

# Get random samples
stone_samples = random.sample(list(stone_dir.glob("*.jpg")), min(3, len(list(stone_dir.glob("*.jpg")))))
normal_samples = random.sample(list(normal_dir.glob("*.jpg")), min(3, len(list(normal_dir.glob("*.jpg")))))

print("\n[STEP 1] Processing STONE images...")
for i, img_path in enumerate(stone_samples, 1):
    original, processed = median_laplacian_process(img_path)
    if processed is not None:
        print(f"  [{i}] Processed: {img_path.name}")

        # Show comparison
        plt.figure(figsize=(10, 4))
        plt.subplot(1, 2, 1)
        plt.imshow(original, cmap='gray')
        plt.title(f'Original: {img_path.name}')
        plt.axis('off')

        plt.subplot(1, 2, 2)
        plt.imshow(processed, cmap='gray')
        plt.title('After Median+Laplacian+HistEq')
        plt.axis('off')

        plt.tight_layout()
        plt.show()

print("\n[STEP 2] Processing NORMAL images...")
for i, img_path in enumerate(normal_samples, 1):
    original, processed = median_laplacian_process(img_path)
    if processed is not None:
        print(f"  [{i}] Processed: {img_path.name}")

        # Show comparison
        plt.figure(figsize=(10, 4))
        plt.subplot(1, 2, 1)
        plt.imshow(original, cmap='gray')
        plt.title(f'Original: {img_path.name}')
        plt.axis('off')

        plt.subplot(1, 2, 2)
        plt.imshow(processed, cmap='gray')
        plt.title('After Median+Laplacian+HistEq')
        plt.axis('off')

        plt.tight_layout()
        plt.show()

print("\n" + "=" * 60)
print("WHAT THIS DOES")
print("=" * 60)
print("""
This is NOT a machine learning model!
It's an IMAGE PREPROCESSING technique:

1. Median Blur: Reduces noise while preserving edges
2. Laplacian: Detects edges and boundaries
3. Sharpening: Enhances edges (subtracts Laplacian)
4. Normalization: Scales to 0-255 range
5. Histogram Equalization: Improves contrast

Benefits:
✓ Makes kidney stone edges more visible
✓ Enhances contrast between tissues
✓ Reduces noise in ultrasound images

This can be used BEFORE feeding images to ML models
to potentially improve accuracy!
""")

print("\n" + "=" * 60)
print("INTEGRATION IDEAS")
print("=" * 60)
print("""
You could:
1. Add this preprocessing to your Flutter app
2. Apply it before MobileNetV2 inference
3. Test if it improves prediction accuracy

Note: This adds processing time (~50-100ms per image)
""")
