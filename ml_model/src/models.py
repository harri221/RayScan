"""
RayScan ML Model - Model Architectures
Based on Paper 1 (IJECE 2023): CNN + VGG16 feature extraction with XGBoost classifier
"""

import numpy as np
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers, Model, Sequential
from tensorflow.keras.applications import VGG16
from tensorflow.keras.callbacks import EarlyStopping, ModelCheckpoint, ReduceLROnPlateau
import xgboost as xgb
from sklearn.ensemble import RandomForestClassifier
import joblib


class CustomCNN:
    """
    Custom CNN for feature extraction from kidney ultrasound images.
    Architecture based on Paper 1 methodology.
    """

    def __init__(self, input_shape=(224, 224, 1), num_features=256):
        """
        Initialize Custom CNN feature extractor.

        Args:
            input_shape: Input image shape (height, width, channels)
            num_features: Number of features in the output layer
        """
        self.input_shape = input_shape
        self.num_features = num_features
        self.model = self._build_model()

    def _build_model(self):
        """Build the CNN feature extractor architecture."""
        model = Sequential([
            # Block 1
            layers.Conv2D(32, (3, 3), activation='relu', padding='same',
                         input_shape=self.input_shape),
            layers.BatchNormalization(),
            layers.Conv2D(32, (3, 3), activation='relu', padding='same'),
            layers.BatchNormalization(),
            layers.MaxPooling2D((2, 2)),
            layers.Dropout(0.25),

            # Block 2
            layers.Conv2D(64, (3, 3), activation='relu', padding='same'),
            layers.BatchNormalization(),
            layers.Conv2D(64, (3, 3), activation='relu', padding='same'),
            layers.BatchNormalization(),
            layers.MaxPooling2D((2, 2)),
            layers.Dropout(0.25),

            # Block 3
            layers.Conv2D(128, (3, 3), activation='relu', padding='same'),
            layers.BatchNormalization(),
            layers.Conv2D(128, (3, 3), activation='relu', padding='same'),
            layers.BatchNormalization(),
            layers.MaxPooling2D((2, 2)),
            layers.Dropout(0.25),

            # Block 4
            layers.Conv2D(256, (3, 3), activation='relu', padding='same'),
            layers.BatchNormalization(),
            layers.MaxPooling2D((2, 2)),
            layers.Dropout(0.25),

            # Feature extraction output
            layers.Flatten(),
            layers.Dense(512, activation='relu'),
            layers.Dropout(0.5),
            layers.Dense(self.num_features, activation='relu', name='features'),
        ])

        return model

    def extract_features(self, images):
        """
        Extract features from images.

        Args:
            images: Numpy array of preprocessed images

        Returns:
            Feature vectors
        """
        return self.model.predict(images, verbose=0)

    def summary(self):
        """Print model summary."""
        return self.model.summary()


class VGG16FeatureExtractor:
    """
    VGG16 Transfer Learning feature extractor.
    Based on Paper 1 methodology for high accuracy.
    """

    def __init__(self, input_shape=(224, 224, 3), num_features=512):
        """
        Initialize VGG16 feature extractor.

        Args:
            input_shape: Input image shape (must be 3 channels for VGG16)
            num_features: Number of features in the output layer
        """
        self.input_shape = input_shape
        self.num_features = num_features
        self.model = self._build_model()

    def _build_model(self):
        """Build VGG16-based feature extractor."""
        # Load pre-trained VGG16 (without top layers)
        base_model = VGG16(
            weights='imagenet',
            include_top=False,
            input_shape=self.input_shape
        )

        # Freeze base model layers
        base_model.trainable = False

        # Add custom layers for feature extraction
        model = Sequential([
            base_model,
            layers.GlobalAveragePooling2D(),
            layers.Dense(1024, activation='relu'),
            layers.Dropout(0.5),
            layers.Dense(self.num_features, activation='relu', name='features'),
        ])

        return model

    def extract_features(self, images):
        """
        Extract features from images.

        Args:
            images: Numpy array of preprocessed images (3 channels)

        Returns:
            Feature vectors
        """
        return self.model.predict(images, verbose=0)

    def fine_tune(self, unfreeze_layers=4):
        """
        Unfreeze top layers of VGG16 for fine-tuning.

        Args:
            unfreeze_layers: Number of layers to unfreeze from the top
        """
        base_model = self.model.layers[0]
        base_model.trainable = True

        # Freeze all except last n layers
        for layer in base_model.layers[:-unfreeze_layers]:
            layer.trainable = False

        print(f"Fine-tuning enabled: {unfreeze_layers} layers unfrozen")

    def summary(self):
        """Print model summary."""
        return self.model.summary()


class EndToEndCNN:
    """
    End-to-end CNN classifier (for comparison with hybrid approach).
    """

    def __init__(self, input_shape=(224, 224, 1)):
        """
        Initialize end-to-end CNN classifier.

        Args:
            input_shape: Input image shape
        """
        self.input_shape = input_shape
        self.model = self._build_model()

    def _build_model(self):
        """Build end-to-end CNN classifier."""
        model = Sequential([
            # Block 1
            layers.Conv2D(32, (3, 3), activation='relu', padding='same',
                         input_shape=self.input_shape),
            layers.BatchNormalization(),
            layers.Conv2D(32, (3, 3), activation='relu', padding='same'),
            layers.BatchNormalization(),
            layers.MaxPooling2D((2, 2)),
            layers.Dropout(0.25),

            # Block 2
            layers.Conv2D(64, (3, 3), activation='relu', padding='same'),
            layers.BatchNormalization(),
            layers.Conv2D(64, (3, 3), activation='relu', padding='same'),
            layers.BatchNormalization(),
            layers.MaxPooling2D((2, 2)),
            layers.Dropout(0.25),

            # Block 3
            layers.Conv2D(128, (3, 3), activation='relu', padding='same'),
            layers.BatchNormalization(),
            layers.Conv2D(128, (3, 3), activation='relu', padding='same'),
            layers.BatchNormalization(),
            layers.MaxPooling2D((2, 2)),
            layers.Dropout(0.25),

            # Block 4
            layers.Conv2D(256, (3, 3), activation='relu', padding='same'),
            layers.BatchNormalization(),
            layers.MaxPooling2D((2, 2)),
            layers.Dropout(0.25),

            # Classification head
            layers.Flatten(),
            layers.Dense(512, activation='relu'),
            layers.Dropout(0.5),
            layers.Dense(128, activation='relu'),
            layers.Dropout(0.5),
            layers.Dense(1, activation='sigmoid'),  # Binary classification
        ])

        model.compile(
            optimizer=keras.optimizers.Adam(learning_rate=0.001),
            loss='binary_crossentropy',
            metrics=['accuracy', keras.metrics.Precision(), keras.metrics.Recall()]
        )

        return model

    def train(self, X_train, y_train, X_val, y_val, epochs=50, batch_size=32):
        """
        Train the end-to-end CNN.

        Args:
            X_train, y_train: Training data
            X_val, y_val: Validation data
            epochs: Number of epochs
            batch_size: Batch size

        Returns:
            Training history
        """
        callbacks = [
            EarlyStopping(
                monitor='val_loss',
                patience=10,
                restore_best_weights=True
            ),
            ReduceLROnPlateau(
                monitor='val_loss',
                factor=0.5,
                patience=5,
                min_lr=1e-7
            ),
            ModelCheckpoint(
                '../models/end_to_end_cnn_best.keras',
                monitor='val_accuracy',
                save_best_only=True
            )
        ]

        history = self.model.fit(
            X_train, y_train,
            validation_data=(X_val, y_val),
            epochs=epochs,
            batch_size=batch_size,
            callbacks=callbacks
        )

        return history

    def predict(self, images):
        """Make predictions."""
        return self.model.predict(images)

    def summary(self):
        """Print model summary."""
        return self.model.summary()


class HybridClassifier:
    """
    Hybrid CNN + XGBoost/RandomForest classifier.
    Based on Paper 1 achieving 99.47% accuracy.
    """

    def __init__(self, feature_extractor='cnn', classifier='xgboost'):
        """
        Initialize hybrid classifier.

        Args:
            feature_extractor: 'cnn' or 'vgg16'
            classifier: 'xgboost' or 'random_forest'
        """
        self.feature_extractor_type = feature_extractor
        self.classifier_type = classifier

        # Initialize feature extractor
        if feature_extractor == 'cnn':
            self.feature_extractor = CustomCNN()
        else:
            self.feature_extractor = VGG16FeatureExtractor()

        # Initialize classifier
        if classifier == 'xgboost':
            self.classifier = xgb.XGBClassifier(
                n_estimators=200,
                max_depth=6,
                learning_rate=0.1,
                objective='binary:logistic',
                eval_metric='logloss',
                use_label_encoder=False,
                random_state=42
            )
        else:
            self.classifier = RandomForestClassifier(
                n_estimators=200,
                max_depth=10,
                random_state=42,
                n_jobs=-1
            )

    def train(self, X_train, y_train, X_val=None, y_val=None):
        """
        Train the hybrid classifier.

        Args:
            X_train, y_train: Training data
            X_val, y_val: Validation data (optional)

        Returns:
            Training metrics
        """
        print(f"Extracting features using {self.feature_extractor_type.upper()}...")
        train_features = self.feature_extractor.extract_features(X_train)

        print(f"Training {self.classifier_type.upper()} classifier...")
        if X_val is not None and self.classifier_type == 'xgboost':
            val_features = self.feature_extractor.extract_features(X_val)
            self.classifier.fit(
                train_features, y_train,
                eval_set=[(val_features, y_val)],
                verbose=True
            )
        else:
            self.classifier.fit(train_features, y_train)

        # Training accuracy
        train_pred = self.classifier.predict(train_features)
        train_acc = np.mean(train_pred == y_train)

        return {'train_accuracy': train_acc}

    def predict(self, images):
        """
        Make predictions on new images.

        Args:
            images: Preprocessed images

        Returns:
            Predictions (0 or 1)
        """
        features = self.feature_extractor.extract_features(images)
        return self.classifier.predict(features)

    def predict_proba(self, images):
        """
        Get prediction probabilities.

        Args:
            images: Preprocessed images

        Returns:
            Prediction probabilities
        """
        features = self.feature_extractor.extract_features(images)
        return self.classifier.predict_proba(features)

    def save(self, path):
        """
        Save the trained model.

        Args:
            path: Directory to save model files
        """
        import os
        os.makedirs(path, exist_ok=True)

        # Save feature extractor
        self.feature_extractor.model.save(
            os.path.join(path, f'{self.feature_extractor_type}_feature_extractor.keras')
        )

        # Save classifier
        joblib.dump(
            self.classifier,
            os.path.join(path, f'{self.classifier_type}_classifier.pkl')
        )

        print(f"Model saved to: {path}")

    def load(self, path):
        """
        Load a trained model.

        Args:
            path: Directory containing model files
        """
        import os

        # Load feature extractor
        self.feature_extractor.model = keras.models.load_model(
            os.path.join(path, f'{self.feature_extractor_type}_feature_extractor.keras')
        )

        # Load classifier
        self.classifier = joblib.load(
            os.path.join(path, f'{self.classifier_type}_classifier.pkl')
        )

        print(f"Model loaded from: {path}")


def create_tflite_model(keras_model, output_path, quantize=True):
    """
    Convert Keras model to TFLite for mobile deployment.

    Args:
        keras_model: Trained Keras model
        output_path: Path to save .tflite file
        quantize: Whether to apply INT8 quantization

    Returns:
        Size of the TFLite model in MB
    """
    converter = tf.lite.TFLiteConverter.from_keras_model(keras_model)

    if quantize:
        converter.optimizations = [tf.lite.Optimize.DEFAULT]

    tflite_model = converter.convert()

    with open(output_path, 'wb') as f:
        f.write(tflite_model)

    size_mb = len(tflite_model) / (1024 * 1024)
    print(f"TFLite model saved: {output_path} ({size_mb:.2f} MB)")

    return size_mb


if __name__ == "__main__":
    print("RayScan ML Model Architectures")
    print("=" * 50)

    # Test Custom CNN
    print("\n1. Custom CNN Feature Extractor:")
    cnn = CustomCNN()
    cnn.summary()

    # Test VGG16
    print("\n2. VGG16 Feature Extractor:")
    vgg = VGG16FeatureExtractor()
    vgg.summary()

    # Test End-to-End CNN
    print("\n3. End-to-End CNN Classifier:")
    e2e = EndToEndCNN()
    e2e.summary()

    print("\n4. Hybrid Classifier (CNN + XGBoost):")
    print("   - Combines CNN feature extraction with XGBoost classification")
    print("   - Expected accuracy: >99% based on Paper 1")
