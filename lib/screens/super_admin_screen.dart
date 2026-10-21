import 'package:absensi_qrcode/screens/login_screen.dart';
import 'package:absensi_qrcode/services/db_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for TextInputFormatter
import 'package:intl/intl.dart';

class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> {
  final DbService _dbService = DbService();
  final _formKey = GlobalKey<FormState>();

  // --- CONTROLLERS ---
  final TextEditingController _idNumberCtrl =
      TextEditingController(); // ID NUMBER
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _classCodeCtrl = TextEditingController();
  final TextEditingController _dobCtrl = TextEditingController();

  // --- VARIABLES ---
  String _selectedRole = 'siswa';
  String _selectedGender = 'L'; // Default Laki-laki

  // --- RELIGION SELECTION ---
  String _selectedReligion = 'Islam';
  final List<String> _religionList = [
    'Islam',
    'Kristen Protestan',
    'Katolik',
    'Hindu',
    'Buddha',
    'Konghucu',
  ];

  bool _isLoading = false;
  final TextStyle _inputStyle = const TextStyle(fontSize: 16);

  @override
  void dispose() {
    _idNumberCtrl.dispose();
    _nameCtrl.dispose();
    _passwordCtrl.dispose();
    _classCodeCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  // --- LOGIC BUAT USER ---
  void _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dobCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tanggal Lahir wajib diisi!"),
          backgroundColor: Colors.pink,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _dbService.createUser(
        idNumber: _idNumberCtrl.text.trim(), // Kirim variable idNumber
        password: _passwordCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        role: _selectedRole,
        classCode: _classCodeCtrl.text.trim().toUpperCase(),
        gender: _selectedGender,
        birthDate: _dobCtrl.text.trim(),
        religion: _selectedReligion,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Akun berhasil dibuat!"),
          backgroundColor: Colors.green,
        ),
      );

      // Reset Form
      _idNumberCtrl.clear();
      _nameCtrl.clear();
      _passwordCtrl.clear();
      _dobCtrl.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.pink),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Super Admin - Buat Akun"),
        backgroundColor: Colors.pinkAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Buat Akun Baru",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // 1. INPUT ROLE
              DropdownButtonFormField<String>(
                value: _selectedRole,
                style: _inputStyle.copyWith(color: Colors.black),
                decoration: const InputDecoration(
                  labelText: "Peran (Role)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.manage_accounts),
                ),
                items: const [
                  DropdownMenuItem(value: 'siswa', child: Text("Siswa")),
                  DropdownMenuItem(
                    value: 'guru',
                    child: Text("Guru (Wali Kelas)"),
                  ),
                ],
                onChanged: (val) => setState(() => _selectedRole = val!),
              ),
              const SizedBox(height: 15),

              // 2. INPUT ID NUMBER
              TextFormField(
                controller: _idNumberCtrl,
                style: _inputStyle,
                decoration: const InputDecoration(
                  labelText: "ID Number (NIS/NIP)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 15),

              // 3. INPUT NAMA
              TextFormField(
                controller: _nameCtrl,
                style: _inputStyle,
                decoration: const InputDecoration(
                  labelText: "Nama Lengkap",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 15),

              // 4. GENDER & RELIGION
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedGender,
                      style: _inputStyle.copyWith(color: Colors.black),
                      decoration: const InputDecoration(
                        labelText: "Gender",
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'L', child: Text("Laki-Laki")),
                        DropdownMenuItem(value: 'P', child: Text("Perempuan")),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedGender = val!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedReligion,
                      isExpanded: true,
                      style: _inputStyle.copyWith(color: Colors.black),
                      decoration: const InputDecoration(
                        labelText: "Agama",
                        border: OutlineInputBorder(),
                      ),
                      items: _religionList.map((String religion) {
                        return DropdownMenuItem<String>(
                          value: religion,
                          child: Text(
                            religion,
                            style: _inputStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedReligion = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // 5. INPUT TANGGAL LAHIR (FIXED DATE PICKER)
              TextFormField(
                controller: _dobCtrl,
                readOnly: true,
                style: _inputStyle,
                decoration: const InputDecoration(
                  labelText: "Tanggal Lahir",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_month),
                ),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2010), // Mulai dari 2010
                    firstDate: DateTime(1950), // Batas paling tua
                    lastDate: DateTime.now(), // Batas hari ini
                  );
                  if (pickedDate != null) {
                    setState(
                      () => _dobCtrl.text = DateFormat(
                        'yyyy-MM-dd',
                      ).format(pickedDate),
                    );
                  }
                },
                validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 15),

              // 6. INPUT KODE KELAS
              TextFormField(
                controller: _classCodeCtrl,
                style: _inputStyle,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [UpperCaseTextFormatter()],
                decoration: const InputDecoration(
                  labelText: "Kode Kelas (Guru/Wali Kelas)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.class_),
                ),
                validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 15),

              // 7. INPUT PASSWORD
              TextFormField(
                controller: _passwordCtrl,
                style: _inputStyle,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (val) => val!.length < 4 ? "Min 4 karakter" : null,
              ),
              const SizedBox(height: 30),

              // TOMBOL SUBMIT
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "BUAT AKUN",
                          style: _inputStyle.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
