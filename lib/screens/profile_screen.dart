import 'dart:convert';
import 'dart:io';

import 'package:absensi_qrcode/screens/smart_camera_screen.dart';
import 'package:absensi_qrcode/services/db_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final bool isEditable;
  const ProfileScreen({
    super.key,
    required this.userData,
    this.isEditable = false,
  });
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DbService _dbService = DbService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameCtrl;
  late TextEditingController _classCodeCtrl;
  String? _imageBase64;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.userData['name']);
    _classCodeCtrl = TextEditingController(text: widget.userData['classCode']);
    _imageBase64 = widget.userData['profile_base64'];
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
      return "$age Tahun";
    } catch (e) {
      return '-';
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.all(15.0),
                child: Text(
                  "Ganti Foto Profil",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.blue),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _processPhoto(isCamera: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('Ambil dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _processPhoto(isCamera: false);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processPhoto({required bool isCamera}) async {
    XFile? pickedFile;

    if (isCamera) {
      pickedFile = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SmartCameraScreen()),
      );
    } else {
      pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        imageQuality: 50,
      );
    }

    if (pickedFile != null) {
      setState(() => _isLoading = true);
      try {
        File file = File(pickedFile.path);
        List<int> bytes = await file.readAsBytes();
        String base64Image = base64Encode(bytes);

        await _dbService.updateProfile(
          widget.userData['docId'],
          _classCodeCtrl.text.toUpperCase(),
          base64Image,
        );

        setState(() {
          _imageBase64 = base64Image;
          widget.userData['profile_base64'] = base64Image;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Foto Profil Berhasil Diganti!"),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal ganti foto: $e"),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      String code = _classCodeCtrl.text.toUpperCase();
      await _dbService.updateProfile(
        widget.userData['docId'],
        code,
        _imageBase64,
      );
      setState(() {
        widget.userData['classCode'] = code;
        widget.userData['profile_base64'] = _imageBase64;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profil Berhasil Diperbarui!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal update profil: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showChangePasswordDialog() {
    final TextEditingController n = TextEditingController();
    final TextEditingController c = TextEditingController();
    bool isObscure = true;
    bool isDialogLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Ganti Password"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: n,
                    obscureText: isObscure,
                    decoration: InputDecoration(
                      labelText: "Password Baru",
                      suffixIcon: IconButton(
                        icon: Icon(
                          isObscure ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () =>
                            setStateDialog(() => isObscure = !isObscure),
                      ),
                    ),
                  ),
                  TextField(
                    controller: c,
                    obscureText: isObscure,
                    decoration: const InputDecoration(
                      labelText: "Konfirmasi Password",
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDialogLoading ? null : () => Navigator.pop(ctx),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: isDialogLoading
                      ? null
                      : () async {
                          if (n.text.length < 4 || n.text != c.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Password tidak cocok atau terlalu pendek!",
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          final messenger = ScaffoldMessenger.of(context);
                          setStateDialog(() => isDialogLoading = true);

                          bool success = await _dbService.changePassword(
                            widget.userData['docId'],
                            n.text.trim(),
                          );

                          if (!ctx.mounted) return;

                          if (success) {
                            Navigator.pop(ctx);
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text("Sukses ganti password!"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            setStateDialog(() => isDialogLoading = false);
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text("Gagal memperbarui database."),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: isDialogLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _zoom() {
    if (_imageBase64 == null) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(child: Image.memory(base64Decode(_imageBase64!))),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String age = _calculateAge(widget.userData['birthDate']);
    bool hasPhoto = _imageBase64 != null && _imageBase64!.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: _zoom,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade200,
                      border: Border.all(color: Colors.blueAccent, width: 3),
                      image: hasPhoto
                          ? DecorationImage(
                              image: MemoryImage(base64Decode(_imageBase64!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: hasPhoto
                        ? null
                        : const Icon(
                            Icons.person,
                            size: 80,
                            color: Colors.grey,
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _showPickerOptions,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Ketuk icon pensil untuk ganti foto",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: _nameCtrl,
            readOnly: true,
            style: const TextStyle(fontSize: 16, color: Colors.black),
            decoration: InputDecoration(
              labelText: "Nama Lengkap",
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.person_outline),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _classCodeCtrl,
            enabled: widget.isEditable,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [UpperCaseTextFormatter()],
            style: const TextStyle(fontSize: 16, color: Colors.black),
            decoration: InputDecoration(
              labelText: "Kode Kelas",
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.class_outlined),
              filled: true,
              fillColor: widget.isEditable ? Colors.white : Colors.grey.shade50,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(height: 25),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Informasi Pribadi",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildInfoTile(
            Icons.cake_outlined,
            "Usia & Tgl Lahir",
            "$age (${widget.userData['birthDate'] ?? '-'})",
          ),
          _buildInfoTile(
            Icons.mosque_outlined,
            "Agama",
            widget.userData['religion'] ?? '-',
          ),
          _buildInfoTile(
            Icons.wc_outlined,
            "Gender",
            widget.userData['gender'] == 'L' ? "Laki-Laki" : "Perempuan",
          ),
          _buildInfoTile(
            Icons.badge_outlined,
            "ID Number (NIS/NIP)",
            widget.userData['id_number'] ?? '-',
          ),
          _buildInfoTile(
            Icons.security_outlined,
            "Peran Akun",
            widget.userData['role'].toString().toUpperCase(),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showChangePasswordDialog,
              icon: const Icon(Icons.lock_reset, color: Colors.red),
              label: const Text(
                "GANTI PASSWORD",
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
          const SizedBox(height: 15),
          if (widget.isEditable)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "SIMPAN PERUBAHAN",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData i, String t, String v) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Row(
      children: [
        Icon(i, color: Colors.blueAccent, size: 24),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                v,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) =>
      n.copyWith(text: n.text.toUpperCase());
}
