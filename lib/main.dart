import 'dart:convert';

import 'package:absensi_qrcode/screens/login_screen.dart';
import 'package:absensi_qrcode/screens/student_screen.dart';
import 'package:absensi_qrcode/screens/teacher_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk Orientasi Layar
import 'package:intl/date_symbol_data_local.dart'; // Untuk Format Tanggal Indo
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // 1. Pastikan engine Flutter siap
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Setting Format Tanggal Indonesia (PENTING untuk fitur Usia & Tanggal)
  await initializeDateFormatting('id_ID', null);

  // 3. Kunci Orientasi Layar ke Portrait (Berdiri) agar UI tidak berantakan
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 4. Inisialisasi Firebase
  await Firebase.initializeApp();

  // 5. Jalankan Aplikasi
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Absensi SMPN 204',

      // Tema Aplikasi Global - Konsisten dengan warna Biru Akses
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey.shade50,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          centerTitle:
              false, // Diubah ke false sesuai permintaan dashboard guru di kiri
          elevation: 0,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),

      // Entry point aplikasi menggunakan pengecekan session
      home: const CheckAuth(),
    );
  }
}

// === WIDGET KHUSUS CEK STATUS LOGIN (AUTO LOGIN LOGIC) ===
class CheckAuth extends StatefulWidget {
  const CheckAuth({super.key});

  @override
  State<CheckAuth> createState() => _CheckAuthState();
}

class _CheckAuthState extends State<CheckAuth> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // --- LOGIC CEK SESSION (DATA DI MEMORI HP) ---
  void _checkLoginStatus() async {
    // 1. Inisialisasi SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // 2. Ambil data string JSON dari key 'userData'
    String? userDataStr = prefs.getString('userData');

    // 3. Beri jeda 2 detik untuk animasi Splash Screen yang smooth
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (userDataStr != null) {
      // --- JIKA USER SUDAH PERNAH LOGIN (SESSION ADA) ---
      try {
        Map<String, dynamic> userData = jsonDecode(userDataStr);
        String role = userData['role'];

        // Arahkan otomatis berdasarkan Role tanpa perlu input NIS/NIP lagi
        if (role == 'siswa') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => StudentScreen(userData: userData),
            ),
          );
        } else if (role == 'guru') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => TeacherScreen(userData: userData),
            ),
          );
        } else {
          // Jika role tidak dikenal, arahkan ke login
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      } catch (e) {
        // Jika data di memori rusak (corrupt), bersihkan dan minta login ulang
        debugPrint("Session Corrupt: $e");
        await prefs.clear();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } else {
      // --- JIKA BELUM LOGIN ---
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tampilan Splash Screen (Logo Sekolah & Loading)
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.blue.shade50],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Aplikasi
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/logo_white_bg.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Nama Aplikasi
              const Text(
                "ABSENSI SMPN 204",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Sistem Absensi Berbasis QR-Code",
                style: TextStyle(color: Colors.blueGrey, fontSize: 14),
              ),

              const SizedBox(height: 60),

              // Loading Indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
              const SizedBox(height: 16),
              const Text(
                "Mengecek Sesi...",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
