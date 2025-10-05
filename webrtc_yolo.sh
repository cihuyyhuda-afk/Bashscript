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
pip install streamlit ultralytics opencv-python Pillow
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
import cv2
from ultralytics import YOLO
import numpy as np
from PIL import Image

# 1. Muat Model YOLO
# Menggunakan YOLOv8n (nano) karena cepat dan cocok untuk real-time
@st.cache_resource
def load_yolo_model():
    # Ganti 'yolov8n.pt' dengan model lain jika perlu (misal 'yolov8m.pt')
    model = YOLO('yolov8n.pt') 
    return model

model = load_yolo_model()
# --- Tampilan Streamlit ---
st.title("Real-time Object Detector (YOLOv8 + Streamlit)")
st.caption("Deteksi objek menggunakan live webcam")

# Tempat untuk menampilkan video stream yang dianotasi
frame_placeholder = st.empty()

# Tombol untuk memulai dan menghentikan deteksi
col1, col2 = st.columns(2)
with col1:
    start_button = st.button("Mulai Deteksi", type="primary")
with col2:
    stop_button = st.button("Hentikan Deteksi")

# --- Konfigurasi Deteksi (Opsional) ---
st.sidebar.header("Pengaturan Deteksi")
confidence = st.sidebar.slider("Confidence Threshold", 0.0, 1.0, 0.25)

# --- Logika Deteksi Real-time ---
if 'running' not in st.session_state:
    st.session_state.running = False

if start_button:
    st.session_state.running = True

if stop_button:
    st.session_state.running = False

cap = None

if st.session_state.running:
    try:
        # Menggunakan webcam (0 adalah ID webcam default)
        cap = cv2.VideoCapture(0) 

        if not cap.isOpened():
            st.error("Gagal mengakses webcam. Pastikan tidak ada aplikasi lain yang menggunakan webcam.")
            st.session_state.running = False

        while st.session_state.running and cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                st.warning("Gagal membaca frame dari webcam.")
                break

            # Konversi BGR (OpenCV) ke RGB (YOLO/Streamlit)
            # frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            
            # 2. Lakukan Deteksi dengan YOLOv8
            # Pengaturan: conf= confidence threshold, stream=True untuk performa video
            results = model(frame, conf=confidence, stream=True)  

            # 3. Anotasi Frame
            for r in results:
                # Plot bounding box dan label ke frame (fungsi bawaan YOLOv8)
                annotated_frame = r.plot()
                
                # Konversi hasil plot (numpy array BGR) ke RGB untuk Streamlit
                annotated_frame_rgb = cv2.cvtColor(annotated_frame, cv2.COLOR_BGR2RGB)
                
                # 4. Tampilkan Frame yang Dianotasi
                frame_placeholder.image(
                    annotated_frame_rgb, 
                    channels="RGB", 
                    caption="Deteksi Real-time", 
                    use_column_width=True
                )
                
            # Kontrol kecepatan loop (misalnya 1 ms delay)
            if cv2.waitKey(1) & 0xFF == ord('q'):
                st.session_state.running = False
                break
                
    except Exception as e:
        st.error(f"Terjadi error: {e}")
        st.session_state.running = False

    finally:
        # Pastikan webcam dilepaskan ketika loop berakhir
        if cap is not None and cap.isOpened():
            cap.release()
            
        if st.session_state.running == False:
            frame_placeholder.empty() # Kosongkan placeholder setelah berhenti
            st.warning("Deteksi Dihentikan.")
            

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
