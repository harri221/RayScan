"""
Inspect the actual images to see if they're visually distinguishable
"""
import os
import random
from PIL import Image
import numpy as np

DATASET_DIR = r'c:\Users\Admin\Downloads\flutter_application_1\ds'

# Sample random images from each class
stone_dir = os.path.join(DATASET_DIR, 'stone')
normal_dir = os.path.join(DATASET_DIR, 'normal')

stone_images = [f for f in os.listdir(stone_dir) if f.lower().endswith(('.jpg', '.jpeg', '.png'))]
normal_images = [f for f in os.listdir(normal_dir) if f.lower().endswith(('.jpg', '.jpeg', '.png'))]

print("=" * 60)
print("DATASET INSPECTION")
print("=" * 60)

# Sample 5 random images from each class
stone_samples = random.sample(stone_images, 5)
normal_samples = random.sample(normal_images, 5)

print("\n[STONE IMAGES]")
for img_name in stone_samples:
    img_path = os.path.join(stone_dir, img_name)
    img = Image.open(img_path)
    img_array = np.array(img)

    print(f"\n  {img_name}")
    print(f"    Size: {img.size}")
    print(f"    Mode: {img.mode}")
    print(f"    Shape: {img_array.shape}")
    print(f"    Min pixel: {img_array.min()}, Max pixel: {img_array.max()}")
    print(f"    Mean pixel: {img_array.mean():.2f}, Std: {img_array.std():.2f}")

    # Check if image is mostly black or white
    if img_array.mean() < 10:
        print(f"    [WARNING] Image is almost completely black!")
    elif img_array.mean() > 245:
        print(f"    [WARNING] Image is almost completely white!")

print("\n[NORMAL IMAGES]")
for img_name in normal_samples:
    img_path = os.path.join(normal_dir, img_name)
    img = Image.open(img_path)
    img_array = np.array(img)

    print(f"\n  {img_name}")
    print(f"    Size: {img.size}")
    print(f"    Mode: {img.mode}")
    print(f"    Shape: {img_array.shape}")
    print(f"    Min pixel: {img_array.min()}, Max pixel: {img_array.max()}")
    print(f"    Mean pixel: {img_array.mean():.2f}, Std: {img_array.std():.2f}")

    if img_array.mean() < 10:
        print(f"    [WARNING] Image is almost completely black!")
    elif img_array.mean() > 245:
        print(f"    [WARNING] Image is almost completely white!")

# Compare statistics
print("\n" + "=" * 60)
print("STATISTICAL COMPARISON")
print("=" * 60)

# Load all stone images and compute stats
stone_means = []
for img_name in stone_images[:100]:  # Sample 100
    img = Image.open(os.path.join(stone_dir, img_name))
    stone_means.append(np.array(img).mean())

# Load all normal images and compute stats
normal_means = []
for img_name in normal_images[:100]:  # Sample 100
    img = Image.open(os.path.join(normal_dir, img_name))
    normal_means.append(np.array(img).mean())

stone_avg = np.mean(stone_means)
normal_avg = np.mean(normal_means)

print(f"\nAverage pixel intensity (100 samples each):")
print(f"  Stone images:  {stone_avg:.2f}")
print(f"  Normal images: {normal_avg:.2f}")
print(f"  Difference: {abs(stone_avg - normal_avg):.2f}")

if abs(stone_avg - normal_avg) < 5:
    print("\n[CRITICAL] Images are statistically TOO SIMILAR!")
    print("The model cannot learn because stone and normal images")
    print("have nearly identical pixel distributions.")
    print("\nPOSSIBLE SOLUTIONS:")
    print("  1. Check if images are correctly labeled")
    print("  2. Use images with more visible/marked stones")
    print("  3. Apply preprocessing to enhance stone visibility")
else:
    print("\n[OK] Images have sufficient statistical difference")

print("\n" + "=" * 60)
print("RECOMMENDATION")
print("=" * 60)
print("\nTo visually inspect images, open:")
print(f"  Stone: {os.path.join(stone_dir, stone_samples[0])}")
print(f"  Normal: {os.path.join(normal_dir, normal_samples[0])}")
print("\nCan YOU tell them apart by looking at them?")
print("If you can't, the model definitely can't!")
