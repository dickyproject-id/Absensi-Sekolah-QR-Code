# Absensi Sekolah dengan QR Code

Aplikasi absensi sekolah (SMPN 204) untuk Siswa dan Guru berbasis pemindaian QR Code menggunakan Flutter dan Cloud Firestore.

## Fitur Utama

- **Login Multi-Role**: Siswa, Guru, dan Super Admin.
- **Auto Login / Session Persistence**: Menggunakan SharedPreferences.
- **Smart Camera QR Scanner**: Pemindaian QR Code cepat dan akurat untuk absensi kehadiran.
- **Export Data ke Excel**: Guru dan Admin dapat mengekspor rekap absensi ke format Excel (`.xlsx`).
- **Manajemen Profil & Ganti Password**: Kemudahan konfigurasi akun bagi tiap pengguna.

## Panduan Setup & Konfigurasi

Untuk alasan keamanan, file konfigurasi rahasia (seperti Firebase API Keys & kredensial lokal) tidak disertakan dalam repositori ini.

### 1. Konfigurasi Firebase (Android)
Salin file template:
```bash
cp android/app/google-services.json.example android/app/google-services.json
```
Lalu lengkapi dengan konfigurasi Firebase project Anda sendiri (`project_id`, `api_key`, `mobilesdk_app_id`).

### 2. Konfigurasi Local Properties (Android)
Salin file template:
```bash
cp android/local.properties.example android/local.properties
```
Sesuaikan direktori `sdk.dir` dan `flutter.sdk` dengan direktori di laptop/komputer Anda.

### 3. Install Dependencies & Jalankan
```bash
flutter pub get
flutter run
```
