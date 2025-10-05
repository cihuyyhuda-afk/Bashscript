#!/bin/bash

# Nama folder proyek utama
PROJECT_DIR="yolo_webrtc_app"
# Nama lingkungan virtual
VENV_NAME=".venv"

echo "--- Penyiapan Otomatis YOLO WebRTC Streamlit ---"

# 1. Membuat dan Pindah ke Direktori Proyek
if [ -d "$PROJECT_DIR" ]; then
    echo "Direktori $PROJECT_DIR sudah ada. Menghapus yang lama dan membuat ulang..."
    rm -rf "$PROJECT_DIR"
fi
mkdir "$PROJECT_DIR"
cd "$PROJECT_DIR"
echo "Berhasil membuat dan masuk ke direktori: $PROJECT_DIR"

# 2. Membuat Lingkungan Virtual Python
echo "Membuat lingkungan virtual Python..."
python3 -m venv "$VENV_NAME"

# Mengaktifkan lingkungan virtual
source "$VENV_NAME/bin/activate"
echo "Lingkungan virtual diaktifkan."

# 3. Menginstal Dependensi
echo "Menginstal dependensi (streamlit, streamlit-webrtc, ultralytics, opencv-python)..."
# Perintah 'pip' akan menginstal ke dalam lingkungan virtual
pip install numpy ultralytics streamlit streamlit-webrtc opencv-python tensorflow
if [ $? -ne 0 ]; then
    echo "ERROR: Gagal menginstal dependensi. Pastikan Python 3 dan pip sudah terinstal."
    deactivate
    exit 1
fi
echo "Instalasi selesai."

# 4. Membuat Kode Aplikasi Streamlit

# --- Kode Python: streamlit_app.py ---
echo "Membuat streamlit_app.py..."
cat > streamlit_app.py << EOF
import cv2
import streamlit as st
import numpy as np
import tensorflow as tf
from streamlit_webrtc import webrtc_streamer, WebRtcMode, RTCConfiguration
from tensorflow.keras.applications.mobilenet_v2 import MobileNetV2, preprocess_input
from tensorflow.keras.preprocessing import image
from tensorflow.keras.applications.mobilenet_v2 import decode_predictions

# Model Setup
model = MobileNetV2(weights="imagenet")

# Object detection function
def detect_objects(frame):
    # Convert image to RGB
    rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    img = image.array_to_img(rgb_frame)
    img = img.resize((224, 224))
    img_array = image.img_to_array(img)
    img_array = np.expand_dims(img_array, axis=0)
    img_array = preprocess_input(img_array)

    preds = model.predict(img_array)
    decoded_preds = decode_predictions(preds, top=3)[0]

    # Show top prediction
    label = decoded_preds[0][1]
    confidence = decoded_preds[0][2]

    # Draw the label on the frame
    font = cv2.FONT_HERSHEY_SIMPLEX
    frame = cv2.putText(frame, f"{label}: {confidence:.2f}", (10, 30), font, 1, (255, 0, 0), 2)

    return frame

# Streamlit Interface
st.title("Real-Time Object Detection with Streamlit WebRTC")

st.write(
    "This application performs real-time object detection using Streamlit and WebRTC."
)

# WebRTC configuration for streaming
rtc_configuration = RTCConfiguration({
    "iceServers": [{"urls": ["stun:stun.l.google.com:19302"]}]
})

# WebRTC streamer callback
def video_frame_callback(frame):
    # Convert frame to numpy array
    img = frame.to_ndarray(format="bgr24")
    
    # Detect objects
    img = detect_objects(img)

    # Convert back to stream format
    return img

# Start WebRTC stream
webrtc_streamer(
    key="object-detection",
    mode=WebRtcMode.SENDRECV,
    rtc_configuration=rtc_configuration,
    video_frame_callback=video_frame_callback,
    async_processing=True
)
EOF

# 5. Menjalankan Aplikasi
echo "Semua file telah dibuat. Menjalankan aplikasi Streamlit..."
echo "----------------------------------------------------------------------"
echo "Aplikasi akan tersedia di http://localhost:8501"
echo "Untuk diakses orang lain (di jaringan yang sama), gunakan alamat IP lokal Anda:"
echo "Misalnya: http://<IP_KOMPUTER_ANDA>:8501"
echo "----------------------------------------------------------------------"
echo "Tekan CTRL+C di terminal ini untuk menghentikan aplikasi."

# Menjalankan aplikasi Streamlit
streamlit run streamlit_app.py --server.address 0.0.0.0

# Setelah CTRL+C ditekan
echo "Aplikasi berjalan."
sleep 6666666666666

# 6. Deaktivasi Lingkungan Virtual
deactivate
echo "Lingkungan virtual dideaktivasi."
echo "Selesai."
