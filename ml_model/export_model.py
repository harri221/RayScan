"""
Quick script to export VGG16 model to TFLite
"""
import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'

import tensorflow as tf
from pathlib import Path

print("Loading VGG16 model...")
model_path = Path(__file__).parent / "models" / "vgg16_best.keras"
model = tf.keras.models.load_model(str(model_path))
print("Model loaded!")

print("\nConverting to TFLite...")
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.target_spec.supported_types = [tf.float16]
tflite_model = converter.convert()

# Save to models folder
output_path = Path(__file__).parent / "models" / "kidney_stone_vgg16.tflite"
with open(output_path, 'wb') as f:
    f.write(tflite_model)
print(f"Saved to: {output_path}")
print(f"Size: {len(tflite_model) / (1024*1024):.2f} MB")

# Copy to Flutter assets
flutter_path = Path(__file__).parent.parent / "assets" / "models" / "kidney_stone.tflite"
with open(flutter_path, 'wb') as f:
    f.write(tflite_model)
print(f"Copied to Flutter: {flutter_path}")

print("\nDone! Model ready for Flutter app.")
