#!/bin/bash

# Nama folder proyek utama
PROJECT_DIR="webrtc_app"
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
pip install streamlit opencv-python opencv-python-headless tensorflow
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
import numpy as np
import streamlit as st
import tensorflow as tf

# Load pre-trained model
net = cv2.dnn.readNetFromTensorflow('ssd_mobilenet_v2_coco.pb')

# Function to perform object detection
def detect_objects(frame):
    height, width, _ = frame.shape
    blob = cv2.dnn.blobFromImage(frame, 1.0, (300, 300), (127.5, 127.5, 127.5), True, crop=False)
    net.setInput(blob)
    detections = net.forward()

    for i in range(detections.shape[2]):
        confidence = detections[0, 0, i, 2]
        if confidence > 0.5:
            box = detections[0, 0, i, 3:7] * np.array([width, height, width, height])
            (x1, y1, x2, y2) = box.astype("int")
            label = int(detections[0, 0, i, 1])
            cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
            cv2.putText(frame, f"Object {label}", (x1, y1-10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)
    return frame

# Streamlit app
st.title("Real-Time Object Detection with Streamlit")

# Start video capture
cap = cv2.VideoCapture(0)

if not cap.isOpened():
    st.error("Error: Could not open webcam.")
else:
    stframe = st.empty()
    while True:
        ret, frame = cap.read()
        if not ret:
            break

        # Perform object detection
        frame = detect_objects(frame)

        # Convert BGR to RGB for Streamlit display
        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

        # Display the frame
        stframe.image(frame_rgb, channels="RGB", use_column_width=True)

    cap.release()
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
streamlit run streamlit_app.py

# Setelah CTRL+C ditekan
echo "Aplikasi berjalan."
sleep 6666666666666

# 6. Deaktivasi Lingkungan Virtual
deactivate
echo "Lingkungan virtual dideaktivasi."
echo "Selesai."
