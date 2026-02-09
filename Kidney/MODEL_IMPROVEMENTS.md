# Enhanced Kidney Stone Detection Model

## Overview

This implementation improves upon the original kidney stone detection model by incorporating techniques from two key research papers:

1. **"Ultrasound renal stone diagnosis based on CNN and VGG16 features"**
   - VGG16 feature extraction
   - XGBoost classification
   - ~99.47% reported accuracy

2. **"Automated Detection of Kidney Stones in Ultrasound Images"** - Gurjeet Kaur et al.
   - Traditional image filtering
   - End-to-end CNN classifier
   - ~99.1% reported accuracy on 9,416 images

## Key Improvements

### 1. **Enhanced Image Preprocessing**

#### CLAHE (Contrast Limited Adaptive Histogram Equalization)
- Enhances local contrast in ultrasound images
- Particularly effective for medical imaging where subtle features matter
- Improves visibility of kidney stones against tissue background

#### Bilateral Filtering
- Reduces noise while preserving edges
- Critical for ultrasound images which often have speckle noise
- Maintains important boundary information for stone detection

### 2. **Hybrid Architecture**

#### VGG16 Feature Extraction
- Pretrained on ImageNet (transfer learning)
- Extracts high-level features from ultrasound images
- 512-dimensional feature vectors per image

#### XGBoost Classification
- Trained on VGG16 features
- Handles imbalanced datasets well
- Provides feature importance metrics
- Fast inference

#### End-to-End Hybrid Model
- Combines VGG16 backbone with custom classification head
- Fine-tuned for kidney stone detection
- Single .h5 file for easy deployment
- Compatible with mobile integration (Flutter app)

### 3. **Improved Training Strategy**

- **Data Augmentation**: Rotation, shifts, zoom, flips
- **Stratified Splitting**: Ensures balanced train/val/test sets
- **Early Stopping**: Prevents overfitting
- **Learning Rate Scheduling**: Adaptive learning rate reduction
- **Checkpoint Saving**: Saves best model based on validation accuracy

## Model Comparison

### Original Model (Basic CNN)
```
- Architecture: Simple 3-layer CNN
- Preprocessing: Basic resize + normalize
- Accuracy: Variable (overfitting issues)
```

### Improved Model (Hybrid VGG16+XGBoost)
```
- Architecture: VGG16 (pretrained) + XGBoost
- Preprocessing: CLAHE + Bilateral Filter + normalize
- Expected Accuracy: ~99%+ (based on papers)
- Benefits:
  ✅ Better feature extraction (transfer learning)
  ✅ Enhanced preprocessing for ultrasound images
  ✅ Reduced overfitting
  ✅ More robust to variations
```

## Files Structure

```
Kidney/
├── Dataset/
│   ├── normal/          # Normal kidney ultrasound images
│   └── stone/           # Kidney stone ultrasound images
│
├── Kidney/              # Model output directory
│   ├── kidney_stone_hybrid.h5          # ✅ NEW: Hybrid model (use this)
│   ├── vgg16_feature_extractor.h5      # VGG16 feature extractor
│   ├── xgboost_classifier.pkl          # XGBoost classifier
│   └── kidney_stone_cnn.h5             # OLD: Basic CNN (fallback)
│
├── train_improved_model.py              # ✅ NEW: Train hybrid model
├── ml_service_improved.py               # ✅ NEW: Enhanced ML service
├── retrain_model.py                     # OLD: Train basic CNN
└── ml_service.py                        # OLD: Basic ML service
```

## Installation & Usage

### Step 1: Install Dependencies

```bash
pip install tensorflow opencv-python xgboost scikit-learn flask flask-cors matplotlib
```

### Step 2: Prepare Dataset

Ensure your dataset is organized as:
```
Kidney/Dataset/
├── normal/
│   ├── Normal_1.JPG
│   ├── Normal_2.JPG
│   └── ...
└── stone/
    ├── Stone_1.JPG
    ├── Stone_2.JPG
    └── ...
```

### Step 3: Train the Improved Model

```bash
cd Kidney
python train_improved_model.py
```

**Expected Output:**
- `kidney_stone_hybrid.h5` - Main deployment model
- `vgg16_feature_extractor.h5` - Feature extractor (for analysis)
- `xgboost_classifier.pkl` - XGBoost model (for comparison)

Training will take **30-60 minutes** depending on:
- Dataset size (~9,000+ images recommended)
- GPU availability (uses GPU if available)

### Step 4: Start the Enhanced ML Service

```bash
python ml_service_improved.py
```

The service will:
- Load the hybrid model automatically
- Fall back to basic CNN if hybrid not available
- Start on port 5000
- Apply enhanced preprocessing (CLAHE + Bilateral)

### Step 5: Test the Service

```bash
# Health check
curl http://localhost:5000/health

# Prediction (from command line)
curl -X POST -F "image=@test_ultrasound.jpg" http://localhost:5000/predict
```

## API Response Format

```json
{
  "success": true,
  "data": {
    "prediction": "Stone Detected",
    "confidence": 95.67,
    "confidence_score": 0.9567,
    "raw_score": 0.9567,
    "has_kidney_stone": true,
    "model_type": "Hybrid VGG16+XGBoost",
    "preprocessing": "enhanced"
  }
}
```

## Integration with Flutter App

The enhanced model is **fully compatible** with your existing Flutter app. No changes needed in the app code!

1. Stop the old ML service (if running)
2. Start the new enhanced service:
   ```bash
   python ml_service_improved.py
   ```
3. The service automatically detects which model is available
4. Same API endpoints, enhanced predictions ✅

## Performance Expectations

Based on the research papers and our implementation:

| Metric | Expected Range |
|--------|---------------|
| Accuracy | 97-99% |
| Precision | 96-99% |
| Recall | 95-98% |
| F1-Score | 96-98% |
| Inference Time | < 500ms per image |

## Preprocessing Visualization

### Without Enhancement:
```
Original Image → Resize → Normalize → Predict
```

### With Enhancement (NEW):
```
Original Image → Bilateral Filter → CLAHE → Resize → Normalize → Predict
                 (denoise)          (contrast)
```

## Model Architecture Details

### VGG16 Feature Extractor
```
Input: 224x224x3 ultrasound image
↓
VGG16 (pretrained, frozen layers)
↓
GlobalAveragePooling2D
↓
Output: 512 features
```

### Hybrid Classification Head
```
VGG16 Features (512)
↓
Dense(512, relu) + BatchNorm + Dropout(0.5)
↓
Dense(256, relu) + BatchNorm + Dropout(0.4)
↓
Dense(1, sigmoid)
↓
Output: Stone probability [0, 1]
```

## Troubleshooting

### Model Not Loading
```bash
# Check if model exists
ls -lh Kidney/kidney_stone_hybrid.h5

# If missing, train the model
python train_improved_model.py
```

### Low Accuracy
1. **Check dataset quality**: Remove corrupted images
2. **Verify data balance**: Should have similar counts for normal/stone
3. **Try more epochs**: Increase EPOCHS in training script
4. **Check preprocessing**: Ensure images are ultrasound format

### Memory Errors
1. Reduce BATCH_SIZE in training script (try 16 or 8)
2. Close other applications
3. Use GPU if available (CUDA)

## Future Enhancements

- [ ] Grad-CAM visualization for explainability
- [ ] Ensemble models (combine multiple architectures)
- [ ] Real-time video stream processing
- [ ] Multi-class classification (stone size/type)
- [ ] Edge deployment (TensorFlow Lite for mobile)

## References

1. "Ultrasound renal stone diagnosis based on CNN and VGG16 features"
   - VGG16 + XGBoost approach
   - 99.47% accuracy

2. "Automated Detection of Kidney Stones in Ultrasound Images" - Gurjeet Kaur et al.
   - Image filtering + CNN
   - 99.1% accuracy on 9,416 images

## Citation

If you use this model in your research or application, please cite the original papers and acknowledge this implementation.

---

**Author**: RayScan ML Team
**Last Updated**: 2025
**Version**: 2.0.0
