import streamlit as st
import numpy as np
import cv2
from tensorflow.keras.models import load_model

# Load your trained CNN model
model = load_model("kidney_stone_cnn.h5")

# Prediction function
def predict(image):
    img = cv2.resize(image, (224, 224))
    img = img / 255.0
    img = np.expand_dims(img, axis=0)

    pred = model.predict(img)[0][0]
    if pred > 0.5:
        return "🪨 Kidney Stone Detected ✅", float(pred)
    else:
        return "🟢 Normal Kidney", float(1 - pred)

# Streamlit UI
st.set_page_config(page_title="RayScan - Kidney Stone Detection", layout="centered")
st.title("🩻 RayScan: Kidney Stone Detection from Ultrasound")
st.write("Upload an ultrasound image to detect the presence of kidney stones.")

uploaded_file = st.file_uploader("Choose an image", type=["jpg", "jpeg", "png"])

if uploaded_file is not None:
    # Read and display image
    file_bytes = np.asarray(bytearray(uploaded_file.read()), dtype=np.uint8)
    image = cv2.imdecode(file_bytes, 1)
    image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    st.image(image_rgb, caption="Uploaded Ultrasound Image", use_column_width=True)

    # Predict
    label, confidence = predict(image)
    st.markdown(f"### 🧠 Prediction: **{label}**")
    st.markdown(f"**Confidence:** `{confidence:.4f}`")
