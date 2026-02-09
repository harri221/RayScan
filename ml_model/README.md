# RayScan ML Model - Kidney Stone Detection

## Overview

Machine Learning model for detecting kidney stones in ultrasound images. Based on methodologies from two research papers:

1. **Paper 1 (IJECE 2023)**: CNN + VGG16 feature extraction with XGBoost/Random Forest classifiers (99.47% accuracy)
2. **Paper 2 (AECE 2022)**: Image preprocessing with Bilateral Filter + CLAHE

## Quick Start

### 1. Setup Python Environment

```bash
# Create virtual environment
python -m venv venv

# Activate (Windows)
venv\Scripts\activate

# Activate (Linux/Mac)
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Download Dataset

**Option A: Automatic (Kaggle API)**

1. Get Kaggle API credentials:
   - Go to https://www.kaggle.com/settings
   - Click "Create New Token" under API section
   - Move downloaded `kaggle.json` to `~/.kaggle/` (or `C:\Users\<username>\.kaggle\` on Windows)

2. Run download script:
```bash
python download_dataset.py
```

**Option B: Manual Download**

1. Download from: https://www.kaggle.com/datasets/gurjeetkaurmangat/kidney-ultrasound-images-stone-and-no-stone
2. Extract and organize into:
```
data/processed/
├── train/
│   ├── stone/
│   └── normal/
├── val/
│   ├── stone/
│   └── normal/
└── test/
    ├── stone/
    └── normal/
```

### 3. Train Model

```bash
cd src

# Train CNN + XGBoost (recommended)
python train.py --data_dir ../data/processed --model cnn_xgboost

# Train VGG16 + XGBoost
python train.py --data_dir ../data/processed --model vgg16_xgboost

# Train all models for comparison
python train.py --data_dir ../data/processed --model all
```

### 4. Export to TFLite (for Flutter)

```bash
python -c "
from export import create_flutter_model
from tensorflow import keras

model = keras.models.load_model('../models/end_to_end_cnn.keras')
create_flutter_model(model, '../models/kidney_stone.tflite')
"
```

## Project Structure

```
ml_model/
├── data/
│   ├── raw/                    # Original downloaded images
│   └── processed/              # Preprocessed train/val/test splits
├── notebooks/                  # Jupyter notebooks for exploration
├── src/
│   ├── preprocessing.py        # Bilateral Filter + CLAHE pipeline
│   ├── models.py               # CNN, VGG16, Hybrid architectures
│   ├── train.py                # Training script
│   ├── evaluate.py             # Evaluation metrics
│   ├── gradcam.py              # Grad-CAM explainability
│   └── export.py               # TFLite conversion
├── models/                     # Trained model files
├── download_dataset.py         # Dataset download script
├── requirements.txt            # Python dependencies
└── README.md                   # This file
```

## Model Architectures

### 1. Custom CNN + XGBoost (Hybrid)
- Custom CNN extracts 256 features
- XGBoost classifier for final prediction
- Best for: High accuracy with interpretability

### 2. VGG16 + XGBoost (Transfer Learning)
- Pre-trained VGG16 extracts 512 features
- XGBoost classifier for final prediction
- Best for: Leveraging ImageNet knowledge

### 3. End-to-End CNN
- Full CNN with classification head
- Trained end-to-end
- Best for: TFLite conversion (single model file)

## Preprocessing Pipeline

Based on Paper 2 methodology:

1. **Crop ROI** - Remove scan metadata/borders
2. **Bilateral Filter** - Noise reduction (preserves edges)
3. **CLAHE** - Contrast enhancement
4. **Resize** - 224x224 pixels
5. **Normalize** - Scale to [0, 1]

```python
from preprocessing import UltrasoundPreprocessor

preprocessor = UltrasoundPreprocessor(target_size=(224, 224))
img = preprocessor.preprocess_single('ultrasound.jpg')
```

## Evaluation Metrics

Target metrics (based on papers):
- **Accuracy**: >95%
- **Recall (Sensitivity)**: >97% - Critical for not missing stones!
- **Precision**: >93%
- **AUC-ROC**: >0.98

## Grad-CAM Explainability

Visualize where the model is looking:

```python
from gradcam import GradCAM

gradcam = GradCAM(model)
heatmap, overlay = gradcam.visualize(image, original_image)
```

## Flutter Integration

After exporting to TFLite:

1. Copy `kidney_stone.tflite` to `assets/` in Flutter project
2. Add to `pubspec.yaml`:
```yaml
dependencies:
  tflite_flutter: ^0.10.4
```

3. Use the predictor:
```dart
class KidneyStonePredictor {
  Interpreter? _interpreter;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('kidney_stone.tflite');
  }

  Future<Map<String, dynamic>> predict(Uint8List imageBytes) async {
    // Preprocess and run inference
    // See lib/services/ml_service.dart for full implementation
  }
}
```

## Datasets

| Dataset | Type | Images | Source |
|---------|------|--------|--------|
| Kidney Ultrasound Stone/No Stone | Ultrasound | ~8,700 | [Kaggle](https://www.kaggle.com/datasets/gurjeetkaurmangat/kidney-ultrasound-images-stone-and-no-stone) |
| CT Kidney Dataset | CT | ~12,000 | [Kaggle](https://www.kaggle.com/datasets/nazmul0087/ct-kidney-dataset-normal-cyst-tumor-and-stone) |
| Open Kidney Dataset | Ultrasound | ~500 | [GitHub](https://github.com/rsingla92/kidneyUS) |

## References

1. CNN + XGBoost methodology: IJECE 2023
2. Bilateral Filter + CLAHE preprocessing: AECE 2022
3. Grad-CAM: "Grad-CAM: Visual Explanations from Deep Networks"

## License

This project is for educational and research purposes. Please cite the original papers if using the methodology.
