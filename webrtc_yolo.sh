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
pip install streamlit streamlit-webrtc ultralytics opencv-python numpy av
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
import streamlit as st
from streamlit_webrtc import webrtc_stream, WebRtcMode
import cv2
from ultralytics import YOLO
import numpy as np
import av

# Konfigurasi halaman Streamlit
st.set_page_config(page_title="YOLO WebRTC Detector", layout="wide")

# Memuat Model YOLOv8 (nano)
@st.cache_resource
def load_yolo_model():
    # Model akan didownload otomatis jika belum ada
    return YOLO('yolov8n.pt') 

model = load_yolo_model()

# Fungsi callback yang dipanggil untuk setiap frame dari kamera pengguna
def video_frame_callback(frame: av.VideoFrame) -> av.VideoFrame:
    # Konversi frame WebRTC (AV) ke array numpy (OpenCV format BGR)
    img = frame.to_ndarray(format="bgr") 
    
    # --- Deteksi Objek dengan YOLO ---
    # Jalankan inferensi. stream=False dan verbose=False untuk efisiensi
    results = model(img, stream=False, verbose=False)
    
    # Mendapatkan frame dengan bounding box yang sudah digambar oleh YOLO
    annotated_frame = results[0].plot()
    
    # Mengembalikan frame yang sudah di-annotate
    return av.VideoFrame.from_ndarray(annotated_frame, format="bgr")

st.title("Object Detection Real-Time (YOLOv8 via WebRTC) 🚀")
st.markdown("Aplikasi ini menggunakan kamera Anda melalui **WebRTC** untuk menjalankan deteksi objek **YOLOv8** di server.")

# Konfigurasi WebRTC
webrtc_ctx = webrtc_stream(
    key="yolo-detection",
    mode=WebRtcMode.SENDRECV, # Mengirim video (dari klien) dan menerima (hasil)
    video_frame_callback=video_frame_callback,
    media_stream_constraints={"video": True, "audio": False}, # Hanya aktifkan video
    async_processing=True,
)

# Status tampilan
if webrtc_ctx.video_receiver:
    st.info("Deteksi Aktif! Kamera Anda digunakan. Beri izin kamera di browser.")
else:
    st.warning("Menunggu izin kamera dari browser Anda. Harap berikan izin.")

st.markdown("""
<style>
    /* Styling untuk tombol "Start" WebRTC */
    .stButton>button {
        background-color: #4CAF50;
        color: white;
        font-size: 16px;
        padding: 10px 24px;
        border-radius: 8px;
    }
</style>
""", unsafe_allow_html=True)
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
echo "Aplikasi dihentikan."

# 6. Deaktivasi Lingkungan Virtual
deactivate
echo "Lingkungan virtual dideaktivasi."
echo "Selesai."
