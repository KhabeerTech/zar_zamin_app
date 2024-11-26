import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zar_zamin_app/services/storage_service.dart';
import 'package:http/http.dart' as http;

class NewWorker extends StatefulWidget {
  const NewWorker({super.key});

  @override
  State<NewWorker> createState() => _NewWorkerState();
}

class _NewWorkerState extends State<NewWorker> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _jobController = TextEditingController();
  int? _startHour;
  int? _startMinute;
  int? _endHour;
  int? _endMinute;
  // File? _imageFile;
  // final ImagePicker _picker = ImagePicker();
  bool _nameHasError = false;
  bool _phoneHasError = false;
  bool _jobHasError = false;

  String? _formatTime(int? hour, int? minute) {
    if (hour == null || minute == null) return null;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  // Future<void> _pickImage() async {
  //   try {
  //     final XFile? pickedFile =
  //         await _picker.pickImage(source: ImageSource.gallery);
  //     if (pickedFile != null) {
  //       setState(() {
  //         _imageFile = File(pickedFile.path);
  //       });
  //     }
  //   } catch (e) {
  //     debugPrint('Rasm tanlashda xatolik: $e');
  //   }
  // }

  Future<void> _selectTime(bool isStartTime) async {
    int? selectedHour;
    int? selectedMinute;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            isStartTime ? 'Kelish vaqtini tanlang' : 'Ketish vaqtini tanlang',
            style: TextStyle(color: Color.fromRGBO(142, 92, 94, 1)),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Container(
                height: 200,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text(
                              'Soat',
                              style: TextStyle(
                                  color: Color.fromRGBO(142, 92, 94, 1)),
                            ),
                            Container(
                              height: 150,
                              width: 70,
                              child: ListWheelScrollView(
                                itemExtent: 50,
                                children: List.generate(24, (index) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: selectedHour == index
                                          ? Color.fromRGBO(142, 92, 94, 1)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      index.toString().padLeft(2, '0'),
                                      style: TextStyle(
                                        color: selectedHour == index
                                            ? Colors.white
                                            : Color.fromRGBO(142, 92, 94, 1),
                                        fontSize: 20,
                                      ),
                                    ),
                                  );
                                }),
                                onSelectedItemChanged: (index) {
                                  setState(() {
                                    selectedHour = index;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              'Daqiqa',
                              style: TextStyle(
                                  color: Color.fromRGBO(142, 92, 94, 1)),
                            ),
                            Container(
                              height: 150,
                              width: 70,
                              child: ListWheelScrollView(
                                itemExtent: 50,
                                children: List.generate(60, (index) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: selectedMinute == index
                                          ? Color.fromRGBO(142, 92, 94, 1)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      index.toString().padLeft(2, '0'),
                                      style: TextStyle(
                                        color: selectedMinute == index
                                            ? Colors.white
                                            : Color.fromRGBO(142, 92, 94, 1),
                                        fontSize: 20,
                                      ),
                                    ),
                                  );
                                }),
                                onSelectedItemChanged: (index) {
                                  setState(() {
                                    selectedMinute = index;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Bekor qilish',
                style: TextStyle(color: Color.fromRGBO(142, 92, 94, 1)),
              ),
            ),
            TextButton(
              onPressed: () {
                if (selectedHour != null && selectedMinute != null) {
                  setState(() {
                    if (isStartTime) {
                      _startHour = selectedHour;
                      _startMinute = selectedMinute;
                    } else {
                      _endHour = selectedHour;
                      _endMinute = selectedMinute;
                    }
                  });
                }
                Navigator.pop(context);
              },
              child: Text(
                'Tanlash',
                style: TextStyle(color: Color.fromRGBO(142, 92, 94, 1)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<File?> compressImage(File file) async {
    try {
      final String fileName = path.basename(file.path);
      debugPrint('Starting image compression for: $fileName');
      debugPrint('Original size: ${await file.length()} bytes');

      // Get the temporary directory
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
          dir.path, 'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Ensure the temporary directory exists
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Check if input file exists
      if (!await file.exists()) {
        debugPrint('Error: Input file does not exist at ${file.path}');
        return null;
      }

      debugPrint('Compressing image to: $targetPath');

      var result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 85, // Increased quality
        minWidth: 1024, // Increased width
        minHeight: 1024, // Increased height
        format: CompressFormat.jpeg,
        keepExif: true,
      );

      if (result != null) {
        final compressedSize = await result.length();
        final compressionRatio =
            (compressedSize / await file.length() * 100).toStringAsFixed(2);
        debugPrint('Compression successful:');
        debugPrint('- Original size: ${await file.length()} bytes');
        debugPrint('- Compressed size: $compressedSize bytes');
        debugPrint('- Compression ratio: $compressionRatio%');
        return File(result.path);
      } else {
        debugPrint('Compression failed: result is null');
        return file; // Return original file if compression fails
      }
    } catch (e, stackTrace) {
      debugPrint('Image compression error: $e');
      debugPrint('Stack trace: $stackTrace');
      return file; // Return original file if compression fails
    }
  }

  Future<void> _showCredentialsDialog() async {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    bool isLoading = false;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Kirish ma\'lumotlarini kiriting'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 10),
                            Text('Ma\'lumotlar yuklanmoqda...',
                                textAlign: TextAlign.center),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: [
                          TextField(
                            controller: usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: passwordController,
                            decoration: const InputDecoration(
                              labelText: 'Parol',
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Bekor qilish'),
                ),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (usernameController.text.isEmpty ||
                              passwordController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Iltimos, barcha maydonlarni to\'ldiring'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (passwordController.text.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Parol kamida 6 ta belgidan iborat bo\'lishi kerak'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setState(() {
                            isLoading = true;
                          });

                          try {
                            debugPrint('Username mavjudligini tekshirish...');
                            // Check if username exists
                            final usersSnapshot = await FirebaseFirestore
                                .instance
                                .collection('users')
                                .where('username',
                                    isEqualTo: usernameController.text.trim())
                                .get();

                            if (usersSnapshot.docs.isNotEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Bu username allaqachon mavjud'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              setState(() {
                                isLoading = false;
                              });
                              return;
                            }

                            debugPrint('Rasmni siqishni boshlash...');
                            // Compress image before upload
                            // final compressedImage =
                            //     await compressImage(_imageFile!);
                            // final imageToUpload =
                            //     compressedImage ?? _imageFile!;
                            // debugPrint('Rasm siqildi va yuklashga tayyor');

                            debugPrint(
                                'Supabase Storagega yuklash boshlandi...');
                            // final String timestamp = DateTime.now()
                            //     .millisecondsSinceEpoch
                            //     .toString();
                            // final String fileName =
                            //     '${timestamp}_${path.basename(imageToUpload.path)}';

                            // String? imageUrl =
                            //     await StorageService.uploadImage(imageToUpload);
                            // if (imageUrl == null) {
                            //   throw Exception(
                            //       'Rasmni yuklashda xatolik yuz berdi');
                            // }

                            debugPrint('Firestoreda ma\'lumotlarni saqlash...');
                            // Save to Firestore
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc()  // Avtomatik ID yaratish
                                .set({
                              'name': _nameController.text.trim(),
                              'phone': _phoneController.text.trim(),
                              'job': _jobController.text.trim(),
                              'username': usernameController.text.trim(),
                              'password': passwordController.text,
                              'startTime':
                                  _formatTime(_startHour, _startMinute),
                              'endTime': _formatTime(_endHour, _endMinute),
                              'role': 'hodim',
                              'createdAt': FieldValue.serverTimestamp(),
                              'isActive': true,
                            });
                            debugPrint('Ma\'lumotlar saqlandi');

                            if (mounted) {
                              Navigator.of(context).pop(); // Close dialog
                              Navigator.of(context)
                                  .pop(); // Return to previous screen
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Hodim muvaffaqiyatli qo\'shildi'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e, stackTrace) {
                            debugPrint('Xatolik yuz berdi: $e');
                            debugPrint('Stack trace: $stackTrace');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Xatolik yuz berdi: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              setState(() {
                                isLoading = false;
                              });
                            }
                          }
                        },
                  child: const Text('Saqlash'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _saveWorker() {
    if (_formKey.currentState!.validate()) {
      // if (_imageFile == null) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(
      //       content: Text('Iltimos, rasm tanlang'),
      //       backgroundColor: Colors.red,
      //     ),
      //   );
      //   return;
      // }
      if (_startHour == null ||
          _startMinute == null ||
          _endHour == null ||
          _endMinute == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Iltimos, ish vaqtini tanlang'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show credentials dialog
      _showCredentialsDialog();
    }
  }

  @override
  void initState() {
    super.initState();
    _phoneController.text = '+998';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _jobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double titleFontSize = size.width * 0.08;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 43, 0, 0),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: const Color.fromARGB(255, 43, 0, 0),
          leading: Padding(
            padding: const EdgeInsets.only(left: 5.0, top: 12.0),
            child: Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_sharp,
                  color: Color.fromARGB(255, 142, 92, 94),
                  size: 45,
                ),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          elevation: 0,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              const SizedBox(height: 2),
              // Text(
              //   'A   D   M   I   N',
              //   style: TextStyle(
              //     color: Colors.white,
              //     fontSize: titleFontSize,
              //     fontWeight: FontWeight.w900,
              //   ),
              // ),
              const SizedBox(height: 30),
              // GestureDetector(
              //   onTap: _pickImage,
              //   child: Container(
              //     width: 150,
              //     height: 150,
              //     decoration: BoxDecoration(
              //       color: Colors.grey[200],
              //       borderRadius: BorderRadius.circular(75),
              //       border: Border.all(
              //         color: const Color.fromARGB(255, 142, 92, 94),
              //         width: 2,
              //       ),
              //     ),
              //     child: _imageFile != null
              //         ? ClipRRect(
              //             borderRadius: BorderRadius.circular(73),
              //             child: Image.file(
              //               _imageFile!,
              //               width: 150,
              //               height: 150,
              //               fit: BoxFit.cover,
              //             ),
              //           )
              //         : const Icon(
              //             Icons.add_a_photo,
              //             size: 50,
              //             color: Color.fromARGB(255, 142, 92, 94),
              //           ),
              //   ),
              // ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                onChanged: (value) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  labelText: 'Ism Familiya',
                  labelStyle: TextStyle(
                    color: (_formKey.currentState?.validate() ?? false) &&
                            _nameController.text.isEmpty
                        ? Colors.red
                        : Colors.white,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: (_formKey.currentState?.validate() ?? false) &&
                              _nameController.text.isEmpty
                          ? Colors.red
                          : Colors.white,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: (_formKey.currentState?.validate() ?? false) &&
                              _nameController.text.isEmpty
                          ? Colors.red
                          : Colors.white,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  filled: true,
                  fillColor: Color.fromRGBO(142, 92, 94, 1),
                  errorStyle: TextStyle(color: Colors.red),
                ),
                style: TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Iltimos ismni kiriting';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                onChanged: (value) {
                  setState(() {});
                },
                inputFormatters: [
                  LengthLimitingTextInputFormatter(13),
                  FilteringTextInputFormatter.allow(RegExp(r'^\+?\d*$')),
                ],
                decoration: InputDecoration(
                  labelText: 'Telefon raqami',
                  labelStyle: TextStyle(
                    color: (_formKey.currentState?.validate() ?? false) &&
                            _phoneController.text.isEmpty
                        ? Colors.red
                        : Colors.white,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: (_formKey.currentState?.validate() ?? false) &&
                              _phoneController.text.isEmpty
                          ? Colors.red
                          : Colors.white,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: (_formKey.currentState?.validate() ?? false) &&
                              _phoneController.text.isEmpty
                          ? Colors.red
                          : Colors.white,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  filled: true,
                  fillColor: Color.fromRGBO(142, 92, 94, 1),
                  errorStyle: TextStyle(color: Colors.red),
                ),
                style: TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Iltimos telefon raqamni kiriting';
                  }
                  if (!value.startsWith('+')) {
                    return 'Telefon raqam + bilan boshlanishi kerak';
                  }
                  if (value.length < 13) {
                    return 'Telefon raqam to\'liq emas';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _jobController,
                onChanged: (value) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  labelText: 'Ishi',
                  labelStyle: TextStyle(
                    color: (_formKey.currentState?.validate() ?? false) &&
                            _jobController.text.isEmpty
                        ? Colors.red
                        : Colors.white,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: (_formKey.currentState?.validate() ?? false) &&
                              _jobController.text.isEmpty
                          ? Colors.red
                          : Colors.white,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: (_formKey.currentState?.validate() ?? false) &&
                              _jobController.text.isEmpty
                          ? Colors.red
                          : Colors.white,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  filled: true,
                  fillColor: Color.fromRGBO(142, 92, 94, 1),
                  errorStyle: TextStyle(color: Colors.red),
                ),
                style: TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Iltimos ishini kiriting';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                readOnly: true,
                onTap: () => _selectTime(true),
                decoration: InputDecoration(
                  labelText: _formatTime(_startHour, _startMinute) != null
                      ? 'Kelish: ${_formatTime(_startHour, _startMinute)}'
                      : 'Kelish vaqti',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Color.fromRGBO(142, 92, 94, 1)),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Color.fromRGBO(142, 92, 94, 1), width: 2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  filled: true,
                  fillColor: Color.fromRGBO(142, 92, 94, 1),
                  suffixIcon: Icon(Icons.access_time, color: Colors.white),
                ),
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              TextFormField(
                readOnly: true,
                onTap: () => _selectTime(false),
                decoration: InputDecoration(
                  labelText: _formatTime(_endHour, _endMinute) != null
                      ? 'Ketish: ${_formatTime(_endHour, _endMinute)}'
                      : 'Ketish vaqti',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Color.fromRGBO(142, 92, 94, 1)),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Color.fromRGBO(142, 92, 94, 1), width: 2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  filled: true,
                  fillColor: Color.fromRGBO(142, 92, 94, 1),
                  suffixIcon: Icon(Icons.access_time, color: Colors.white),
                ),
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 65,
                child: ElevatedButton.icon(
                  onPressed: _saveWorker,
                  icon: const Icon(Icons.person_add,
                      color: Colors.white, size: 32),
                  label: const Text(
                    'Qo\'shish',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(142, 92, 94, 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
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
