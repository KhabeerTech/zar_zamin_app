import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zar_zamin_app/pages/admin_page/admin_onboard.dart';
import 'package:zar_zamin_app/pages/worker_page/worker_onboard.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _checkAndCreateAdmin() async {
    try {
      // Adminlar sonini tekshirish
      final adminCount = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      if (adminCount.docs.isEmpty) {
        debugPrint('Admin foydalanuvchisi topilmadi. Yangi admin yaratilmoqda...');

        // Yangi admin yaratish
        await FirebaseFirestore.instance.collection('users').add({
          'username': 'zar_zamin_admin',
          'password': 'ZarZamin2024@',
          'role': 'admin',
          'createdAt': FieldValue.serverTimestamp(),
          'fullName': 'Admin',
          'isActive': true,
        });
        debugPrint('Yangi admin yaratildi');
      }
    } catch (e) {
      debugPrint('Admin yaratishda xatolik: $e');
    }
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Foydalanuvchini username va parol bo'yicha qidirish
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: _usernameController.text.trim())
          .where('password', isEqualTo: _passwordController.text)
          .get();

      if (userDoc.docs.isNotEmpty) {
        final userData = userDoc.docs.first.data();
        final userId = userDoc.docs.first.id;
        debugPrint('Foydalanuvchi ma\'lumotlari: $userData');
        
        // UserId ni saqlash
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', userId);
        
        // Rolga qarab yo'naltirish
        if (userData['role'] == 'admin') {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminOnboard()),
            );
          }
        } else if (userData['role'] == 'hodim') {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const WorkerOnboard()),
            );
          }
        } else {
          setState(() {
            _errorMessage = 'Noma\'lum foydalanuvchi roli';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Username yoki parol noto\'g\'ri';
        });
      }
    } catch (e) {
      debugPrint('Login xatolik: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Tizimda xatolik yuz berdi';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Admin foydalanuvchisini yaratish
    _checkAndCreateAdmin();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double screenHeight = size.height;
    final double screenWidth = size.width;

    final double titleFontSize = screenWidth * 0.08;
    final double buttonHeight = screenHeight * 0.08;
    final double buttonFontSize = screenWidth * 0.045;
    final double imageHeight = screenHeight * 0.35;
    final double topPadding = screenHeight * 0.05;
    final double buttonSpacing = screenHeight * 0.02;
    final double imageTopPadding = screenHeight * 0.03;
    final double horizontalPadding = screenWidth * 0.05;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 43, 0, 0),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              SizedBox(height: topPadding),
              Center(
                child: Text(
                  'Z A R   Z A M I N',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(height: imageTopPadding),
              Center(
                child: Image.asset(
                  'assets/images/zar-zamin.png',
                  height: imageHeight,
                ),
              ),
              SizedBox(height: screenHeight * 0.05),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Username',
                        labelStyle: TextStyle(
                          color: (_formKey.currentState?.validate() ?? false) &&
                                  _usernameController.text.isEmpty
                              ? Colors.red
                              : Colors.white,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color:
                                (_formKey.currentState?.validate() ?? false) &&
                                        _usernameController.text.isEmpty
                                    ? Colors.red
                                    : Colors.white,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color:
                                (_formKey.currentState?.validate() ?? false) &&
                                        _usernameController.text.isEmpty
                                    ? Colors.red
                                    : Colors.white,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.red),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: Colors.red, width: 2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        filled: true,
                        fillColor: const Color.fromRGBO(142, 92, 94, 1),
                        errorStyle: const TextStyle(color: Colors.red),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Iltimos username kiriting';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: buttonSpacing),
                    TextFormField(
                      controller: _passwordController,
                      style: const TextStyle(color: Colors.white),
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(
                          color: (_formKey.currentState?.validate() ?? false) &&
                                  _passwordController.text.isEmpty
                              ? Colors.red
                              : Colors.white,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color:
                                (_formKey.currentState?.validate() ?? false) &&
                                        _passwordController.text.isEmpty
                                    ? Colors.red
                                    : Colors.white,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color:
                                (_formKey.currentState?.validate() ?? false) &&
                                        _passwordController.text.isEmpty
                                    ? Colors.red
                                    : Colors.white,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.red),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: Colors.red, width: 2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        filled: true,
                        fillColor: const Color.fromRGBO(142, 92, 94, 1),
                        errorStyle: const TextStyle(color: Colors.red),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Iltimos parolni kiriting';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: buttonSpacing * 2),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: buttonHeight,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : Text(
                                'Kirish',
                                style: TextStyle(
                                  fontSize: buttonFontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
