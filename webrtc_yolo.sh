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
pip install av streamlit ultralytics opencv-python Pillow streamlit-webrtc
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
import streamlit as st
import numpy as np
import av
from streamlit_webrtc import webrtc_streamer, VideoTransformerBase
from ultralytics import YOLO

# 1. Muat Model YOLO (dengan caching)
@st.cache_resource
def load_yolo_model():
    # Menggunakan YOLOv8n (nano)
    model = YOLO('yolov8n.pt') 
    return model

model = load_yolo_model()
CONFIDENCE_THRESHOLD = 0.25 

# 2. Definisi Video Transformer untuk Deteksi Objek
# Kelas ini akan memproses setiap frame yang datang dari webcam client
class YOLOVideoTransformer(VideoTransformerBase):
    def transform(self, frame: av.VideoFrame) -> np.ndarray:
        # Konversi frame AV ke numpy array (format BGR)
        img = frame.to_ndarray(format="bgr24") 

        # Lakukan Inferensi YOLOv8
        # Kami menggunakan img (BGR) karena Ultralytics dapat menangani BGR/RGB
        results = model(img, conf=CONFIDENCE_THRESHOLD, verbose=False) 

        # Ambil frame yang sudah dianotasi (sudah BGR)
        annotated_frame = results[0].plot()

        # Kembalikan frame (harus dalam format BGR/RGB yang didukung)
        return annotated_frame

# --- Tampilan Streamlit ---
st.title("Real-time Object Detector (WebRTC + YOLOv8)")
st.caption("Meminta izin kamera pengguna untuk deteksi real-time")

# 3. Widget webrtc_streamer
# Memanggil widget ini akan memunculkan permintaan izin kamera di browser user.
ctx = webrtc_streamer(
    key="yolo-detection-stream",
    video_processor_factory=YOLOVideoTransformer,
    rtc_configuration={
        "iceServers": [{"urls": ["stun:stun.l.google.com:19302"]}]
    },
    media_stream_constraints={"video": True, "audio": False},
)

if ctx.state.playing:
    st.success("Webcam aktif! Deteksi dimulai...")
else:
    st.warning("Menunggu izin kamera...")

# Anda bisa menambahkan slider di sini untuk mengubah CONFIDENCE_THRESHOLD
# (membutuhkan sedikit logika tambahan untuk mengupdate nilai di dalam kelas)

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
