# RayScan ML Model Integration Guide

## ✅ What You've Accomplished

### 1. Model Training Results
- **Accuracy**: 99.58%
- **Sensitivity (Stone Detection)**: 99.87% - Almost never misses a stone!
- **Specificity (Normal Detection)**: 99.24%
- **AUC-ROC**: 0.9977 - Excellent discrimination

### 2. Dataset Used
- **Total Images**: 9,416 ultrasound images
- **Stone Images**: 5,002
- **Normal Images**: 4,414
- **Source**: Kidney Ultrasound Dataset (Kaggle)

### 3. Model Architecture
- Custom CNN with 4 convolutional blocks
- Batch Normalization + Dropout for regularization
- Data augmentation during training
- Preprocessing: Bilateral Filter + CLAHE (from Paper 2)

### 4. Files Created
- **TFLite Model**: `assets/models/kidney_stone.tflite` (25.15 MB)
- **Keras Model**: `ml_model/models/best_model.keras`
- **Flutter Service**: `lib/services/kidney_stone_detector.dart`

---

## 📱 How to Use ML Model in Flutter

The ML model is already integrated! Here's how to use it:

### Option 1: On-Device Prediction (TFLite)
```dart
import 'package:flutter_application_1/services/kidney_stone_detector.dart';

// Initialize detector
final detector = KidneyStoneDetector();
await detector.initialize();

// Predict from image file
final result = await detector.predictFromFile(imageFile);

print('Has Stone: ${result.hasStone}');
print('Confidence: ${result.confidence}');
print('Severity: ${result.severity}');
print('Recommendation: ${result.recommendationText}');
```

### Option 2: Server-Side Prediction (Existing API)
```dart
import 'package:flutter_application_1/services/ml_service.dart';

final report = await MLService.predictKidneyStone(imagePath);
```

---

## 🚀 Next Steps

### To Test the Model:

1. **Install the APK** on your phone:
   - APK location: `build/app/outputs/flutter-apk/app-release.apk`
   - Transfer to phone and install

2. **Test with Kidney Stone Images**:
   - Upload an ultrasound image
   - The model will detect if there's a stone
   - You'll get confidence score and recommendation

3. **Features You Can Add**:
   - Upload ultrasound image screen
   - Show detection results with confidence
   - Display Grad-CAM heatmap (visual explanation)
   - Save detection history

---

## 📊 Model Performance Details

### Confusion Matrix
```
                Predicted
              Normal  Stone
Actual Normal   657      5     (99.24% correct)
       Stone      1    750     (99.87% correct)
```

### What This Means:
- **Out of 751 stone cases**: Detected 750 correctly (missed only 1)
- **Out of 662 normal cases**: Detected 657 correctly (5 false alarms)
- **False Negative Rate**: 0.13% (very safe - rarely misses stones)
- **False Positive Rate**: 0.76% (low false alarms)

---

## 🔧 Retraining the Model

If you want to retrain with different parameters:

```bash
cd ml_model
venv\Scripts\activate
python train_model.py
```

The script will:
1. Load your dataset
2. Preprocess images
3. Train the model
4. Evaluate performance
5. Export to TFLite
6. Copy to Flutter assets automatically

---

## 📝 Technical Details

### Preprocessing Pipeline
1. Load as grayscale
2. **Bilateral Filter** - Removes noise while preserving edges
3. **CLAHE** - Enhances contrast for better stone visibility
4. Resize to 224x224
5. Normalize to [0, 1]

### Model Inputs
- **Input**: 224x224 grayscale image
- **Output**: Probability of kidney stone (0-1)
- **Threshold**: 0.5 (adjustable)

### Model Size
- **TFLite (Optimized)**: 25.15 MB
- **Keras (Full)**: ~100 MB

---

## 🎯 Using the Model in Your App

### Example Integration:

```dart
class KidneyStoneScanner extends StatefulWidget {
  @override
  _KidneyStoneScannerState createState() => _KidneyStoneScannerState();
}

class _KidneyStoneScannerState extends State<KidneyStoneScanner> {
  final detector = KidneyStoneDetector();
  DetectionResult? result;

  @override
  void initState() {
    super.initState();
    detector.initialize();
  }

  Future<void> analyzeImage(File imageFile) async {
    setState(() => result = null);

    final detectionResult = await detector.predictFromFile(imageFile);

    setState(() => result = detectionResult);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kidney Stone Detection')),
      body: Column(
        children: [
          // Image upload button
          ElevatedButton(
            onPressed: pickAndAnalyzeImage,
            child: Text('Upload Ultrasound Image'),
          ),

          // Results
          if (result != null) ...[
            Text('Result: ${result!.message}'),
            Text('Confidence: ${(result!.confidence * 100).toStringAsFixed(1)}%'),
            Text('Severity: ${result!.severity}'),
            Text('Recommendation: ${result!.recommendationText}'),
          ],
        ],
      ),
    );
  }
}
```

---

## 🏥 Medical Disclaimer

This model is for **educational and assistive purposes only**. It should NOT replace professional medical diagnosis. Always consult with a qualified urologist or radiologist for:
- Final diagnosis
- Treatment decisions
- Medical advice

The model can assist in:
- Preliminary screening
- Second opinion support
- Educational demonstrations
- Research purposes

---

## 📚 References

Based on research papers:
1. **CNN + XGBoost methodology** - IJECE 2023 (99.47% accuracy)
2. **Bilateral Filter + CLAHE preprocessing** - AECE 2022

---

## ✨ Congratulations!

You now have a **99.58% accurate** kidney stone detection model running in your Flutter app!

The model is:
- ✅ Trained on 9,416 real ultrasound images
- ✅ Optimized for mobile devices (25 MB)
- ✅ Ready to use on-device (no internet needed)
- ✅ Highly accurate (99.87% sensitivity)
- ✅ Integrated into your Flutter app

**Next**: Test it with real ultrasound images and share with your supervisor!
