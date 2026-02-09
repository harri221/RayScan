"""
Convert old Keras model to new TensorFlow 2.x format
Run this if ml_service.py fails to load the model
"""

import tensorflow as tf
from tensorflow import keras
import os

print("=" * 60)
print("  Keras Model Converter for TensorFlow 2.x")
print("=" * 60)
print()

# Paths
OLD_MODEL_PATH = os.path.join(os.path.dirname(__file__), 'Kidney', 'kidney_stone_cnn.h5')
NEW_MODEL_PATH = os.path.join(os.path.dirname(__file__), 'Kidney', 'kidney_stone_cnn_v2.h5')

print(f"📂 Loading model from: {OLD_MODEL_PATH}")

try:
    # Try loading with compile=False
    print("⏳ Attempting to load model...")
    model = tf.keras.models.load_model(OLD_MODEL_PATH, compile=False)
    print("✅ Model loaded successfully!")

    # Print model info
    print("\n📊 Model Information:")
    print(f"   Input shape: {model.input_shape}")
    print(f"   Output shape: {model.output_shape}")
    print(f"   Total layers: {len(model.layers)}")

    # Recompile model
    print("\n⚙️  Recompiling model...")
    model.compile(
        optimizer='adam',
        loss='binary_crossentropy',
        metrics=['accuracy']
    )

    # Save in new format
    print(f"\n💾 Saving model to: {NEW_MODEL_PATH}")
    model.save(NEW_MODEL_PATH)
    print("✅ Model saved successfully!")

    print("\n" + "=" * 60)
    print("  ✅ Conversion Complete!")
    print("=" * 60)
    print(f"\n📝 Update ml_service.py line 28:")
    print(f"   MODEL_PATH = 'Kidney/kidney_stone_cnn_v2.h5'")
    print("\nOr just rename the new file to replace the old one.")

except Exception as e:
    print(f"\n❌ Error: {e}")
    print("\n💡 Alternative Solution:")
    print("   The model file might be corrupted or incompatible.")
    print("   You may need to retrain the model or use a pre-trained one.")
    print()

    # Try to create a simple model as backup
    print("🔧 Creating a simple backup model for testing...")
    try:
        from tensorflow.keras.models import Sequential
        from tensorflow.keras.layers import Conv2D, MaxPooling2D, Flatten, Dense, Dropout

        model = Sequential([
            Conv2D(32, (3, 3), activation='relu', input_shape=(224, 224, 3)),
            MaxPooling2D((2, 2)),
            Conv2D(64, (3, 3), activation='relu'),
            MaxPooling2D((2, 2)),
            Conv2D(64, (3, 3), activation='relu'),
            Flatten(),
            Dense(64, activation='relu'),
            Dropout(0.5),
            Dense(1, activation='sigmoid')
        ])

        model.compile(
            optimizer='adam',
            loss='binary_crossentropy',
            metrics=['accuracy']
        )

        backup_path = os.path.join(os.path.dirname(__file__), 'Kidney', 'kidney_stone_backup.h5')
        model.save(backup_path)
        print(f"✅ Backup model created: {backup_path}")
        print("\n⚠️  Note: This is an untrained model for testing only!")
        print("   Predictions will be random until you use the actual trained model.")

    except Exception as e2:
        print(f"❌ Could not create backup model: {e2}")

print()
