import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class WorkerProfile extends StatefulWidget {
  final String userId;
  const WorkerProfile({Key? key, required this.userId}) : super(key: key);

  @override
  State<WorkerProfile> createState() => _WorkerProfileState();
}

class _WorkerProfileState extends State<WorkerProfile> {
  File? _imageFile;
  final _picker = ImagePicker();
  Map<String, dynamic>? userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (doc.exists) {
        setState(() {
          userData = doc.data();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Ma\'lumotlarni yuklashda xatolik: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        await _uploadImage();
      }
    } catch (e) {
      debugPrint('Rasm tanlashda xatolik: $e');
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('worker_images')
          .child('${widget.userId}.jpg');

      await ref.putFile(_imageFile!);
      final imageUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'imageUrl': imageUrl});

      await _loadUserData();
    } catch (e) {
      debugPrint('Rasmni yuklashda xatolik: $e');
    }
  }

  Widget _buildInfoContainer(String label, String value) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: 55,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(142, 92, 94, 1),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color.fromARGB(255, 43, 0, 0),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userData == null) {
      return const Scaffold(
        backgroundColor: Color.fromARGB(255, 43, 0, 0),
        body: Center(child: Text('Ma\'lumot topilmadi')),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 43, 0, 0),
      appBar: AppBar(
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: 55,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(142, 92, 94, 1),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  userData?['name'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // GestureDetector(
            //   onTap: _pickImage,
            //   child: Center(
            //     child: CircleAvatar(
            //       radius: 70,
            //       backgroundColor: const Color.fromRGBO(142, 92, 94, 1),
            //       backgroundImage: userData!['imageUrl'] != null
            //           ? NetworkImage(userData!['imageUrl'])
            //           : null,
            //       child: userData!['imageUrl'] == null
            //           ? const Icon(Icons.add_a_photo,
            //               size: 70, color: Colors.white)
            //           : null,
            //     ),
            //   ),
            // ),
            const SizedBox(height: 40),
            _buildInfoContainer('Telefon', userData!['phone'] ?? ''),
            _buildInfoContainer('Lavozim', userData!['job'] ?? ''),
            _buildInfoContainer('Ish vaqti',
                '${userData!['startTime'] ?? ''} - ${userData!['endTime'] ?? ''}'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
