<div align="center">

# 📱 Absensi Sekolah QR-Code (SMPN 204)

### 🇮🇩 Sistem Presensi & Manajemen Absensi Siswa & Guru Berbasis QR-Code & Face Recognition
### 🇬🇧 QR-Code & Face Recognition-Based School Attendance & Management System

<br/>

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Cloud Firestore](https://img.shields.io/badge/Cloud%20Firestore-Database-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![ML Kit](https://img.shields.io/badge/ML%20Kit-Face%20Detection-4285F4?style=for-the-badge&logo=google&logoColor=white)
![Mobile Scanner](https://img.shields.io/badge/QR%20Code-Scanner%20%26%20Generator-009688?style=for-the-badge&logo=qr-code&logoColor=white)
![Excel Export](https://img.shields.io/badge/Excel-Export%20Report-217346?style=for-the-badge&logo=microsoftexcel&logoColor=white)

</div>

---

## 🇮🇩 Deskripsi Proyek

**Absensi Sekolah QR-Code (SMPN 204)** adalah aplikasi presensi digital multi-peran berbasis Flutter yang dirancang untuk modernisasi sistem pencatatan kehadiran siswa dan guru di sekolah. 

Aplikasi ini mengintegrasikan **pemindaian QR-Code dinamis (Mobile Scanner & QR Flutter)**, verifikasi wajah pintar (**Google ML Kit Face Detection**), pembatasan koordinat lokasi (**Geolocator GPS**), serta penyimpanan cloud real-time menggunakan **Cloud Firestore**. Selain itu, sistem menyediakan fitur rekapitulasi kehadiran instan yang dapat langsung diekspor ke format **Microsoft Excel (`.xlsx`)** dan dibagikan.

---

## 🇬🇧 Project Description

**Absensi Sekolah QR-Code (SMPN 204)** is a multi-role digital attendance Flutter mobile application designed to modernize student and teacher attendance tracking in schools.

The app integrates **dynamic QR-Code scanning (Mobile Scanner & QR Flutter)**, smart facial verification (**Google ML Kit Face Detection**), geofencing location validation (**Geolocator GPS**), and real-time cloud data management via **Cloud Firestore**. Additionally, it provides automated attendance reports that can be directly exported into **Microsoft Excel (`.xlsx`)** and shared.

---

## ✨ Fitur Utama & Struktur Aplikasi (Core Features & App Structure)

---

### 🇮🇩 Bahasa Indonesia

**A. Multi-Role Authentication & Keamanan Akses**

- 👥 **3 Peran Pengguna (Multi-Role):** Mendukung login khusus untuk **Siswa**, **Guru**, dan **Super Admin**.
- 🔐 **Autentikasi Aman:** Validasi kredensial (NIS/NIP & Password) langsung dengan enkripsi database Firestore.
- ⚡ **Auto-Login / Session Persistence:** Pengguna tidak perlu login berulang kali; sesi tersimpan aman di penyimpanan lokal menggunakan SharedPreferences.
- 🏢 **Validasi Kode Kelas:** Siswa divalidasi berdasarkan kecocokan ID dan kode kelas aktif mereka.

**B. Sistem Presensi QR-Code & Smart Camera**

- 📡 **QR-Code Generator Interaktif:** Guru dapat men-generate QR-Code sesi presensi pelajaran secara instan.
- 📷 **Pemindai QR Cepat:** Siswa memindai QR-Code guru menggunakan kamera perangkat via `mobile_scanner`.
- 🤖 **Smart Camera & Face Detection:** Verifikasi wajah otomatis menggunakan Google ML Kit untuk mencegah kecurangan titip absen.
- 📍 **Validasi Geolocation (GPS):** Pengecekan radius lokasi siswa saat melakukan absensi untuk memastikan presensi dilakukan di area sekolah.
- 🛡️ **Pencegahan Duplikasi:** Sistem menolak absensi ganda pada sesi atau hari yang sama untuk siswa yang sama.

**C. Rekapitulasi & Export Data ke Excel**

- 📊 **Rekap Real-time:** Guru dan Admin dapat memantau status kehadiran (Hadir, Izin, Sakit, Alpa) secara langsung.
- 📑 **Export ke Excel (.xlsx):** Sekali klik untuk mengunduh rekap presensi kelas lengkap dengan tanggal, jam, status, dan keterangan.
- 📤 **Fitur Berbagi (Share Plus):** File rekap absensi Excel dapat langsung dibagikan melalui WhatsApp, Email, atau Cloud Drive.
- 📸 **Tangkapan Layar Bukti:** Mendukung penyimpanan screenshot bukti absensi untuk arsip siswa/guru.

**D. Manajemen Profil & Personalisasi**

- 👤 **Profil Lengkap:** Menampilkan informasi NIS/NIP, nama lengkap, kelas, jenis kelamin, tanggal lahir, dan agama.
- 🖼️ **Foto Profil Terkompresi:** Pengguna dapat memperbarui foto profil yang otomatis dikompresi (Base64) tanpa memberatkan database.
- 🔑 **Ubah Kata Sandi:** Setiap pengguna dapat mengganti kata sandi akun mereka sendiri secara mandiri.

**E. Super Admin Control Panel**

- ➕ **Pendaftaran Akun Baru:** Admin dapat mendaftarkan siswa atau guru baru dengan data lengkap.
- 🧹 **Auto-Cleanup Riwayat Lama:** Membersihkan data riwayat usang saat pendaftaran ulang ID pengguna.
- 📋 **Manajemen Data Induk:** Pemeliharaan akun pengguna dan kontrol hak akses terpusat.

**F. Tampilan & Pengalaman Pengguna (UI/UX)**

- 🎨 **Desain Elegan & Bersih:** Tampilan antarmuka profesional bertema biru cerah yang ramah pengguna.
- 🚀 **Splash Screen Animasi:** Layar pembuka logo sekolah dengan pengecekan status sesi otomatis.
- 📱 **Responsif di Berbagai Layar:** Layout adaptif untuk berbagai ukuran layar smartphone Android dan iOS.

---

### 🇬🇧 English

**A. Multi-Role Authentication & Access Security**

- 👥 **3 User Roles (Multi-Role):** Dedicated login interfaces for **Students**, **Teachers**, and **Super Admin**.
- 🔐 **Secure Authentication:** Validates credentials (NIS/NIP & Password) directly against Cloud Firestore.
- ⚡ **Auto-Login / Session Persistence:** Users don't need to log in repeatedly; sessions are saved locally using SharedPreferences.
- 🏢 **Class Code Verification:** Validates students based on matching student IDs and active class codes.

**B. QR-Code & Smart Camera Attendance System**

- 📡 **Interactive QR-Code Generator:** Teachers can generate attendance session QR codes instantly.
- 📷 **High-Speed QR Scanner:** Students scan the teacher's QR code using their device camera via `mobile_scanner`.
- 🤖 **Smart Camera & Face Detection:** Automated facial verification using Google ML Kit to prevent attendance fraud.
- 📍 **Geolocation (GPS) Validation:** Verifies student radius coordinates to ensure attendance is submitted inside the school area.
- 🛡️ **Duplicate Prevention:** Rejects duplicate submissions for the same student on the same session/date.

**C. Attendance Recapitulation & Excel Export**

- 📊 **Real-time Recaps:** Teachers and Admins can monitor attendance statuses (Present, Excused, Sick, Absent) in real time.
- 📑 **Excel Export (.xlsx):** One-click download of attendance spreadsheets formatted with dates, timestamps, statuses, and notes.
- 📤 **Direct Sharing (Share Plus):** Instantly share generated Excel reports via WhatsApp, Email, or cloud storage.
- 📸 **Screenshot Proof Capture:** Enables capturing screenshots of attendance confirmations for user archives.

**D. Profile Management & Personalization**

- 👤 **Complete Profile View:** Displays user ID, full name, class code, gender, date of birth, and religion.
- 🖼️ **Compressed Profile Pictures:** Users can upload profile photos that are automatically compressed to Base64 to save bandwidth.
- 🔑 **Password Modification:** Users can independently change their account passwords at any time.

**E. Super Admin Control Panel**

- ➕ **User Registration:** Admin can register new teachers and students with complete identity details.
- 🧹 **Old History Cleanup:** Cleans outdated attendance records when re-registering recycled student IDs.
- 📋 **Master Data Management:** Centralized maintenance of user accounts and permissions.

**F. UI/UX**

- 🎨 **Clean & Professional Theme:** Harmonious blue-themed interface designed for simplicity and ease of use.
- 🚀 **Animated Splash Screen:** School logo opening screen with automatic background session checks.
- 📱 **Responsive Layout:** Adaptive layouts tested across diverse Android and iOS screen sizes.

---

## 🧰 Tech Stack

- **Framework:** Flutter 3.x / Dart 3.x
- **Backend & Database:** Cloud Firestore, Firebase Core, Firebase Auth
- **QR Code Engine:** `mobile_scanner`, `qr_flutter`
- **Vision & AI:** `google_mlkit_face_detection`, `camera`
- **Location & Sensors:** `geolocator`
- **Reporting & Documents:** `excel`, `path_provider`, `share_plus`, `screenshot`
- **Local Storage / Session:** `shared_preferences`
- **Media & Processing:** `image_picker`, `flutter_image_compress`
- **Utilities:** `intl`, `permission_handler`

---

## ⚙️ Setup Firebase & Konfigurasi (Wajib / Required)

File konfigurasi kredensial **tidak disertakan** di repositori ini untuk menjaga keamanan API Key dan konfigurasi database.
Credential config files are **not included** in this repository to safeguard API keys and database credentials.

**1. Buat project Firebase / Create a Firebase Project**
- Kunjungi / Visit: [https://console.firebase.google.com/](https://console.firebase.google.com/)
- Aktifkan / Enable: **Cloud Firestore** dan **Authentication**

**2. Setup `android/app/google-services.json`**
```bash
cp android/app/google-services.json.example android/app/google-services.json
# Buka file tersebut dan sesuaikan project_id, project_number, dan api_key dengan project Firebase Anda
# Or download google-services.json from Firebase Console → Project Settings → Android
```

**3. Setup `android/local.properties`**
```bash
cp android/local.properties.example android/local.properties
# Sesuaikan path direktori Android SDK dan Flutter SDK di komputer Anda
# Adjust your local Android SDK and Flutter SDK paths
```

---

## 🚀 Menjalankan Aplikasi / Running the App

```bash
# 1. Unduh seluruh dependensi paket
flutter pub get

# 2. Jalankan aplikasi pada emulator atau perangkat fisik
flutter run
```

---

## 📁 Struktur Proyek / Project Structure

```
lib/
├── screens/
│   ├── login_screen.dart           # Layar login multi-role (Siswa, Guru, Admin)
│   ├── profile_screen.dart         # Pengaturan profil, foto & ganti password
│   ├── smart_camera_screen.dart    # Kamera cerdas & deteksi wajah ML Kit
│   ├── student_screen.dart         # Dashboard siswa, riwayat & scanner QR
│   ├── super_admin_screen.dart     # Panel super admin & pendaftaran akun
│   └── teacher_screen.dart         # Dashboard guru, generator QR & export Excel
├── services/
│   ├── auth_services.dart          # Layanan autentikasi Firebase
│   └── db_service.dart             # Layanan Cloud Firestore & export Excel
└── main.dart                       # Entry point aplikasi & pengecekan sesi login
```

---

<div align="center">

**© 2026 Absensi SMPN 204 - Muhammad Dicky Adicandra**

</div>
