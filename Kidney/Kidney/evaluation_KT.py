import os
import numpy as np
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from sklearn.metrics import classification_report, confusion_matrix

# Paths
model_path = "kidney_stone_cnn.h5"
data_dir = "dataset"
IMG_SIZE = (224, 224)
BATCH_SIZE = 32

# Load model
model = load_model(model_path)

# Reload validation set
datagen = ImageDataGenerator(rescale=1./255, validation_split=0.2)

val_gen = datagen.flow_from_directory(
    data_dir,
    target_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    class_mode='binary',
    subset='validation',
    shuffle=False
)

# Predict
y_true = val_gen.classes
y_pred = (model.predict(val_gen) > 0.5).astype("int32")

# Evaluation
print("\nClassification Report:")
print(classification_report(y_true, y_pred, target_names=val_gen.class_indices))

print("Confusion Matrix:")
print(confusion_matrix(y_true, y_pred))
