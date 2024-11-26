import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:cross_file/cross_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class QrCodeGenerate extends StatefulWidget {
  const QrCodeGenerate({super.key});

  @override
  State<QrCodeGenerate> createState() => _QrCodeGenerateState();
}

class _QrCodeGenerateState extends State<QrCodeGenerate> {
  String qrData = "Default QR Code";
  final Random _random = Random();
  final GlobalKey _qrKey = GlobalKey();
  DateTime? expiryTime;
  String? qrDocId;
  Timer? _timer;
  Duration? timeLeft;

  String _generateRandomString() {
    const chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    return String.fromCharCodes(Iterable.generate(
        35, (_) => chars.codeUnitAt(_random.nextInt(chars.length))));
  }

  @override
  void initState() {
    super.initState();
    _checkAndLoadActiveQR();
  }

  Future<void> _checkAndLoadActiveQR() async {
    try {
      // Faol QR kodlarni olish
      final snapshot = await FirebaseFirestore.instance
          .collection('qr_codes')
          .where('isActive', isEqualTo: true)
          .get();

      final docs = snapshot.docs;
      
      // Yaratilgan vaqti bo'yicha tartiblash
      docs.sort((a, b) {
        final aTime = (a.data()['createdAt'] as Timestamp).toDate();
        final bTime = (b.data()['createdAt'] as Timestamp).toDate();
        return bTime.compareTo(aTime); // Eng yangi birinchi
      });

      if (docs.length >= 2) {
        // 2 ta yoki undan ko'p faol QR kod bor
        final latestQR = docs.first;
        setState(() {
          qrData = latestQR.data()['code'];
          expiryTime = (latestQR.data()['expiryTime'] as Timestamp).toDate();
          qrDocId = latestQR.id;
          timeLeft = expiryTime?.difference(DateTime.now());
        });
        _startTimer();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bir kunda faqat 2 ta QR kod yaratish mumkin'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Yangi QR kod yaratish mumkin
        _generateAndSaveQR();
      }
    } catch (e) {
      debugPrint('QR kodlarni tekshirishda xatolik: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateAndSaveQR() async {
    qrData = _generateRandomString();
    final expiryDateTime = DateTime.now().add(const Duration(hours: 24));

    final docRef = await FirebaseFirestore.instance.collection('qr_codes').add({
      'code': qrData,
      'createdAt': FieldValue.serverTimestamp(),
      'expiryTime': expiryDateTime,
      'isActive': true,
    });

    setState(() {
      expiryTime = expiryDateTime;
      qrDocId = docRef.id;
      timeLeft = const Duration(hours: 24);
    });

    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (expiryTime == null) return;

      final now = DateTime.now();
      if (now.isAfter(expiryTime!)) {
        _deactivateQR();
        timer.cancel();
        return;
      }

      setState(() {
        timeLeft = expiryTime!.difference(now);
      });
    });
  }

  Future<void> _deactivateQR() async {
    if (qrDocId != null) {
      await FirebaseFirestore.instance
          .collection('qr_codes')
          .doc(qrDocId)
          .update({'isActive': false});
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _shareQR() async {
    try {
      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF fayl tayyorlanmoqda...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Get QR code image
      debugPrint('QR kod rasmini olish...');
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('QR kod topilmadi');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('QR kodni rasmga aylantirish muvaffaqiyatsiz');
      }
      debugPrint('QR kod rasmi olindi');

      // Create PDF document
      debugPrint('PDF yaratish...');
      final document = PdfDocument();
      final page = document.pages.add();

      // Draw QR code
      final imageBytes = byteData.buffer.asUint8List();
      final qrImage = PdfBitmap(imageBytes);

      final pageSize = page.getClientSize();
      final qrSize = pageSize.width * 0.85;
      final qrX = (pageSize.width - qrSize) / 2;
      final qrY = (pageSize.height - qrSize) / 2;

      // Draw QR code with border
      page.graphics.drawRectangle(
        pen: PdfPen(PdfColor(0, 0, 0), width: 2),
        bounds: Rect.fromLTWH(qrX - 15, qrY - 15, qrSize + 30, qrSize + 30),
      );

      page.graphics.drawImage(
        qrImage,
        Rect.fromLTWH(qrX, qrY, qrSize, qrSize),
      );

      // Add title
      final titleFont = PdfStandardFont(PdfFontFamily.helvetica, 54);
      page.graphics.drawString(
        '',
        titleFont,
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );

      // Add code text
      final codeFont = PdfStandardFont(PdfFontFamily.helvetica, 16);
      page.graphics.drawString(
        '',
        codeFont,
        bounds: Rect.fromLTWH(0, pageSize.height - 100, pageSize.width, 50),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      debugPrint('PDF yaratildi');

      // Save PDF to temporary file
      debugPrint('PDF faylni saqlash...');
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/qr_code.pdf';
      final file = File(tempPath);

      // Save and dispose
      final bytes = await document.save();
      await file.writeAsBytes(bytes);
      document.dispose();
      debugPrint('PDF fayl saqlandi: $tempPath');

      // Check if file exists
      if (!await file.exists()) {
        throw Exception('PDF fayl yaratilmadi');
      }
      debugPrint('PDF fayl mavjud');

      if (!context.mounted) return;

      // Share PDF
      debugPrint('PDF faylni ulashish...');
      try {
        await Share.shareFiles(
          [tempPath],
          text: 'QR Kod',
          mimeTypes: ['application/pdf'],
        );
        debugPrint('PDF fayl ulashildi');
      } catch (shareError) {
        debugPrint('PDF faylni ulashishda xatolik: $shareError');
        throw Exception('PDF faylni ulashib bo\'lmadi: $shareError');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF muvaffaqiyatli ulashildi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('XATOLIK: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double screenHeight = size.height;
    final double screenWidth = size.width;
    final double titleFontSize = screenWidth * 0.08;

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
              decoration: BoxDecoration(
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 5),
            Text(
              'A   D   M   I   N',
              style: TextStyle(
                color: Colors.white,
                fontSize: titleFontSize,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: RepaintBoundary(
                  key: _qrKey,
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: size.width * 0.7,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ),
            const Spacer(),
            if (timeLeft != null) ...[
              Text(
                'Qolgan vaqt: ${_formatDuration(timeLeft)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
            ],
            SizedBox(
              width: double.infinity,
              height: 65,
              child: ElevatedButton.icon(
                onPressed: _shareQR,
                icon: const Icon(Icons.share, color: Colors.white, size: 32),
                label: Text(
                  'Share QR Code',
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
