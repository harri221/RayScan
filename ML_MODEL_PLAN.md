# RayScan ML Model Development Plan
## Kidney Stone Detection from Ultrasound Images

---

## Overview

We will build a kidney stone detection system combining methodologies from two research papers:

1. **Paper 1 (IJECE 2023)**: CNN + VGG16 feature extraction with XGBoost/Random Forest classifiers (99.47% accuracy)
2. **Paper 2 (AECE 2022)**: Image preprocessing with Bilateral Filter + CLAHE + Watershed Segmentation

---

## Phase 1: Dataset Acquisition

### Task 1.1: Find Public Datasets
We need kidney ultrasound images with stone/normal labels.

**Potential Sources:**
- Kaggle kidney stone datasets
- UCI Machine Learning Repository
- GitHub medical imaging datasets
- CT2US (CT to Ultrasound) datasets
- Contact hospitals/research institutions

**Target:** ~5,000-10,000 images (balanced: 50% stone, 50% normal)

### Task 1.2: Dataset Structure
```
dataset/
├── train/
│   ├── stone/
│   └── normal/
├── validation/
│   ├── stone/
│   └── normal/
└── test/
    ├── stone/
    └── normal/
```

**Split Ratio:** 70% train, 15% validation, 15% test

---

## Phase 2: Image Preprocessing Pipeline

Based on Paper 2 methodology:

### Task 2.1: Noise Reduction
```python
# Bilateral Filter (best for ultrasound speckle noise)
def apply_bilateral_filter(image):
    return cv2.bilateralFilter(image, d=9, sigmaColor=75, sigmaSpace=75)
```

### Task 2.2: Contrast Enhancement (CLAHE)
```python
# Contrast Limited Adaptive Histogram Equalization
def apply_clahe(image):
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8,8))
    return clahe.apply(image)
```

### Task 2.3: Complete Preprocessing Pipeline
```python
def preprocess_image(image_path):
    # 1. Load image
    img = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)

    # 2. Crop ROI (remove patient info, scan details)
    img = crop_roi(img, size=(512, 512))

    # 3. Apply Bilateral Filter (noise reduction)
    img = cv2.bilateralFilter(img, 9, 75, 75)

    # 4. Apply CLAHE (contrast enhancement)
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8,8))
    img = clahe.apply(img)

    # 5. Resize for model input
    img = cv2.resize(img, (224, 224))

    # 6. Normalize (0-1)
    img = img / 255.0

    return img
```

---

## Phase 3: Model Architecture

We'll implement TWO approaches and compare them:

### Approach A: Custom CNN + XGBoost (Paper 1 Method)

```python
# Custom CNN for Feature Extraction
model = Sequential([
    # Block 1
    Conv2D(32, (3,3), activation='relu', input_shape=(224,224,1)),
    BatchNormalization(),
    Conv2D(32, (3,3), activation='relu'),
    BatchNormalization(),
    MaxPooling2D((2,2)),

    # Block 2
    Conv2D(64, (3,3), activation='relu'),
    BatchNormalization(),
    Conv2D(64, (3,3), activation='relu'),
    BatchNormalization(),
    MaxPooling2D((2,2)),

    # Block 3
    Conv2D(128, (3,3), activation='relu'),
    BatchNormalization(),
    MaxPooling2D((2,2)),

    # Feature extraction output
    Flatten(),
    Dense(256, activation='relu'),
])

# Extract features, then train XGBoost
features = model.predict(X_train)
xgb_classifier = XGBClassifier(n_estimators=100, max_depth=6)
xgb_classifier.fit(features, y_train)
```

### Approach B: VGG16 Transfer Learning + XGBoost (Paper 1 Method)

```python
# VGG16 Feature Extraction
from tensorflow.keras.applications import VGG16

base_model = VGG16(weights='imagenet', include_top=False, input_shape=(224,224,3))
base_model.trainable = False  # Freeze layers

# Add custom layers
model = Sequential([
    base_model,
    GlobalAveragePooling2D(),
    Dense(512, activation='relu'),
    Dropout(0.5),
])

# Extract features
features = model.predict(X_train)

# Train XGBoost on extracted features
xgb_classifier = XGBClassifier(
    n_estimators=200,
    max_depth=6,
    learning_rate=0.1,
    objective='binary:logistic'
)
xgb_classifier.fit(features, y_train)
```

### Approach C: End-to-End CNN (for comparison)

```python
# Full CNN with classification head
model = Sequential([
    # ... CNN layers ...
    Dense(128, activation='relu'),
    Dropout(0.5),
    Dense(1, activation='sigmoid')  # Binary classification
])

model.compile(
    optimizer='adam',
    loss='binary_crossentropy',
    metrics=['accuracy']
)
```

---

## Phase 4: Training Strategy

### Task 4.1: Data Augmentation
```python
train_datagen = ImageDataGenerator(
    rotation_range=20,
    width_shift_range=0.2,
    height_shift_range=0.2,
    horizontal_flip=True,
    zoom_range=0.2,
    shear_range=0.1,
    fill_mode='nearest'
)
```

### Task 4.2: Training Parameters
- **Epochs:** 50-100 (with early stopping)
- **Batch Size:** 32
- **Learning Rate:** 0.001 (with decay)
- **Optimizer:** Adam
- **Loss:** Binary Cross-Entropy
- **Early Stopping:** patience=10, monitor='val_loss'

### Task 4.3: Cross-Validation
- 5-Fold Cross-Validation for robust evaluation
- Stratified splits to maintain class balance

---

## Phase 5: Model Evaluation

### Metrics to Track:
1. **Accuracy** - Overall correctness
2. **Precision** - TP / (TP + FP)
3. **Recall (Sensitivity)** - TP / (TP + FN) - Critical for medical diagnosis!
4. **F1-Score** - Harmonic mean of Precision & Recall
5. **AUC-ROC** - Area under ROC curve
6. **Confusion Matrix** - Visual representation

### Target Metrics (based on papers):
- Accuracy: >95%
- Recall: >97% (important - don't miss stones!)
- Precision: >93%
- AUC: >0.98

---

## Phase 6: Explainability (Grad-CAM)

For medical AI, explainability is crucial:

```python
from tf_keras_vis.gradcam import Gradcam

def generate_gradcam(model, image):
    gradcam = Gradcam(model)
    cam = gradcam(score_function, image, penultimate_layer=-1)

    # Overlay heatmap on original image
    heatmap = cv2.applyColorMap(np.uint8(255 * cam), cv2.COLORMAP_JET)
    output = cv2.addWeighted(original_image, 0.6, heatmap, 0.4, 0)

    return output
```

This shows WHERE the model is looking to make its decision.

---

## Phase 7: Model Export for Mobile

### Task 7.1: Convert to TFLite (for Flutter)
```python
# Convert to TensorFlow Lite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()

# Save
with open('kidney_stone_model.tflite', 'wb') as f:
    f.write(tflite_model)
```

### Task 7.2: Model Size Optimization
- Quantization (INT8) for smaller size
- Target: <50MB for mobile deployment

---

## Phase 8: Flutter Integration

### Task 8.1: Add TFLite to Flutter
```yaml
# pubspec.yaml
dependencies:
  tflite_flutter: ^0.10.4
  image_picker: ^1.0.4
  image: ^4.1.3
```

### Task 8.2: Prediction Service
```dart
class KidneyStonePredictor {
  Interpreter? _interpreter;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('kidney_stone_model.tflite');
  }

  Future<Map<String, dynamic>> predict(File imageFile) async {
    // Preprocess image
    final input = preprocessImage(imageFile);

    // Run inference
    final output = List.filled(1, 0.0).reshape([1, 1]);
    _interpreter!.run(input, output);

    final confidence = output[0][0];
    return {
      'hasStone': confidence > 0.5,
      'confidence': confidence,
      'result': confidence > 0.5 ? 'Stone Detected' : 'Normal',
    };
  }
}
```

---

## Implementation Timeline

| Phase | Task | Duration |
|-------|------|----------|
| 1 | Dataset Acquisition | 1-2 days |
| 2 | Preprocessing Pipeline | 1 day |
| 3 | Model Architecture | 2 days |
| 4 | Training & Tuning | 2-3 days |
| 5 | Evaluation & Testing | 1 day |
| 6 | Grad-CAM Integration | 1 day |
| 7 | TFLite Conversion | 1 day |
| 8 | Flutter Integration | 1-2 days |

**Total: ~10-14 days**

---

## File Structure

```
ml_model/
├── data/
│   ├── raw/                    # Original images
│   └── processed/              # Preprocessed images
├── notebooks/
│   ├── 01_data_exploration.ipynb
│   ├── 02_preprocessing.ipynb
│   ├── 03_model_training.ipynb
│   ├── 04_evaluation.ipynb
│   └── 05_gradcam.ipynb
├── src/
│   ├── preprocessing.py        # Image preprocessing
│   ├── models.py               # Model architectures
│   ├── train.py                # Training script
│   ├── evaluate.py             # Evaluation metrics
│   └── export.py               # TFLite conversion
├── models/
│   ├── cnn_xgboost.pkl         # Trained CNN+XGBoost
│   ├── vgg16_xgboost.pkl       # Trained VGG16+XGBoost
│   └── kidney_stone.tflite     # Mobile model
├── requirements.txt
└── README.md
```

---

## Key Contributions (for Publication)

1. **Combined Methodology**: Unified preprocessing (Paper 2) with hybrid CNN+XGBoost (Paper 1)
2. **Improved Preprocessing**: CLAHE + Bilateral Filter for better ultrasound quality
3. **Comparative Study**: CNN vs VGG16 vs Hybrid approaches on same dataset
4. **Explainability**: Grad-CAM for medical decision support
5. **Practical Deployment**: End-to-end mobile app (RayScan)
6. **Large Dataset**: Training on significantly larger dataset than original papers

---

## Next Steps

1. **Search for kidney ultrasound datasets** on Kaggle/GitHub
2. **Set up Python environment** with TensorFlow, OpenCV, XGBoost
3. **Start with preprocessing pipeline** implementation
4. **Train both models** and compare results
5. **Export best model** to TFLite
6. **Integrate into Flutter app**

---

Ready to start? Let me know and I'll begin with Phase 1: Dataset Acquisition!
