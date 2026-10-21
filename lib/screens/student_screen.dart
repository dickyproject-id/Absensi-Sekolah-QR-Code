import 'dart:convert';
import 'dart:io';

import 'package:absensi_qrcode/screens/login_screen.dart';
import 'package:absensi_qrcode/screens/profile_screen.dart';
import 'package:absensi_qrcode/screens/smart_camera_screen.dart';
import 'package:absensi_qrcode/services/db_service.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart'; // WAJIB: Untuk format tanggal & hitung umur
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const StudentScreen({super.key, required this.userData});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  int _currentIndex = 0;
  final DbService _dbService = DbService();
  bool _isLoading = false;

  // ===========================================================================
  // CONFIGURASI LOKASI & SAKLAR PENGUJIAN KKP
  // ===========================================================================
  final double schoolLat = -6.142763; // Koordinat asli SMPN 204
  final double schoolLng = 106.743728;
  final double maxDistance = 1000; // Radius 1KM

  // UBAH KE 'true' UNTUK PENGUJIAN KKP DI LUAR SEKOLAH (GPS BYPASS)
  // UBAH KE 'false' UNTUK PENGGUNAAN ASLI (GPS RADIUS AKTIF)
  final bool isTestingMode = true;
  // ===========================================================================

  // --- LOGIC HITUNG UMUR ---
  String _calculateAge(String? dateStr) {
    if (dateStr == null || dateStr == '-' || dateStr.isEmpty) return '-';
    try {
      DateTime dob = DateFormat('yyyy-MM-dd').parse(dateStr);
      DateTime now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return "$age Thn";
    } catch (e) {
      return '-';
    }
  }

  // --- LOGIC LOGOUT ---
  void _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  // --- LOGIC HAPUS KEHADIRAN (Agar bisa absen ulang) ---
  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Riwayat?"),
        content: const Text(
          "Jika dihapus, riwayat ini akan hilang dari laporan guru dan Anda bisa melakukan absensi ulang hari ini.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await _dbService.deleteAttendance(docId);
                _showSuccess("Data berhasil dihapus. Silakan absen ulang.");
              } catch (e) {
                _showError("Gagal menghapus data.");
              } finally {
                setState(() => _isLoading = false);
              }
            },
            child: const Text(
              "Hapus & Absen Ulang",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // --- LOGIC ZOOM FOTO ---
  void _showZoomImage(String? base64Image) {
    if (base64Image == null || base64Image.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.memory(
                base64Decode(base64Image),
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.5),
                radius: 20,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- LOGIC ABSENSI UTAMA ---
  void _startAttendanceProcess() async {
    setState(() => _isLoading = true);

    try {
      String idNumber = widget.userData['id_number'];

      // 1. CEK SUDAH ABSEN HARI INI?
      String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      bool alreadyAbsen = await _dbService.hasStudentAttended(
        idNumber,
        todayStr,
      );

      if (alreadyAbsen) {
        _showError("Anda sudah melakukan absensi hari ini!");
        setState(() => _isLoading = false);
        return;
      }

      // 2. CEK IZIN GPS
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError("Aktifkan GPS perangkat Anda!");
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError("Izin lokasi wajib diaktifkan!");
          return;
        }
      }

      // 3. SCAN QR CODE
      if (!mounted) return;
      setState(() => _isLoading = false);

      final String? qrRaw = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SimpleQRScanner()),
      );

      if (qrRaw == null) return;

      setState(() => _isLoading = true);

      // 4. CEK LOKASI
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      double distance = Geolocator.distanceBetween(
        schoolLat,
        schoolLng,
        pos.latitude,
        pos.longitude,
      );

      // SAKLAR LOGIC: Jika isTestingMode = true, jarak diabaikan.
      if (distance > maxDistance && !isTestingMode) {
        _showError("Jarak terlalu jauh! (${distance.toInt()}m dari sekolah)");
        return;
      }

      // 5. VALIDASI DATA QR
      Map<String, dynamic> qrData;
      try {
        qrData = jsonDecode(qrRaw);
      } catch (e) {
        _showError("QR Code tidak valid.");
        return;
      }

      if (qrData['code'] != widget.userData['classCode']) {
        _showError("QR Salah! Ini untuk kelas ${qrData['code']}.");
        return;
      }

      String maxTimeStr = qrData['maxTime'];
      String nowTimeStr = DateFormat('HH:mm').format(DateTime.now());
      String status = (nowTimeStr.compareTo(maxTimeStr) > 0)
          ? "Terlambat"
          : "Hadir";

      if (status == "Terlambat") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Anda Terlambat!"),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // 6. AMBIL FOTO SELFIE
      if (!mounted) return;
      final XFile? photo = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SmartCameraScreen()),
      );

      if (photo == null) {
        setState(() => _isLoading = false);
        return;
      }

      // 7. KIRIM KE DATABASE
      await _dbService.submitAbsensi(
        idNumber: idNumber,
        studentName: widget.userData['name'],
        classCode: widget.userData['classCode'],
        date: qrData['date'],
        time: nowTimeStr,
        status: status,
        photoFile: File(photo.path),
        lat: pos.latitude,
        lng: pos.longitude,
        gender: widget.userData['gender'] ?? '-',
        birthDate: widget.userData['birthDate'] ?? '-',
        religion: widget.userData['religion'] ?? '-',
      );

      _showSuccess("Absensi Berhasil Tercatat! ($status)");
    } catch (e) {
      _showError("Terjadi Kesalahan: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  void _showSuccess(String msg) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));

  @override
  Widget build(BuildContext context) {
    // === TAB 1: HOME ===
    Widget homePage = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // INDIKATOR TESTING MODE (Visual agar penguji/Anda tahu saklar sedang aktif)
          if (isTestingMode)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "⚠️ Mode Pengujian Aktif (GPS Bypass)",
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          const Icon(Icons.verified_user, size: 80, color: Colors.blueAccent),
          const SizedBox(height: 20),
          Text(
            "Halo, ${widget.userData['name']}",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            "Kelas: ${widget.userData['classCode']}",
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Text(
              "Status: Siap Absen",
              style: TextStyle(color: Colors.blue),
            ),
          ),
          const SizedBox(height: 50),
          _isLoading
              ? const CircularProgressIndicator()
              : SizedBox(
                  width: 250,
                  height: 60,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                    icon: const Icon(Icons.qr_code_scanner, size: 28),
                    label: const Text(
                      "MULAI ABSEN",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: _startAttendanceProcess,
                  ),
                ),
          const SizedBox(height: 20),
          const Text(
            "Pastikan berada di area sekolah",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );

    // === TAB 2: RIWAYAT ===
    Widget historyPage = Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          width: double.infinity,
          color: Colors.blue.shade50,
          child: const Text(
            "Riwayat Kehadiran",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _dbService.getStudentHistory(widget.userData['id_number']),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                return const Center(child: Text("Belum ada riwayat absen."));

              var docs = snapshot.data!.docs;

              docs.sort((a, b) {
                var dataA = a.data() as Map<String, dynamic>;
                var dataB = b.data() as Map<String, dynamic>;
                var timeA = dataA['created_at'] != null
                    ? (dataA['created_at'] as Timestamp).toDate()
                    : DateTime(2000);
                var timeB = dataB['created_at'] != null
                    ? (dataB['created_at'] as Timestamp).toDate()
                    : DateTime(2000);
                return timeB.compareTo(timeA);
              });

              return ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var data = docs[index].data() as Map<String, dynamic>;
                  String docId = docs[index].id;
                  bool isLate = data['status'] == 'Terlambat';
                  String teacherNote = data['teacher_note'] ?? "";
                  String age = _calculateAge(data['birthDate']);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 8,
                      ),
                      leading: GestureDetector(
                        onTap: () => _showZoomImage(data['photo_base64']),
                        child: CircleAvatar(
                          backgroundColor: isLate
                              ? Colors.red.shade100
                              : Colors.green.shade100,
                          backgroundImage:
                              (data['photo_base64'] != null &&
                                  data['photo_base64'].toString().isNotEmpty)
                              ? MemoryImage(base64Decode(data['photo_base64']))
                              : null,
                          child:
                              (data['photo_base64'] == null ||
                                  data['photo_base64'].toString().isEmpty)
                              ? Icon(
                                  isLate ? Icons.timer_off : Icons.check_circle,
                                  color: isLate ? Colors.red : Colors.green,
                                )
                              : null,
                        ),
                      ),
                      title: Text(
                        data['date'] ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "ID: ${data['id_number'] ?? '-'}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isLate ? Colors.red : Colors.green,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  data['status'] ?? '-',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Jam: ${data['time']}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "Usia: $age | Agama: ${data['religion'] ?? '-'}",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                          if (teacherNote.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: Colors.orange.shade200,
                                ),
                              ),
                              child: Text(
                                "Guru: $teacherNote",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_sweep,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => _confirmDelete(docId),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Siswa"),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: [
        homePage,
        historyPage,
        ProfileScreen(userData: widget.userData, isEditable: false),
      ][_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Absen"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "Riwayat"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

class SimpleQRScanner extends StatefulWidget {
  const SimpleQRScanner({super.key});
  @override
  State<SimpleQRScanner> createState() => _SimpleQRScannerState();
}

class _SimpleQRScannerState extends State<SimpleQRScanner> {
  bool _isScanned = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR Guru")),
      body: MobileScanner(
        onDetect: (capture) {
          if (_isScanned) return;
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
            final String code = barcodes.first.rawValue!;
            if (code.contains("{") && code.contains("}")) {
              setState(() => _isScanned = true);
              Navigator.pop(context, code);
            }
          }
        },
      ),
    );
  }
}
