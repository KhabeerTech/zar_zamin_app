import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  MobileScannerController cameraController = MobileScannerController();
  bool isScanned = false;
  bool isProcessing = false;
  bool isScanningEnabled = false;
  String selectedAction = '';

  final String botToken = '7848900150:AAHzUEk2HyE_ie60v4S-Q8Rf0domag3Ngws';
  final String chatId =
      '-1002443385982'; // Telegram kanal/guruh ID sini kiriting

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> sendToTelegram(String message) async {
    final url = 'https://api.telegram.org/bot$botToken/sendMessage';
    final response = await http.get(
      Uri.parse('$url?chat_id=$chatId&text=${Uri.encodeComponent(message)}'),
    );

    if (response.statusCode != 200) {
      debugPrint('Telegram xabar yuborishda xatolik: ${response.body}');
    }
  }

  Future<void> _processQRData(String qrData) async {
    if (isProcessing || !isScanningEnabled) return;
    setState(() {
      isProcessing = true;
    });

    try {
      debugPrint('Scanning QR code: $qrData');

      // QR kodlar kolleksiyasidan ma'lumotlarini olish
      final qrSnapshot = await FirebaseFirestore.instance
          .collection('qr_codes')
          .where('code', isEqualTo: qrData)
          .get();

      debugPrint('Found QR codes: ${qrSnapshot.docs.length}');

      if (qrSnapshot.docs.isEmpty) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color.fromARGB(255, 43, 0, 0),
              title: const Text(
                'Xatolik',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                'QR kod topilmadi',
                style: TextStyle(color: Colors.white),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      isScanned = false;
                      isProcessing = false;
                    });
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: Color.fromRGBO(142, 92, 94, 1),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return;
      }

      final qrDoc = qrSnapshot.docs.first.data();
      debugPrint('QR code data: $qrDoc');

      // QR kod faol ekanligini tekshirish
      if (!qrDoc['isActive']) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color.fromARGB(255, 43, 0, 0),
              title: const Text(
                'Xatolik',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                'QR kod faol emas',
                style: TextStyle(color: Colors.white),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      isScanned = false;
                      isProcessing = false;
                    });
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: Color.fromRGBO(142, 92, 94, 1),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return;
      }

      // QR kod vaqtini tekshirish
      final now = DateTime.now();
      final createdAt = (qrDoc['createdAt'] as Timestamp).toDate();
      final expiryTime = (qrDoc['expiryTime'] as Timestamp).toDate();

      if (now.isAfter(expiryTime)) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color.fromARGB(255, 43, 0, 0),
              title: const Text(
                'Xatolik',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                'QR kod muddati tugagan',
                style: TextStyle(color: Colors.white),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      isScanned = false;
                      isProcessing = false;
                    });
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: Color.fromRGBO(142, 92, 94, 1),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Hodim ma'lumotlarini olish
      final workerSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: qrDoc['username'])
          .where('role', isEqualTo: 'hodim')
          .limit(1)
          .get();

      debugPrint('Worker docs found: ${workerSnapshot.docs.length}');

      if (workerSnapshot.docs.isEmpty) {
        throw Exception('Hodim ma\'lumotlari topilmadi');
      }

      final workerDoc = workerSnapshot.docs.first;
      final workerData = workerDoc.data();
      debugPrint('Worker data: $workerData');

      final dateStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final timeStr =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      // Xodimning bugungi yozuvini topish yoki yangi yaratish
      final docRef = FirebaseFirestore.instance
          .collection('kunlik_tarix')
          .doc(dateStr)
          .collection('records')
          .doc(workerData['username']);

      final docSnapshot = await docRef.get();

      if (selectedAction == '➡️KELDI') {
        // Kelgan vaqtni yozish
        if (docSnapshot.exists) {
          // Agar oldin kelgan bo'lsa, yangilash
          await docRef.update({
            'kelganVaqt': timeStr,
            'kelganTimestamp': now,
          });
        } else {
          // Yangi yozuv yaratish
          await docRef.set({
            'username': workerData['username'],
            'name': workerData['name'],
            'phone': workerData['phone'],
            'job': workerData['job'],
            'kelganVaqt': timeStr,
            'kelganTimestamp': now,
          });
        }

        // Telegram xabarni tayyorlash
        String message = '👤Ismi: ${workerData['name']}\n';
        message += '💼Lavozimi: ${workerData['job']}\n';
        message += '➡️Keldi: $timeStr\n';
        message += '📞Telefon raqami: ${workerData['phone']}';

        // Telegram botga yuborish
        await sendToTelegram(message);
      } else if (selectedAction == '⬅️KETDI') {
        if (!docSnapshot.exists) {
          throw Exception('Bugun kelgan vaqti topilmadi');
        }

        final data = docSnapshot.data()!;
        final kelganVaqt = data['kelganVaqt'];

        // Ketgan vaqtni yozish
        await docRef.update({
          'ketganVaqt': timeStr,
          'ketganTimestamp': now,
        });

        // Telegram xabarni tayyorlash
        String message = '👤Ismi: ${workerData['name']}\n';
        message += '💼Lavozimi: ${workerData['job']}\n';
        message += '➡️Keldi: $kelganVaqt\n';
        message += '⬅️Ketdi: $timeStr\n';
        message += '📞Telefon raqami: ${workerData['phone']}';

        // Telegram botga yuborish
        await sendToTelegram(message);
      }

      // QR kod tasdiqlandi
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color.fromARGB(255, 43, 0, 0),
            title: const Text(
              'Muvaffaqiyatli',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Xodim ${selectedAction.toLowerCase()}',
              style: const TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    isScanned = false;
                    isProcessing = false;
                    isScanningEnabled = false;
                    selectedAction = '';
                  });
                },
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Color.fromRGBO(142, 92, 94, 1),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Xatolik: $e');
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color.fromARGB(255, 43, 0, 0),
            title: const Text(
              'Xatolik',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Xatolik yuz berdi: $e',
              style: const TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    isScanned = false;
                    isProcessing = false;
                    isScanningEnabled = false;
                    selectedAction = '';
                  });
                },
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Color.fromRGBO(142, 92, 94, 1),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 43, 0, 0),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 43, 0, 0),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'QR Skanerlash',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'QR kodni skanerlang',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 30),
          if (!isScanningEnabled)
            const Expanded(
              child: Center(
                child: Text(
                  'Davom etish uchun "Keldi" yoki "Ketdi" tugmasini bosing',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          if (isScanningEnabled)
            Expanded(
              child: MobileScanner(
                controller: cameraController,
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty && !isScanned) {
                    final String qrData = barcodes.first.rawValue ?? '';
                    setState(() {
                      isScanned = true;
                    });
                    _processQRData(qrData);
                  }
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedAction = '➡️KELDI';
                      isScanningEnabled = true;
                      isScanned = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedAction == '➡️KELDI'
                        ? const Color.fromRGBO(142, 92, 94, 1)
                        : const Color.fromARGB(255, 43, 0, 0),
                    minimumSize: const Size(150, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Keldim',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedAction = '⬅️KETDI';
                      isScanningEnabled = true;
                      isScanned = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedAction == '⬅️KETDI'
                        ? const Color.fromRGBO(142, 92, 94, 1)
                        : const Color.fromARGB(255, 43, 0, 0),
                    minimumSize: const Size(150, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'KETDI',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
