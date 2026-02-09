"""
RayScan ML Model - Dataset Download Script
Downloads kidney ultrasound images from Kaggle
"""

import os
import sys
import zipfile
import shutil
from pathlib import Path


def check_kaggle_credentials():
    """Check if Kaggle API credentials are set up."""
    kaggle_dir = Path.home() / '.kaggle'
    kaggle_json = kaggle_dir / 'kaggle.json'

    if kaggle_json.exists():
        print("✅ Kaggle credentials found!")
        return True

    print("❌ Kaggle credentials not found!")
    print("\n📋 Setup Instructions:")
    print("1. Go to https://www.kaggle.com/settings")
    print("2. Scroll to 'API' section")
    print("3. Click 'Create New Token' - this downloads kaggle.json")
    print(f"4. Move kaggle.json to: {kaggle_dir}")
    print("   On Windows: Create folder .kaggle in your user directory")
    print(f"   Full path: {kaggle_json}")
    print("\n5. Run this script again!")

    return False


def download_ultrasound_dataset():
    """
    Download the Kidney Ultrasound Images dataset from Kaggle.
    Dataset: https://www.kaggle.com/datasets/gurjeetkaurmangat/kidney-ultrasound-images-stone-and-no-stone
    """
    try:
        from kaggle.api.kaggle_api_extended import KaggleApi
    except ImportError:
        print("Installing kaggle package...")
        os.system('pip install kaggle')
        from kaggle.api.kaggle_api_extended import KaggleApi

    if not check_kaggle_credentials():
        return False

    print("\n🔄 Downloading Kidney Ultrasound Dataset from Kaggle...")

    # Initialize API
    api = KaggleApi()
    api.authenticate()

    # Dataset info
    dataset = 'gurjeetkaurmangat/kidney-ultrasound-images-stone-and-no-stone'

    # Download directory
    download_dir = Path(__file__).parent / 'data' / 'raw'
    download_dir.mkdir(parents=True, exist_ok=True)

    print(f"📂 Download directory: {download_dir}")

    # Download dataset
    api.dataset_download_files(dataset, path=str(download_dir), unzip=True)

    print("✅ Download complete!")

    # Organize into train/val/test splits
    organize_dataset(download_dir)

    return True


def download_ct_dataset():
    """
    Download the CT Kidney Dataset (alternative) from Kaggle.
    Dataset: https://www.kaggle.com/datasets/nazmul0087/ct-kidney-dataset-normal-cyst-tumor-and-stone
    """
    try:
        from kaggle.api.kaggle_api_extended import KaggleApi
    except ImportError:
        print("Installing kaggle package...")
        os.system('pip install kaggle')
        from kaggle.api.kaggle_api_extended import KaggleApi

    if not check_kaggle_credentials():
        return False

    print("\n🔄 Downloading CT Kidney Dataset from Kaggle...")

    api = KaggleApi()
    api.authenticate()

    dataset = 'nazmul0087/ct-kidney-dataset-normal-cyst-tumor-and-stone'
    download_dir = Path(__file__).parent / 'data' / 'ct_raw'
    download_dir.mkdir(parents=True, exist_ok=True)

    print(f"📂 Download directory: {download_dir}")

    api.dataset_download_files(dataset, path=str(download_dir), unzip=True)

    print("✅ CT Dataset download complete!")
    print("Note: This dataset contains CT images, not ultrasound.")

    return True


def organize_dataset(raw_dir, train_ratio=0.7, val_ratio=0.15):
    """
    Organize downloaded dataset into train/val/test splits.

    Args:
        raw_dir: Directory containing raw downloaded images
        train_ratio: Percentage for training (default 70%)
        val_ratio: Percentage for validation (default 15%)
        # Test is remaining (15%)
    """
    import random

    print("\n🔄 Organizing dataset into train/val/test splits...")

    raw_path = Path(raw_dir)
    processed_dir = raw_path.parent / 'processed'

    # Create directory structure
    for split in ['train', 'val', 'test']:
        for label in ['stone', 'normal']:
            (processed_dir / split / label).mkdir(parents=True, exist_ok=True)

    # Find all images
    stone_images = []
    normal_images = []

    # Look for common directory structures
    possible_stone_dirs = ['stone', 'Stone', 'kidney_stone', 'Kidney Stone']
    possible_normal_dirs = ['normal', 'Normal', 'no_stone', 'No Stone', 'healthy']

    for stone_dir in possible_stone_dirs:
        stone_path = raw_path / stone_dir
        if stone_path.exists():
            stone_images.extend(list(stone_path.glob('*.[jp][pn][g]')))
            stone_images.extend(list(stone_path.glob('*.jpeg')))
            break

    # Also check subdirectories
    for subdir in raw_path.iterdir():
        if subdir.is_dir():
            for stone_dir in possible_stone_dirs:
                stone_path = subdir / stone_dir
                if stone_path.exists():
                    stone_images.extend(list(stone_path.glob('*.[jp][pn][g]')))
                    stone_images.extend(list(stone_path.glob('*.jpeg')))

    for normal_dir in possible_normal_dirs:
        normal_path = raw_path / normal_dir
        if normal_path.exists():
            normal_images.extend(list(normal_path.glob('*.[jp][pn][g]')))
            normal_images.extend(list(normal_path.glob('*.jpeg')))
            break

    for subdir in raw_path.iterdir():
        if subdir.is_dir():
            for normal_dir in possible_normal_dirs:
                normal_path = subdir / normal_dir
                if normal_path.exists():
                    normal_images.extend(list(normal_path.glob('*.[jp][pn][g]')))
                    normal_images.extend(list(normal_path.glob('*.jpeg')))

    print(f"  Found {len(stone_images)} stone images")
    print(f"  Found {len(normal_images)} normal images")

    if len(stone_images) == 0 or len(normal_images) == 0:
        print("\n⚠️  Could not find images in expected structure.")
        print("Please manually organize images into:")
        print(f"  {processed_dir}/train/stone/")
        print(f"  {processed_dir}/train/normal/")
        print(f"  {processed_dir}/val/stone/")
        print(f"  {processed_dir}/val/normal/")
        print(f"  {processed_dir}/test/stone/")
        print(f"  {processed_dir}/test/normal/")
        return

    # Shuffle and split
    random.seed(42)
    random.shuffle(stone_images)
    random.shuffle(normal_images)

    def split_and_copy(images, label):
        n = len(images)
        train_end = int(n * train_ratio)
        val_end = int(n * (train_ratio + val_ratio))

        splits = {
            'train': images[:train_end],
            'val': images[train_end:val_end],
            'test': images[val_end:]
        }

        for split, split_images in splits.items():
            for img_path in split_images:
                dest = processed_dir / split / label / img_path.name
                shutil.copy2(img_path, dest)

            print(f"    {split}: {len(split_images)} images")

    print("\n  Stone images:")
    split_and_copy(stone_images, 'stone')

    print("\n  Normal images:")
    split_and_copy(normal_images, 'normal')

    print(f"\n✅ Dataset organized at: {processed_dir}")

    # Print summary
    total = 0
    print("\n📊 Dataset Summary:")
    for split in ['train', 'val', 'test']:
        stone_count = len(list((processed_dir / split / 'stone').glob('*')))
        normal_count = len(list((processed_dir / split / 'normal').glob('*')))
        total += stone_count + normal_count
        print(f"  {split}: {stone_count} stone, {normal_count} normal ({stone_count + normal_count} total)")

    print(f"\n  Total: {total} images")


def main():
    print("="*60)
    print("RayScan Dataset Downloader")
    print("Kidney Ultrasound Images for Stone Detection")
    print("="*60)

    print("\nAvailable datasets:")
    print("1. Kidney Ultrasound Images (Stone/No Stone) - RECOMMENDED")
    print("2. CT Kidney Dataset (Stone/Cyst/Tumor/Normal)")
    print("3. Both datasets")

    choice = input("\nSelect dataset (1/2/3): ").strip()

    if choice == '1':
        download_ultrasound_dataset()
    elif choice == '2':
        download_ct_dataset()
    elif choice == '3':
        download_ultrasound_dataset()
        download_ct_dataset()
    else:
        print("Invalid choice. Downloading ultrasound dataset (default)...")
        download_ultrasound_dataset()

    print("\n🎉 Done! You can now run the training script.")
    print("   python src/train.py --data_dir data/processed --model all")


if __name__ == "__main__":
    main()
