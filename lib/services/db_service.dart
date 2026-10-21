import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class DbService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==============================================================================
  // 1. AUTHENTICATION (LOGIN)
  // ==============================================================================
  Future<Map<String, dynamic>?> loginUser(
    String idNumber,
    String password,
    String role, {
    String? classCode,
  }) async {
    try {
      Query query = _db
          .collection('users')
          .where('id_number', isEqualTo: idNumber)
          .where('password', isEqualTo: password)
          .where('role', isEqualTo: role);

      if (role == 'siswa' && classCode != null) {
        query = query.where('classCode', isEqualTo: classCode);
      }

      QuerySnapshot snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        var data = snapshot.docs.first.data() as Map<String, dynamic>;
        data['docId'] = snapshot.docs.first.id;
        return data;
      }
      return null;
    } catch (e) {
      print("Error Login: $e");
      return null;
    }
  }

  // ==============================================================================
  // 2. CREATE USER (SUPER ADMIN) - DENGAN AUTO CLEAN UP
  // ==============================================================================
  Future<void> createUser({
    required String idNumber,
    required String password,
    required String name,
    required String role,
    required String classCode,
    required String gender,
    required String birthDate,
    required String religion,
  }) async {
    try {
      QuerySnapshot check = await _db
          .collection('users')
          .where('id_number', isEqualTo: idNumber)
          .get();

      if (check.docs.isNotEmpty) {
        throw Exception("ID Number (NIS/NIP) sudah terdaftar!");
      }

      QuerySnapshot oldHistory = await _db
          .collection('attendance')
          .where('id_number', isEqualTo: idNumber)
          .get();

      if (oldHistory.docs.isNotEmpty) {
        WriteBatch batch = _db.batch();
        for (var doc in oldHistory.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      await _db.collection('users').add({
        'id_number': idNumber,
        'password': password,
        'name': name,
        'role': role,
        'classCode': classCode,
        'gender': gender,
        'birthDate': birthDate,
        'religion': religion,
        'profile_base64': null,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // ==============================================================================
  // 3. UPDATE PROFILE
  // ==============================================================================
  Future<void> updateProfile(
    String docId,
    String classCode,
    String? base64Image,
  ) async {
    try {
      Map<String, dynamic> data = {'classCode': classCode};
      if (base64Image != null) {
        data['profile_base64'] = base64Image;
      }
      await _db.collection('users').doc(docId).update(data);
    } catch (e) {
      throw Exception("Gagal update profil");
    }
  }

  // ==============================================================================
  // 4. SUBMIT ABSENSI
  // ==============================================================================
  Future<void> submitAbsensi({
    required String idNumber,
    required String studentName,
    required String classCode,
    required String date,
    required String time,
    required String status,
    required File photoFile,
    required double lat,
    required double lng,
    required String gender,
    required String birthDate,
    required String religion,
  }) async {
    try {
      Uint8List? compressedBytes = await FlutterImageCompress.compressWithFile(
        photoFile.absolute.path,
        minWidth: 600,
        minHeight: 600,
        quality: 60,
        format: CompressFormat.jpeg,
      );

      List<int> finalBytes = compressedBytes ?? await photoFile.readAsBytes();
      String base64Photo = base64Encode(finalBytes);

      await _db.collection('attendance').add({
        'id_number': idNumber,
        'student_name': studentName,
        'class_code': classCode,
        'date': date,
        'time': time,
        'status': status,
        'photo_base64': base64Photo,
        'location': GeoPoint(lat, lng),
        'gender': gender,
        'birthDate': birthDate,
        'religion': religion,
        'teacher_note': '',
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error Submit: $e");
      throw Exception("Gagal mengirim data absen.");
    }
  }

  // ==============================================================================
  // 5. CEK SUDAH ABSEN
  // ==============================================================================
  Future<bool> hasStudentAttended(String idNumber, String date) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('attendance')
          .where('id_number', isEqualTo: idNumber)
          .where('date', isEqualTo: date)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ==============================================================================
  // 6. DELETE ATTENDANCE (UNTUK ABSEN ULANG)
  // ==============================================================================
  Future<void> deleteAttendance(String docId) async {
    try {
      await _db.collection('attendance').doc(docId).delete();
    } catch (e) {
      print("Error Delete: $e");
      throw Exception("Gagal menghapus riwayat kehadiran.");
    }
  }

  // ==============================================================================
  // 7. GET ATTENDANCE STREAM (GURU)
  // ==============================================================================
  Stream<QuerySnapshot> getAttendanceStream(String classCode, String date) {
    return _db
        .collection('attendance')
        .where('class_code', isEqualTo: classCode)
        .where('date', isEqualTo: date)
        .snapshots();
  }

  // ==============================================================================
  // 8. GET ACTIVE STUDENT IDs (FILTERING)
  // ==============================================================================
  Stream<List<String>> getActiveStudentIds(String classCode) {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'siswa')
        .where('classCode', isEqualTo: classCode)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => doc['id_number'] as String).toList(),
        );
  }

  // ==============================================================================
  // 9. UPDATE CATATAN GURU
  // ==============================================================================
  Future<void> updateTeacherNote(String docId, String note) async {
    await _db.collection('attendance').doc(docId).update({
      'teacher_note': note,
    });
  }

  // ==============================================================================
  // 10. GET RIWAYAT (SISWA)
  // ==============================================================================
  Stream<QuerySnapshot> getStudentHistory(String idNumber) {
    return _db
        .collection('attendance')
        .where('id_number', isEqualTo: idNumber)
        .snapshots();
  }

  // ==============================================================================
  // 11. EXPORT EXCEL (TERUPDATE: DENGAN FILTER TANGGAL SINKRON)
  // ==============================================================================
  Future<String?> exportToExcel(String classCode, String selectedDate) async {
    try {
      // Query disesuaikan agar sama dengan yang tampil di UI (Filter Tanggal)
      QuerySnapshot snapshot = await _db
          .collection('attendance')
          .where('class_code', isEqualTo: classCode)
          .where('date', isEqualTo: selectedDate)
          .get();

      if (snapshot.docs.isEmpty) {
        return "empty";
      }

      var excel = Excel.createExcel();
      String sheetName = 'Rekap Absensi';
      excel.rename('Sheet1', sheetName);
      Sheet sheet = excel[sheetName];

      sheet.appendRow([
        TextCellValue('Tanggal'),
        TextCellValue('Nama Siswa'),
        TextCellValue('ID Number'),
        TextCellValue('JK'),
        TextCellValue('Agama'),
        TextCellValue('Usia'),
        TextCellValue('Jam Masuk'),
        TextCellValue('Status'),
        TextCellValue('Catatan Guru'),
      ]);

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        String ageStr = '-';
        if (data['birthDate'] != null && data['birthDate'] != '-') {
          try {
            DateTime dob = DateFormat('yyyy-MM-dd').parse(data['birthDate']);
            int age = DateTime.now().year - dob.year;
            if (DateTime.now().month < dob.month ||
                (DateTime.now().month == dob.month &&
                    DateTime.now().day < dob.day)) {
              age--;
            }
            ageStr = "$age Thn";
          } catch (_) {}
        }

        sheet.appendRow([
          TextCellValue(data['date'] ?? '-'),
          TextCellValue(data['student_name'] ?? '-'),
          TextCellValue(data['id_number'] ?? '-'),
          TextCellValue(data['gender'] ?? '-'),
          TextCellValue(data['religion'] ?? '-'),
          TextCellValue(ageStr),
          TextCellValue(data['time'] ?? '-'),
          TextCellValue(data['status'] ?? '-'),
          TextCellValue(data['teacher_note'] ?? ''),
        ]);
      }

      var fileBytes = excel.save();
      final directory = await getTemporaryDirectory();
      String filePath =
          "${directory.path}/Laporan_Kehadiran_$selectedDate.xlsx";

      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes!);

      return filePath;
    } catch (e) {
      print("Export Excel Error: $e");
      return null;
    }
  }

  // ==============================================================================
  // 12. GANTI PASSWORD (TERUPDATE: MENGEMBALIKAN BOOLEAN)
  // ==============================================================================
  Future<bool> changePassword(String docId, String newPassword) async {
    try {
      await _db.collection('users').doc(docId).update({
        'password': newPassword,
      });
      return true;
    } catch (e) {
      print("Gagal ganti password: $e");
      return false;
    }
  }
}
