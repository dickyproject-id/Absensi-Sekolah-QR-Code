import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:absensi_qrcode/screens/login_screen.dart';
import 'package:absensi_qrcode/screens/profile_screen.dart';
import 'package:absensi_qrcode/services/db_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeacherScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const TeacherScreen({super.key, required this.userData});

  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  final DbService _dbService = DbService();
  final ScreenshotController _screenshotController = ScreenshotController();

  late TextEditingController _classCodeCtrl;

  int _currentIndex = 0;
  String _qrData = "";
  TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 30);
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _classCodeCtrl = TextEditingController(text: widget.userData['classCode']);
    _generateQR();
  }

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

  @override
  void dispose() {
    _classCodeCtrl.dispose();
    super.dispose();
  }

  void _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _showZoomImage(String base64Image) {
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
                backgroundColor: Colors.black.withValues(alpha: 0.5),
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

  void _generateQR() {
    String dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String timeStr =
        "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}";
    Map<String, dynamic> data = {
      'code': _classCodeCtrl.text.toUpperCase(),
      'date': dateStr,
      'maxTime': timeStr,
    };
    setState(() => _qrData = jsonEncode(data));
  }

  void _shareQR() async {
    if (_qrData.isEmpty) return;
    try {
      String timeFormatted = _selectedTime.format(context);
      final Uint8List? image = await _screenshotController.capture();
      if (image != null) {
        final directory = await getTemporaryDirectory();
        final file = await File(
          '${directory.path}/qr_absen_${_classCodeCtrl.text}.png',
        ).create();
        await file.writeAsBytes(image);
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text:
                'Absensi Kelas ${_classCodeCtrl.text.toUpperCase()} - ${DateFormat('dd MMM yyyy').format(DateTime.now())}. Batas: $timeFormatted',
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal Share: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? t = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (t != null) {
      setState(() => _selectedTime = t);
      _generateQR();
    }
  }

  void _showNoteDialog(String docId, String currentNote) {
    TextEditingController noteCtrl = TextEditingController(text: currentNote);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Catatan Guru"),
        content: TextField(
          controller: noteCtrl,
          decoration: const InputDecoration(
            hintText: "Contoh: Jangan telat lagi",
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              _dbService.updateTeacherNote(docId, noteCtrl.text);
              Navigator.pop(ctx);
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // === TAB 1: QR PAGE ===
    Widget qrPage = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "QR Code Absensi",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    TextField(
                      controller: _classCodeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (val) => _generateQR(),
                      decoration: const InputDecoration(
                        labelText: "Kode Kelas (Edit)",
                        prefixIcon: Icon(Icons.class_),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Batas Terlambat:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.access_time),
                          label: Text(
                            _selectedTime.format(context),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Screenshot(
              controller: _screenshotController,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    if (_qrData.isNotEmpty)
                      QrImageView(data: _qrData, size: 250),
                    const SizedBox(height: 10),
                    Text(
                      _classCodeCtrl.text.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _shareQR,
                icon: const Icon(Icons.share),
                label: const Text("BAGIKAN QR-CODE"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // === TAB 2: REKAP PAGE ===
    Widget rekapPage = Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: const BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Filter Tanggal:",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      DateTime? d = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (d != null) setState(() => _selectedDate = d);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month,
                            size: 18,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            DateFormat('dd MMM yyyy').format(_selectedDate),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // === TOMBOL EXPORT EXCEL (TERUPDATE) ===
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text("Sedang menyiapkan Excel..."),
                      ),
                    );

                    String formattedDateForQuery = DateFormat(
                      'yyyy-MM-dd',
                    ).format(_selectedDate);

                    String? filePath = await _dbService.exportToExcel(
                      _classCodeCtrl.text.toUpperCase(),
                      formattedDateForQuery,
                    );

                    if (filePath == "empty") {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text("Data kosong tidak bisa di export"),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    } else if (filePath != null) {
                      String dateStr = DateFormat(
                        'dd-MM-yyyy',
                      ).format(_selectedDate);
                      await SharePlus.instance.share(
                        ShareParams(
                          files: [XFile(filePath)],
                          text:
                              "Laporan Kehadiran Kelas ${_classCodeCtrl.text.toUpperCase()} Tanggal $dateStr",
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.file_download),
                  label: const Text("EXPORT EXCEL"),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: StreamBuilder<List<String>>(
            stream: _dbService.getActiveStudentIds(
              _classCodeCtrl.text.toUpperCase(),
            ),
            builder: (context, studentSnapshot) {
              List<String> activeStudentIds = studentSnapshot.data ?? [];

              return StreamBuilder<QuerySnapshot>(
                stream: _dbService.getAttendanceStream(
                  _classCodeCtrl.text.toUpperCase(),
                  DateFormat('yyyy-MM-dd').format(_selectedDate),
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        "Tidak ada data absensi.",
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    );
                  }

                  var docs = snapshot.data!.docs;

                  var filteredDocs = docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return activeStudentIds.contains(data['id_number']);
                  }).toList();

                  if (filteredDocs.isEmpty && activeStudentIds.isNotEmpty) {
                    return Center(
                      child: Text(
                        "Tidak ada data (Siswa mungkin menghapus riwayat).",
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    );
                  }

                  filteredDocs.sort((a, b) {
                    var dataA = a.data() as Map<String, dynamic>;
                    var dataB = b.data() as Map<String, dynamic>;
                    return dataA['student_name']
                        .toString()
                        .toLowerCase()
                        .compareTo(
                          dataB['student_name'].toString().toLowerCase(),
                        );
                  });

                  return ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: filteredDocs.length,
                    itemBuilder: (ctx, i) {
                      var data = filteredDocs[i].data() as Map<String, dynamic>;
                      bool isLate = data['status'] == 'Terlambat';
                      String age = _calculateAge(data['birthDate']);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 2,
                        child: ListTile(
                          leading: GestureDetector(
                            onTap: () {
                              if (data['photo_base64'] != null) {
                                _showZoomImage(data['photo_base64']);
                              }
                            },
                            child: CircleAvatar(
                              backgroundColor: isLate
                                  ? Colors.red.shade100
                                  : Colors.green.shade100,
                              backgroundImage: (data['photo_base64'] != null)
                                  ? MemoryImage(
                                      base64Decode(data['photo_base64']),
                                    )
                                  : null,
                            ),
                          ),
                          title: Text(
                            data['student_name'],
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
                                      data['status'],
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
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              if (data['teacher_note'] != '')
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  margin: const EdgeInsets.only(top: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    "Guru: ${data['teacher_note']}",
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.grey),
                            onPressed: () => _showNoteDialog(
                              filteredDocs[i].id,
                              data['teacher_note'] ?? '',
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );

    List<Widget> pages = [
      qrPage,
      rekapPage,
      ProfileScreen(userData: widget.userData, isEditable: true),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Dashboard Guru", style: TextStyle(fontSize: 14)),
            Text(
              widget.userData['name'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_2),
            label: "QR Share",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: "Rekap"),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
