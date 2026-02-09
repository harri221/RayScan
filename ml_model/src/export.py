"""
RayScan ML Model - TFLite Export
Convert trained models to TensorFlow Lite for mobile deployment
"""

import os
import numpy as np
import tensorflow as tf
from tensorflow import keras
from pathlib import Path
import json


class TFLiteExporter:
    """
    Export Keras models to TensorFlow Lite format for mobile deployment.
    """

    def __init__(self, model, input_shape=(224, 224, 1)):
        """
        Initialize exporter.

        Args:
            model: Trained Keras model
            input_shape: Expected input shape
        """
        self.model = model
        self.input_shape = input_shape

    def export_basic(self, output_path):
        """
        Basic TFLite conversion without optimization.

        Args:
            output_path: Path to save .tflite file

        Returns:
            Model size in MB
        """
        converter = tf.lite.TFLiteConverter.from_keras_model(self.model)
        tflite_model = converter.convert()

        with open(output_path, 'wb') as f:
            f.write(tflite_model)

        size_mb = len(tflite_model) / (1024 * 1024)
        print(f"Basic TFLite model: {output_path} ({size_mb:.2f} MB)")

        return size_mb

    def export_quantized(self, output_path, quantization='dynamic'):
        """
        Export with quantization for smaller model size.

        Args:
            output_path: Path to save .tflite file
            quantization: 'dynamic' (default), 'float16', or 'int8'

        Returns:
            Model size in MB
        """
        converter = tf.lite.TFLiteConverter.from_keras_model(self.model)

        if quantization == 'dynamic':
            # Dynamic range quantization (most common)
            converter.optimizations = [tf.lite.Optimize.DEFAULT]

        elif quantization == 'float16':
            # Float16 quantization (good for GPU inference)
            converter.optimizations = [tf.lite.Optimize.DEFAULT]
            converter.target_spec.supported_types = [tf.float16]

        elif quantization == 'int8':
            # Full integer quantization (requires representative dataset)
            converter.optimizations = [tf.lite.Optimize.DEFAULT]
            converter.target_spec.supported_types = [tf.int8]

        tflite_model = converter.convert()

        with open(output_path, 'wb') as f:
            f.write(tflite_model)

        size_mb = len(tflite_model) / (1024 * 1024)
        print(f"Quantized ({quantization}) TFLite model: {output_path} ({size_mb:.2f} MB)")

        return size_mb

    def export_int8_full(self, output_path, representative_data):
        """
        Full INT8 quantization with representative dataset.
        Smallest size, best for mobile CPU.

        Args:
            output_path: Path to save .tflite file
            representative_data: Sample of training data for calibration

        Returns:
            Model size in MB
        """
        converter = tf.lite.TFLiteConverter.from_keras_model(self.model)
        converter.optimizations = [tf.lite.Optimize.DEFAULT]

        # Representative dataset generator
        def representative_dataset():
            for i in range(min(100, len(representative_data))):
                sample = representative_data[i:i+1].astype(np.float32)
                yield [sample]

        converter.representative_dataset = representative_dataset
        converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
        converter.inference_input_type = tf.uint8
        converter.inference_output_type = tf.uint8

        tflite_model = converter.convert()

        with open(output_path, 'wb') as f:
            f.write(tflite_model)

        size_mb = len(tflite_model) / (1024 * 1024)
        print(f"INT8 Full TFLite model: {output_path} ({size_mb:.2f} MB)")

        return size_mb

    def verify_model(self, tflite_path, test_images, expected_outputs=None):
        """
        Verify TFLite model produces correct outputs.

        Args:
            tflite_path: Path to .tflite file
            test_images: Sample images for testing
            expected_outputs: Expected outputs (optional)

        Returns:
            True if verification passes
        """
        # Load TFLite model
        interpreter = tf.lite.Interpreter(model_path=str(tflite_path))
        interpreter.allocate_tensors()

        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()

        print(f"\nModel Verification:")
        print(f"  Input shape: {input_details[0]['shape']}")
        print(f"  Input type: {input_details[0]['dtype']}")
        print(f"  Output shape: {output_details[0]['shape']}")
        print(f"  Output type: {output_details[0]['dtype']}")

        # Test inference
        results = []
        for img in test_images[:5]:
            # Prepare input
            input_data = np.expand_dims(img, axis=0).astype(input_details[0]['dtype'])

            # Handle quantized input
            if input_details[0]['dtype'] == np.uint8:
                input_scale, input_zero = input_details[0]['quantization']
                input_data = (img / input_scale + input_zero).astype(np.uint8)
                input_data = np.expand_dims(input_data, axis=0)

            interpreter.set_tensor(input_details[0]['index'], input_data)
            interpreter.invoke()

            output = interpreter.get_tensor(output_details[0]['index'])

            # Handle quantized output
            if output_details[0]['dtype'] == np.uint8:
                output_scale, output_zero = output_details[0]['quantization']
                output = (output.astype(np.float32) - output_zero) * output_scale

            results.append(output[0])

        print(f"  Sample predictions: {[f'{r[0]:.4f}' for r in results]}")

        if expected_outputs is not None:
            keras_results = self.model.predict(test_images[:5], verbose=0)
            max_diff = np.max(np.abs(np.array(results).flatten() - keras_results.flatten()))
            print(f"  Max difference from Keras: {max_diff:.6f}")

            if max_diff < 0.1:
                print("  ✅ Verification PASSED")
                return True
            else:
                print("  ⚠️  Verification WARNING: Large difference detected")
                return False

        return True

    def export_all(self, output_dir, representative_data=None, test_images=None):
        """
        Export model in all formats for comparison.

        Args:
            output_dir: Directory to save models
            representative_data: Data for INT8 calibration
            test_images: Images for verification

        Returns:
            Dictionary of model sizes
        """
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)

        sizes = {}

        print("\n" + "="*60)
        print("TFLite Model Export")
        print("="*60)

        # Basic (no quantization)
        basic_path = output_path / 'kidney_stone_basic.tflite'
        sizes['basic'] = self.export_basic(basic_path)

        # Dynamic quantization
        dynamic_path = output_path / 'kidney_stone_dynamic.tflite'
        sizes['dynamic'] = self.export_quantized(dynamic_path, 'dynamic')

        # Float16 quantization
        float16_path = output_path / 'kidney_stone_float16.tflite'
        sizes['float16'] = self.export_quantized(float16_path, 'float16')

        # INT8 full quantization (if representative data provided)
        if representative_data is not None:
            int8_path = output_path / 'kidney_stone_int8.tflite'
            sizes['int8'] = self.export_int8_full(int8_path, representative_data)

        # Print comparison
        print("\n📊 Model Size Comparison:")
        for name, size in sizes.items():
            print(f"   {name}: {size:.2f} MB")

        # Find smallest
        smallest = min(sizes, key=sizes.get)
        print(f"\n🏆 Smallest model: {smallest} ({sizes[smallest]:.2f} MB)")

        # Recommend best for mobile
        if sizes.get('dynamic', float('inf')) < 50:
            recommended = 'dynamic'
        elif sizes.get('float16', float('inf')) < 50:
            recommended = 'float16'
        else:
            recommended = 'basic'

        print(f"📱 Recommended for mobile: {recommended}")

        # Verify models
        if test_images is not None:
            print("\n🔍 Verifying models...")
            for name in sizes.keys():
                path = output_path / f'kidney_stone_{name}.tflite'
                self.verify_model(path, test_images)

        # Save metadata
        metadata = {
            'input_shape': list(self.input_shape),
            'sizes_mb': sizes,
            'recommended': recommended,
            'class_names': ['Normal', 'Stone']
        }

        with open(output_path / 'model_metadata.json', 'w') as f:
            json.dump(metadata, f, indent=2)

        print(f"\n✅ All models exported to: {output_path}")

        return sizes


def create_flutter_model(keras_model, output_path, representative_data=None):
    """
    Create optimized TFLite model for Flutter app.

    Args:
        keras_model: Trained Keras model
        output_path: Path to save .tflite file
        representative_data: Data for INT8 calibration (optional)

    Returns:
        Model size in MB
    """
    print("\n📱 Creating Flutter-optimized TFLite Model...")

    exporter = TFLiteExporter(keras_model)

    # Use dynamic quantization for good balance of size and accuracy
    size = exporter.export_quantized(output_path, quantization='dynamic')

    if size > 50:
        print("⚠️  Warning: Model is larger than 50MB. Consider:")
        print("    - Using Float16 quantization")
        print("    - Using a smaller architecture")
        print("    - Pruning the model")

    # Create labels file
    labels_path = Path(output_path).parent / 'labels.txt'
    with open(labels_path, 'w') as f:
        f.write("Normal\nStone")

    print(f"\n✅ Flutter model ready:")
    print(f"   - Model: {output_path}")
    print(f"   - Labels: {labels_path}")
    print(f"   - Size: {size:.2f} MB")

    return size


if __name__ == "__main__":
    print("RayScan TFLite Exporter")
    print("="*50)
    print("\nUsage:")
    print("  exporter = TFLiteExporter(trained_model)")
    print("  exporter.export_all('output_dir/')")
    print("\nFor Flutter:")
    print("  create_flutter_model(model, 'kidney_stone.tflite')")
