"""
RayScan ML Model - Image Preprocessing Pipeline
Based on Paper 2 (AECE 2022): Bilateral Filter + CLAHE for ultrasound images
"""

import cv2
import numpy as np
import os
from pathlib import Path
from tqdm import tqdm
import albumentations as A


class UltrasoundPreprocessor:
    """
    Preprocessing pipeline for kidney ultrasound images.
    Combines techniques from research papers for optimal stone detection.
    """

    def __init__(self, target_size=(224, 224)):
        """
        Initialize preprocessor with target image size.

        Args:
            target_size: Tuple (width, height) for output images
        """
        self.target_size = target_size

        # CLAHE parameters (Contrast Limited Adaptive Histogram Equalization)
        self.clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))

        # Bilateral filter parameters (preserves edges while reducing noise)
        self.bilateral_d = 9  # Diameter of pixel neighborhood
        self.bilateral_sigma_color = 75  # Filter sigma in color space
        self.bilateral_sigma_space = 75  # Filter sigma in coordinate space

    def apply_bilateral_filter(self, image):
        """
        Apply bilateral filter for speckle noise reduction.
        Best for ultrasound images as it preserves edges.

        Args:
            image: Grayscale image (numpy array)

        Returns:
            Filtered image
        """
        return cv2.bilateralFilter(
            image,
            self.bilateral_d,
            self.bilateral_sigma_color,
            self.bilateral_sigma_space
        )

    def apply_clahe(self, image):
        """
        Apply CLAHE for contrast enhancement.
        Improves visibility of kidney stones in ultrasound.

        Args:
            image: Grayscale image (numpy array)

        Returns:
            Contrast-enhanced image
        """
        return self.clahe.apply(image)

    def crop_roi(self, image, margin_percent=0.05):
        """
        Crop Region of Interest to remove scan metadata/borders.

        Args:
            image: Input image
            margin_percent: Percentage of image to crop from edges

        Returns:
            Cropped image
        """
        h, w = image.shape[:2]
        margin_h = int(h * margin_percent)
        margin_w = int(w * margin_percent)

        return image[margin_h:h-margin_h, margin_w:w-margin_w]

    def preprocess_single(self, image_path, normalize=True):
        """
        Complete preprocessing pipeline for a single image.

        Steps:
        1. Load image as grayscale
        2. Crop ROI (remove scan metadata)
        3. Apply bilateral filter (noise reduction)
        4. Apply CLAHE (contrast enhancement)
        5. Resize to target size
        6. Normalize to [0, 1] range

        Args:
            image_path: Path to the image file
            normalize: Whether to normalize to [0, 1]

        Returns:
            Preprocessed image as numpy array
        """
        # 1. Load image
        img = cv2.imread(str(image_path), cv2.IMREAD_GRAYSCALE)

        if img is None:
            raise ValueError(f"Could not load image: {image_path}")

        # 2. Crop ROI
        img = self.crop_roi(img)

        # 3. Apply bilateral filter (noise reduction)
        img = self.apply_bilateral_filter(img)

        # 4. Apply CLAHE (contrast enhancement)
        img = self.apply_clahe(img)

        # 5. Resize to target size
        img = cv2.resize(img, self.target_size, interpolation=cv2.INTER_LINEAR)

        # 6. Normalize
        if normalize:
            img = img.astype(np.float32) / 255.0

        return img

    def preprocess_for_vgg(self, image_path):
        """
        Preprocess image for VGG16 (requires 3 channels).

        Args:
            image_path: Path to the image file

        Returns:
            Preprocessed image with 3 channels
        """
        img = self.preprocess_single(image_path, normalize=False)

        # Convert grayscale to 3 channels
        img_3ch = cv2.cvtColor(img, cv2.COLOR_GRAY2RGB)

        # Normalize for VGG (ImageNet mean subtraction)
        img_3ch = img_3ch.astype(np.float32)
        img_3ch = img_3ch / 255.0

        return img_3ch

    def preprocess_dataset(self, input_dir, output_dir, file_extensions=('.jpg', '.jpeg', '.png', '.bmp')):
        """
        Preprocess entire dataset directory.

        Args:
            input_dir: Directory containing raw images
            output_dir: Directory to save preprocessed images
            file_extensions: Tuple of valid image extensions

        Returns:
            Number of images processed
        """
        input_path = Path(input_dir)
        output_path = Path(output_dir)

        # Create output directory
        output_path.mkdir(parents=True, exist_ok=True)

        # Find all image files
        image_files = []
        for ext in file_extensions:
            image_files.extend(input_path.glob(f'**/*{ext}'))
            image_files.extend(input_path.glob(f'**/*{ext.upper()}'))

        processed_count = 0

        for img_path in tqdm(image_files, desc="Preprocessing images"):
            try:
                # Preprocess
                img = self.preprocess_single(img_path, normalize=False)

                # Maintain directory structure
                relative_path = img_path.relative_to(input_path)
                output_file = output_path / relative_path
                output_file.parent.mkdir(parents=True, exist_ok=True)

                # Save preprocessed image
                cv2.imwrite(str(output_file), img)
                processed_count += 1

            except Exception as e:
                print(f"Error processing {img_path}: {e}")

        return processed_count


class DataAugmentor:
    """
    Data augmentation for training kidney stone detection model.
    """

    def __init__(self, target_size=(224, 224)):
        self.target_size = target_size

        # Training augmentation pipeline
        self.train_transform = A.Compose([
            A.Rotate(limit=20, p=0.5),
            A.HorizontalFlip(p=0.5),
            A.ShiftScaleRotate(
                shift_limit=0.1,
                scale_limit=0.1,
                rotate_limit=15,
                p=0.5
            ),
            A.RandomBrightnessContrast(
                brightness_limit=0.2,
                contrast_limit=0.2,
                p=0.3
            ),
            A.GaussNoise(var_limit=(10.0, 50.0), p=0.2),
            A.Resize(target_size[0], target_size[1]),
        ])

        # Validation/Test - only resize
        self.val_transform = A.Compose([
            A.Resize(target_size[0], target_size[1]),
        ])

    def augment_train(self, image):
        """Apply training augmentation."""
        augmented = self.train_transform(image=image)
        return augmented['image']

    def augment_val(self, image):
        """Apply validation augmentation (resize only)."""
        augmented = self.val_transform(image=image)
        return augmented['image']


def visualize_preprocessing(image_path, output_path=None):
    """
    Visualize each step of the preprocessing pipeline.

    Args:
        image_path: Path to original image
        output_path: Optional path to save visualization
    """
    import matplotlib.pyplot as plt

    preprocessor = UltrasoundPreprocessor()

    # Load original
    original = cv2.imread(str(image_path), cv2.IMREAD_GRAYSCALE)

    # Step by step
    cropped = preprocessor.crop_roi(original)
    bilateral = preprocessor.apply_bilateral_filter(cropped)
    clahe = preprocessor.apply_clahe(bilateral)
    resized = cv2.resize(clahe, preprocessor.target_size)

    # Plot
    fig, axes = plt.subplots(1, 5, figsize=(20, 4))

    titles = ['Original', 'Cropped ROI', 'Bilateral Filter', 'CLAHE', 'Final (Resized)']
    images = [original, cropped, bilateral, clahe, resized]

    for ax, title, img in zip(axes, titles, images):
        ax.imshow(img, cmap='gray')
        ax.set_title(title)
        ax.axis('off')

    plt.tight_layout()

    if output_path:
        plt.savefig(output_path, dpi=150, bbox_inches='tight')
        print(f"Visualization saved to: {output_path}")

    plt.show()


if __name__ == "__main__":
    # Test preprocessing
    print("RayScan Ultrasound Preprocessor")
    print("=" * 50)

    preprocessor = UltrasoundPreprocessor(target_size=(224, 224))

    # Example usage
    print("\nPreprocessor initialized with:")
    print(f"  - Target size: {preprocessor.target_size}")
    print(f"  - Bilateral filter d: {preprocessor.bilateral_d}")
    print(f"  - CLAHE clip limit: 2.0")
    print(f"  - CLAHE tile grid: (8, 8)")

    print("\nUsage:")
    print("  preprocessor = UltrasoundPreprocessor()")
    print("  img = preprocessor.preprocess_single('path/to/image.jpg')")
    print("  img_vgg = preprocessor.preprocess_for_vgg('path/to/image.jpg')")
