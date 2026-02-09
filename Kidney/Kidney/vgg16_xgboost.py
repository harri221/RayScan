import os
import cv2
import numpy as np
from tqdm import tqdm
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, confusion_matrix
from xgboost import XGBClassifier
from tensorflow.keras.applications.vgg16 import VGG16, preprocess_input

# Paths
base_dir = "C:/Users/DELL/Kidney/Dataset"
IMG_SIZE = 224

# Labels
categories = ["normal", "stone"]

# Load and preprocess images
def load_images():
    X, y = [], []
    for label, category in enumerate(categories):
        folder = os.path.join(base_dir, category)
        for filename in tqdm(os.listdir(folder), desc=f"Loading {category}"):
            img_path = os.path.join(folder, filename)
            try:
                img = cv2.imread(img_path)
                img = cv2.resize(img, (IMG_SIZE, IMG_SIZE))
                img = preprocess_input(img)  # for VGG16
                X.append(img)
                y.append(label)
            except:
                pass  # skip unreadable files
    return np.array(X), np.array(y)

print("📦 Loading and preprocessing images...")
X, y = load_images()

# Load VGG16 without top layers
print("🧠 Extracting features using VGG16...")
vgg = VGG16(weights='imagenet', include_top=False, input_shape=(224, 224, 3))
features = vgg.predict(X, verbose=1)
features = features.reshape(features.shape[0], -1)  # Flatten

# Train/Test Split
X_train, X_test, y_train, y_test = train_test_split(features, y, test_size=0.2, random_state=42, stratify=y)

# Train XGBoost
print("🚀 Training XGBoost...")
clf = XGBClassifier(use_label_encoder=False, eval_metric='logloss')
clf.fit(X_train, y_train)

# Predict
y_pred = clf.predict(X_test)

# Evaluation
print("\n📊 Classification Report:")
print(classification_report(y_test, y_pred, target_names=categories))

print("📉 Confusion Matrix:")
print(confusion_matrix(y_test, y_pred))
