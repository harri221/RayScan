import cv2
import os
import matplotlib.pyplot as plt
import numpy as np

def load_image(path):
    img = cv2.imread(path, cv2.IMREAD_GRAYSCALE)
    img = cv2.resize(img, (224, 224))  # Resize for consistency
    return img

def apply_bilateral(img):
    return cv2.bilateralFilter(img, d=9, sigmaColor=75, sigmaSpace=75)

def apply_median(img):
    return cv2.medianBlur(img, 5)

def apply_clahe(img):
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    return clahe.apply(img)

def apply_gabor(img):
    kernel = cv2.getGaborKernel((21, 21), 8.0, 1.0, 10.0, 0.5, 0, ktype=cv2.CV_32F)
    return cv2.filter2D(img, cv2.CV_8UC3, kernel)

# Load a sample image
sample_path = "dataset/stone/Stone_31.jpg"  # Change this
img = load_image(sample_path)

# Apply filters
bilateral = apply_bilateral(img)
median = apply_median(img)
clahe = apply_clahe(img)
gabor = apply_gabor(img)

# Visualize
titles = ['Original', 'Bilateral', 'Median', 'CLAHE', 'Gabor']
images = [img, bilateral, median, clahe, gabor]

plt.figure(figsize=(15,5))
for i in range(5):
    plt.subplot(1,5,i+1)
    plt.imshow(images[i], cmap='gray')
    plt.title(titles[i])
    plt.axis('off')
plt.tight_layout()
plt.show()
