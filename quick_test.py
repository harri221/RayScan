"""Quick test of TFLite model"""
import tensorflow as tf
import numpy as np
from PIL import Image
import os

# Load TFLite model
tflite_path = r'c:\Users\Admin\Downloads\flutter_application_1\assets\models\kidney_stone.tflite'
interpreter = tf.lite.Interpreter(model_path=tflite_path)
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print(f"Model input shape: {input_details[0]['shape']}")
print(f"Model output shape: {output_details[0]['shape']}")
print(f"Input dtype: {input_details[0]['dtype']}")

# Test with a few stone images
stone_dir = r'c:\Users\Admin\Downloads\flutter_application_1\ds\stone'
normal_dir = r'c:\Users\Admin\Downloads\flutter_application_1\ds\normal'

def test_image(img_path, true_label):
    img = Image.open(img_path).convert('RGB')
    img = img.resize((224, 224))
    img_array = np.array(img, dtype=np.float32) / 255.0
    img_array = np.expand_dims(img_array, axis=0)

    interpreter.set_tensor(input_details[0]['index'], img_array)
    interpreter.invoke()
    output = interpreter.get_tensor(output_details[0]['index'])

    pred_prob = output[0][0]
    pred_class = 1 if pred_prob > 0.5 else 0

    return pred_prob, pred_class

print("\nTesting stone images:")
stone_images = [f for f in os.listdir(stone_dir) if f.lower().endswith(('.jpg', '.jpeg', '.png'))][:5]
for img_name in stone_images:
    prob, pred = test_image(os.path.join(stone_dir, img_name), 1)
    print(f"  {img_name}: prob={prob:.4f}, pred={pred} (expected=1)")

print("\nTesting normal images:")
normal_images = [f for f in os.listdir(normal_dir) if f.lower().endswith(('.jpg', '.jpeg', '.png'))][:5]
for img_name in normal_images:
    prob, pred = test_image(os.path.join(normal_dir, img_name), 0)
    print(f"  {img_name}: prob={prob:.4f}, pred={pred} (expected=0)")
