"""
Fix dataset by converting all images to RGB format
"""
import os
from PIL import Image
from tqdm import tqdm

DATASET_DIR = r'c:\Users\Admin\Downloads\flutter_application_1\ds'

print("=" * 60)
print("FIXING DATASET - CONVERTING ALL TO RGB")
print("=" * 60)

for class_name in ['stone', 'normal']:
    class_dir = os.path.join(DATASET_DIR, class_name)
    image_files = [f for f in os.listdir(class_dir) if f.lower().endswith(('.jpg', '.jpeg', '.png'))]

    print(f"\n[{class_name.upper()}] Processing {len(image_files)} images...")

    grayscale_count = 0
    rgb_count = 0
    converted_count = 0

    for img_name in tqdm(image_files, desc=f"Converting {class_name}"):
        img_path = os.path.join(class_dir, img_name)

        # Open image
        img = Image.open(img_path)

        # Check mode
        if img.mode == 'L':
            grayscale_count += 1
            # Convert grayscale to RGB
            img_rgb = img.convert('RGB')
            # Save back
            img_rgb.save(img_path)
            converted_count += 1
        elif img.mode == 'RGB':
            rgb_count += 1
        else:
            # Handle other modes (RGBA, etc.)
            img_rgb = img.convert('RGB')
            img_rgb.save(img_path)
            converted_count += 1

    print(f"  Original grayscale: {grayscale_count}")
    print(f"  Original RGB: {rgb_count}")
    print(f"  Converted: {converted_count}")

print("\n" + "=" * 60)
print("DATASET FIXED!")
print("=" * 60)
print("\nAll images are now in RGB format.")
print("Now retrain the model with: python train_simple_cnn.py")
