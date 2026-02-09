"""
RayScan ML Model - Grad-CAM Explainability
Visual explanations for kidney stone detection predictions
Based on: "Grad-CAM: Visual Explanations from Deep Networks"
"""

import numpy as np
import tensorflow as tf
from tensorflow import keras
import cv2
import matplotlib.pyplot as plt
from matplotlib import cm


class GradCAM:
    """
    Gradient-weighted Class Activation Mapping (Grad-CAM)
    Generates visual explanations for CNN predictions.
    """

    def __init__(self, model, layer_name=None):
        """
        Initialize Grad-CAM.

        Args:
            model: Trained Keras model
            layer_name: Name of the convolutional layer to visualize
                       If None, uses the last conv layer
        """
        self.model = model
        self.layer_name = layer_name or self._find_last_conv_layer()

        # Create gradient model
        self.grad_model = self._create_grad_model()

    def _find_last_conv_layer(self):
        """Find the last convolutional layer in the model."""
        for layer in reversed(self.model.layers):
            if isinstance(layer, keras.layers.Conv2D):
                return layer.name

            # Check inside nested models (like VGG16)
            if hasattr(layer, 'layers'):
                for sub_layer in reversed(layer.layers):
                    if isinstance(sub_layer, keras.layers.Conv2D):
                        return f"{layer.name}/{sub_layer.name}"

        raise ValueError("No convolutional layer found in the model")

    def _create_grad_model(self):
        """Create model that outputs conv layer activations and predictions."""
        # Handle nested models (for VGG16)
        if '/' in self.layer_name:
            model_name, layer_name = self.layer_name.split('/')
            nested_model = self.model.get_layer(model_name)
            conv_output = nested_model.get_layer(layer_name).output
        else:
            conv_output = self.model.get_layer(self.layer_name).output

        grad_model = keras.Model(
            inputs=self.model.input,
            outputs=[conv_output, self.model.output]
        )

        return grad_model

    def compute_heatmap(self, image, class_idx=None, eps=1e-8):
        """
        Compute Grad-CAM heatmap for an image.

        Args:
            image: Preprocessed image (batch of 1)
            class_idx: Class index for gradient computation
                      If None, uses predicted class
            eps: Small value to avoid division by zero

        Returns:
            Heatmap as numpy array
        """
        # Ensure batch dimension
        if len(image.shape) == 3:
            image = np.expand_dims(image, axis=0)

        # Cast to float32
        image = tf.cast(image, tf.float32)

        # Record gradients
        with tf.GradientTape() as tape:
            tape.watch(image)
            conv_outputs, predictions = self.grad_model(image)

            if class_idx is None:
                class_idx = tf.argmax(predictions[0])

            # Get prediction for target class
            if len(predictions.shape) == 2 and predictions.shape[1] == 1:
                # Binary classification with single output
                class_output = predictions[0, 0]
            else:
                class_output = predictions[0, class_idx]

        # Compute gradients
        grads = tape.gradient(class_output, conv_outputs)

        # Global average pooling of gradients
        pooled_grads = tf.reduce_mean(grads, axis=(0, 1, 2))

        # Weight feature maps by gradients
        conv_outputs = conv_outputs[0]
        heatmap = tf.reduce_sum(conv_outputs * pooled_grads, axis=-1)

        # ReLU and normalize
        heatmap = tf.maximum(heatmap, 0)
        heatmap = heatmap / (tf.reduce_max(heatmap) + eps)

        return heatmap.numpy()

    def overlay_heatmap(self, heatmap, original_image, alpha=0.4, colormap=cv2.COLORMAP_JET):
        """
        Overlay heatmap on original image.

        Args:
            heatmap: Grad-CAM heatmap
            original_image: Original image (grayscale or RGB)
            alpha: Opacity of heatmap overlay
            colormap: OpenCV colormap

        Returns:
            Superimposed image
        """
        # Resize heatmap to image size
        h, w = original_image.shape[:2]
        heatmap_resized = cv2.resize(heatmap, (w, h))

        # Convert to uint8
        heatmap_uint8 = np.uint8(255 * heatmap_resized)

        # Apply colormap
        heatmap_colored = cv2.applyColorMap(heatmap_uint8, colormap)

        # Convert grayscale to RGB if needed
        if len(original_image.shape) == 2:
            original_rgb = cv2.cvtColor(original_image, cv2.COLOR_GRAY2RGB)
        else:
            original_rgb = original_image

        # Ensure same type
        if original_rgb.dtype != np.uint8:
            original_rgb = np.uint8(original_rgb * 255)

        # Superimpose
        superimposed = cv2.addWeighted(original_rgb, 1 - alpha, heatmap_colored, alpha, 0)

        return superimposed

    def visualize(self, image, original_image, class_idx=None, save_path=None, figsize=(15, 5)):
        """
        Generate and display Grad-CAM visualization.

        Args:
            image: Preprocessed image for model
            original_image: Original image for display
            class_idx: Target class index
            save_path: Path to save figure
            figsize: Figure size

        Returns:
            Heatmap and superimposed image
        """
        # Compute heatmap
        heatmap = self.compute_heatmap(image, class_idx)

        # Create overlay
        superimposed = self.overlay_heatmap(heatmap, original_image)

        # Get prediction
        if len(image.shape) == 3:
            image = np.expand_dims(image, axis=0)
        pred = self.model.predict(image, verbose=0)

        if pred.shape[-1] == 1:
            pred_class = 'Stone' if pred[0, 0] > 0.5 else 'Normal'
            confidence = pred[0, 0] if pred[0, 0] > 0.5 else 1 - pred[0, 0]
        else:
            pred_class = 'Stone' if np.argmax(pred) == 1 else 'Normal'
            confidence = np.max(pred)

        # Plot
        fig, axes = plt.subplots(1, 3, figsize=figsize)

        # Original image
        if len(original_image.shape) == 2:
            axes[0].imshow(original_image, cmap='gray')
        else:
            axes[0].imshow(original_image)
        axes[0].set_title('Original Image', fontsize=12)
        axes[0].axis('off')

        # Heatmap
        axes[1].imshow(heatmap, cmap='jet')
        axes[1].set_title('Grad-CAM Heatmap', fontsize=12)
        axes[1].axis('off')

        # Superimposed
        axes[2].imshow(cv2.cvtColor(superimposed, cv2.COLOR_BGR2RGB))
        axes[2].set_title(f'Prediction: {pred_class} ({confidence:.1%})', fontsize=12)
        axes[2].axis('off')

        plt.suptitle('Grad-CAM Visualization for Kidney Stone Detection', fontsize=14, y=1.02)
        plt.tight_layout()

        if save_path:
            plt.savefig(save_path, dpi=150, bbox_inches='tight')
            print(f"Visualization saved to: {save_path}")

        plt.show()

        return heatmap, superimposed


class GradCAMPlusPlus(GradCAM):
    """
    Grad-CAM++ - Improved version with weighted gradients.
    Better localization than standard Grad-CAM.
    """

    def compute_heatmap(self, image, class_idx=None, eps=1e-8):
        """
        Compute Grad-CAM++ heatmap.

        Args:
            image: Preprocessed image (batch of 1)
            class_idx: Class index for gradient computation
            eps: Small value to avoid division by zero

        Returns:
            Heatmap as numpy array
        """
        # Ensure batch dimension
        if len(image.shape) == 3:
            image = np.expand_dims(image, axis=0)

        image = tf.cast(image, tf.float32)

        # First forward pass
        with tf.GradientTape() as tape1:
            with tf.GradientTape() as tape2:
                tape1.watch(image)
                tape2.watch(image)
                conv_outputs, predictions = self.grad_model(image)

                if class_idx is None:
                    class_idx = tf.argmax(predictions[0])

                if len(predictions.shape) == 2 and predictions.shape[1] == 1:
                    class_output = predictions[0, 0]
                else:
                    class_output = predictions[0, class_idx]

            # First-order gradients
            first_grads = tape2.gradient(class_output, conv_outputs)

        # Second-order gradients
        second_grads = tape1.gradient(first_grads, conv_outputs)

        conv_outputs = conv_outputs[0]
        first_grads = first_grads[0]
        second_grads = second_grads[0]

        # Compute weights (alpha)
        global_sum = tf.reduce_sum(tf.exp(class_output) * conv_outputs, axis=(0, 1))
        alpha_num = second_grads
        alpha_denom = 2.0 * second_grads + global_sum * tf.pow(first_grads, 3)
        alpha_denom = tf.where(alpha_denom != 0, alpha_denom, tf.ones_like(alpha_denom) * eps)

        alphas = alpha_num / alpha_denom
        weights = tf.reduce_sum(alphas * tf.maximum(first_grads, 0), axis=(0, 1))

        # Generate heatmap
        heatmap = tf.reduce_sum(conv_outputs * weights, axis=-1)
        heatmap = tf.maximum(heatmap, 0)
        heatmap = heatmap / (tf.reduce_max(heatmap) + eps)

        return heatmap.numpy()


def batch_gradcam(model, images, original_images, output_dir, layer_name=None):
    """
    Generate Grad-CAM visualizations for multiple images.

    Args:
        model: Trained model
        images: Batch of preprocessed images
        original_images: Batch of original images
        output_dir: Directory to save visualizations
        layer_name: Name of conv layer to visualize
    """
    from pathlib import Path
    import os

    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    gradcam = GradCAM(model, layer_name)

    for i, (img, orig) in enumerate(zip(images, original_images)):
        save_path = output_path / f'gradcam_{i:04d}.png'
        gradcam.visualize(img, orig, save_path=save_path)
        print(f"Processed {i+1}/{len(images)}")


def generate_gradcam_report(model, X_test, y_test, original_images, output_dir, n_samples=10):
    """
    Generate Grad-CAM report with correct and incorrect predictions.

    Args:
        model: Trained model
        X_test, y_test: Test data
        original_images: Original test images (for visualization)
        output_dir: Output directory
        n_samples: Number of samples per category
    """
    from pathlib import Path

    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    gradcam = GradCAM(model)

    # Get predictions
    if hasattr(model, 'predict_proba'):
        probs = model.predict_proba(X_test)[:, 1]
    else:
        probs = model.predict(X_test).flatten()

    preds = (probs > 0.5).astype(int)

    # Find correct and incorrect predictions
    correct_mask = preds == y_test
    incorrect_mask = ~correct_mask

    # True positives (correctly detected stones)
    tp_mask = correct_mask & (y_test == 1)
    tp_indices = np.where(tp_mask)[0][:n_samples]

    # True negatives (correctly identified normal)
    tn_mask = correct_mask & (y_test == 0)
    tn_indices = np.where(tn_mask)[0][:n_samples]

    # False positives (normal predicted as stone)
    fp_mask = incorrect_mask & (y_test == 0)
    fp_indices = np.where(fp_mask)[0][:n_samples]

    # False negatives (stone predicted as normal)
    fn_mask = incorrect_mask & (y_test == 1)
    fn_indices = np.where(fn_mask)[0][:n_samples]

    categories = [
        ('true_positives', tp_indices, 'Correctly Detected Stones'),
        ('true_negatives', tn_indices, 'Correctly Identified Normal'),
        ('false_positives', fp_indices, 'False Alarms (Normal → Stone)'),
        ('false_negatives', fn_indices, 'Missed Stones (Stone → Normal)'),
    ]

    for category_name, indices, title in categories:
        category_dir = output_path / category_name
        category_dir.mkdir(exist_ok=True)

        print(f"\nGenerating {title} visualizations...")

        for i, idx in enumerate(indices):
            save_path = category_dir / f'{category_name}_{i:02d}.png'
            gradcam.visualize(
                X_test[idx],
                original_images[idx],
                save_path=save_path
            )

    print(f"\n✅ Grad-CAM report saved to: {output_path}")
    print(f"   - True Positives: {len(tp_indices)} images")
    print(f"   - True Negatives: {len(tn_indices)} images")
    print(f"   - False Positives: {len(fp_indices)} images")
    print(f"   - False Negatives: {len(fn_indices)} images")


if __name__ == "__main__":
    print("RayScan Grad-CAM Explainability Module")
    print("="*50)
    print("\nUsage:")
    print("  gradcam = GradCAM(trained_model)")
    print("  heatmap, overlay = gradcam.visualize(preprocessed_img, original_img)")
    print("\nFor batch processing:")
    print("  batch_gradcam(model, images, originals, 'output_dir/')")
