"""
Test MedianLaplacian preprocessing - Save comparison images
"""
import cv2
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path
import random
import os

print("=" * 60)
print("MEDIAN LAPLACIAN PREPROCESSING TEST")
print("=" * 60)

def median_laplacian_process(img_path):
    """Apply Median Laplacian preprocessing"""
    img = cv2.imread(str(img_path), 0)
    if img is None:
        return None, None

    # Median blur
    dst = cv2.medianBlur(img, 5)

    # Laplacian edge detection
    lap = cv2.Laplacian(dst, cv2.CV_64F)

    # Sharpening
    sharp = dst - 0.3*lap

    # Normalize
    sharp = np.uint8(cv2.normalize(sharp, None, 0, 255, cv2.NORM_MINMAX))

    # Histogram equalization
    equ = cv2.equalizeHist(sharp)

    return img, equ

# Create output directory
output_dir = Path(r'c:\Users\Admin\Downloads\flutter_application_1\median_laplacian_results')
output_dir.mkdir(exist_ok=True)

stone_dir = Path(r'c:\Users\Admin\Downloads\flutter_application_1\ds\stone')
normal_dir = Path(r'c:\Users\Admin\Downloads\flutter_application_1\ds\normal')

# Process stone images
print("\n[Processing STONE images...]")
stone_samples = random.sample(list(stone_dir.glob("*.jpg")), min(3, len(list(stone_dir.glob("*.jpg")))))

for i, img_path in enumerate(stone_samples, 1):
    original, processed = median_laplacian_process(img_path)
    if processed is not None:
        # Save comparison image
        fig, axes = plt.subplots(1, 2, figsize=(10, 4))

        axes[0].imshow(original, cmap='gray')
        axes[0].set_title(f'Original: {img_path.name}')
        axes[0].axis('off')

        axes[1].imshow(processed, cmap='gray')
        axes[1].set_title('After Preprocessing')
        axes[1].axis('off')

        plt.tight_layout()
        output_path = output_dir / f'stone_{i}_comparison.png'
        plt.savefig(output_path, dpi=150, bbox_inches='tight')
        plt.close()

        print(f"  [OK] Saved: {output_path.name}")

# Process normal images
print("\n[Processing NORMAL images...]")
normal_samples = random.sample(list(normal_dir.glob("*.jpg")), min(3, len(list(normal_dir.glob("*.jpg")))))

for i, img_path in enumerate(normal_samples, 1):
    original, processed = median_laplacian_process(img_path)
    if processed is not None:
        # Save comparison image
        fig, axes = plt.subplots(1, 2, figsize=(10, 4))

        axes[0].imshow(original, cmap='gray')
        axes[0].set_title(f'Original: {img_path.name}')
        axes[0].axis('off')

        axes[1].imshow(processed, cmap='gray')
        axes[1].set_title('After Preprocessing')
        axes[1].axis('off')

        plt.tight_layout()
        output_path = output_dir / f'normal_{i}_comparison.png'
        plt.savefig(output_path, dpi=150, bbox_inches='tight')
        plt.close()

        print(f"  [OK] Saved: {output_path.name}")

print("\n" + "=" * 60)
print("RESULTS SAVED")
print("=" * 60)
print(f"\nAll comparison images saved to:")
print(f"{output_dir}")
print(f"\nTotal images: {len(list(output_dir.glob('*.png')))}")

print("\n" + "=" * 60)
print("WHAT IS MEDIAN LAPLACIAN PREPROCESSING?")
print("=" * 60)
print("""
This is an IMAGE PREPROCESSING technique (NOT ML model):

1. Median Blur: Removes noise while keeping edges sharp
2. Laplacian: Detects edges and boundaries in the image
3. Sharpening: Enhances kidney stone edges
4. Histogram Equalization: Improves contrast

Benefits for kidney stone detection:
- Makes stone edges more visible
- Enhances tissue contrast
- Reduces ultrasound noise

You can add this to your Flutter app BEFORE the ML model
to potentially improve prediction accuracy!
""")
