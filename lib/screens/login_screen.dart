import 'dart:convert';

import 'package:absensi_qrcode/screens/student_screen.dart';
import 'package:absensi_qrcode/screens/super_admin_screen.dart';
import 'package:absensi_qrcode/screens/teacher_screen.dart';
import 'package:absensi_qrcode/services/db_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DbService _dbService = DbService();

  bool _isLoading = false;
  bool _isObscure = true;

  // --- CONTROLLERS ---
  final TextEditingController _studentNisCtrl = TextEditingController();
  final TextEditingController _classCodeCtrl = TextEditingController();
  final TextEditingController _studentPassCtrl = TextEditingController();
  final TextEditingController _teacherNipCtrl = TextEditingController();
  final TextEditingController _teacherPassCtrl = TextEditingController();
  final TextEditingController _adminCodeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Jalankan pengecekan session saat aplikasi dibuka
    _checkAutoLogin();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _studentNisCtrl.dispose();
    _classCodeCtrl.dispose();
    _studentPassCtrl.dispose();
    _teacherNipCtrl.dispose();
    _teacherPassCtrl.dispose();
    _adminCodeCtrl.dispose();
    super.dispose();
  }

  // =================================================================
  // LOGIC AUTO LOGIN (SESSION)
  // =================================================================
  void _checkAutoLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userRaw = prefs.getString('userData');

    if (userRaw != null) {
      Map<String, dynamic> userData = jsonDecode(userRaw);
      if (!mounted) return;

      // Langsung arahkan berdasarkan role yang tersimpan
      if (userData['role'] == 'guru') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => TeacherScreen(userData: userData)),
        );
      } else if (userData['role'] == 'siswa') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => StudentScreen(userData: userData)),
        );
      }
    }
  }

  Future<void> _saveSession(Map<String, dynamic> userData) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userData', jsonEncode(userData));
    } catch (e) {
      debugPrint("Gagal simpan sesi: $e");
    }
  }

  // =================================================================
  // LOGIC LOGIN HANDLERS
  // =================================================================

  void _handleStudentLogin() async {
    if (_studentNisCtrl.text.isEmpty ||
        _classCodeCtrl.text.isEmpty ||
        _studentPassCtrl.text.isEmpty) {
      _showSnack("Lengkapi NIS, Kode Kelas, dan Password!", Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    try {
      String cleanNis = _studentNisCtrl.text.trim();
      String cleanPass = _studentPassCtrl.text.trim();
      String cleanCode = _classCodeCtrl.text.trim().toUpperCase();

      var userData = await _dbService.loginUser(
        cleanNis,
        cleanPass,
        'siswa',
        classCode: cleanCode,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (userData != null) {
        await _saveSession(userData);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => StudentScreen(userData: userData)),
        );
      } else {
        _showSnack(
          "Login Gagal! Cek NIS, Password, atau Kode Kelas.",
          Colors.red,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack("Terjadi Kesalahan: $e", Colors.red);
    }
  }

  void _handleTeacherLogin() async {
    if (_teacherNipCtrl.text.isEmpty || _teacherPassCtrl.text.isEmpty) {
      _showSnack("NIP dan Password wajib diisi!", Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    try {
      String cleanNip = _teacherNipCtrl.text.trim();
      String cleanPass = _teacherPassCtrl.text.trim();

      var userData = await _dbService.loginUser(cleanNip, cleanPass, 'guru');

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (userData != null) {
        await _saveSession(userData);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => TeacherScreen(userData: userData)),
        );
      } else {
        _showSnack("Login Gagal! Cek NIP atau Password.", Colors.red);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack("Error: $e", Colors.red);
    }
  }

  void _handleSuperAdminLogin() {
    if (_adminCodeCtrl.text.trim() == "ADMIN@SMPN204") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SuperAdminScreen()),
      );
    } else {
      _showSnack("Kode Admin Salah!", Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/logo_white_bg.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "ABSENSI SMPN 204",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 30),

            // TAB BAR
            Container(
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(25),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(text: "SISWA"),
                  Tab(text: "GURU"),
                  Tab(text: "ADMIN"),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // FORM VIEW
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildStudentForm(),
                  _buildTeacherForm(),
                  _buildAdminForm(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        children: [
          const SizedBox(height: 5),
          _buildTextField(
            controller: _studentNisCtrl,
            label: "ID Number (NIS)",
            icon: Icons.badge_outlined,
            color: Colors.indigo,
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _classCodeCtrl,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [UpperCaseTextFormatter()],
            decoration: _inputDecoration(
              "Kode Wali Kelas",
              Icons.class_outlined,
              Colors.indigo,
            ),
          ),
          const SizedBox(height: 15),
          _buildTextField(
            controller: _studentPassCtrl,
            label: "Password",
            icon: Icons.lock_outline,
            color: Colors.indigo,
            isPassword: true,
          ),
          const SizedBox(height: 30),
          _buildButton("MASUK SISWA", Colors.indigo, _handleStudentLogin),
        ],
      ),
    );
  }

  Widget _buildTeacherForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        children: [
          _buildInfoBox(
            "Login Wali Kelas untuk kelola absensi.",
            Colors.purple,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _teacherNipCtrl,
            label: "ID Number (NIP)",
            icon: Icons.account_circle_outlined,
            color: Colors.purple,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            controller: _teacherPassCtrl,
            label: "Password",
            icon: Icons.lock_outline,
            color: Colors.purple,
            isPassword: true,
          ),
          const SizedBox(height: 30),
          _buildButton("MASUK GURU", Colors.purple, _handleTeacherLogin),
        ],
      ),
    );
  }

  Widget _buildAdminForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        children: [
          _buildInfoBox("Hanya untuk Admin pengelola sistem.", Colors.pink),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _adminCodeCtrl,
            label: "Kode Rahasia Admin",
            icon: Icons.vpn_key_outlined,
            color: Colors.pink,
            isPassword: true,
          ),
          const SizedBox(height: 30),
          _buildButton("MASUK ADMIN", Colors.pink, _handleSuperAdminLogin),
        ],
      ),
    );
  }

  // =================================================================
  // REUSABLE WIDGETS
  // =================================================================

  InputDecoration _inputDecoration(String label, IconData icon, Color color) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: color),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: color, width: 2),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    Color color = Colors.blue,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _isObscure : false,
      decoration: _inputDecoration(label, icon, color).copyWith(
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isObscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () => setState(() => _isObscure = !_isObscure),
              )
            : null,
      ),
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  Widget _buildInfoBox(String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
