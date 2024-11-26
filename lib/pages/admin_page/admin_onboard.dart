import 'package:flutter/material.dart';
import 'package:zar_zamin_app/pages/admin_page/new_worker.dart';
import 'package:zar_zamin_app/pages/admin_page/qr_code_generate.dart';
import 'package:zar_zamin_app/pages/admin_page/status_page.dart';

class AdminOnboard extends StatelessWidget {
  const AdminOnboard({super.key});

  @override
  Widget build(BuildContext context) {
    // Ekran o'lchamlari
    final Size size = MediaQuery.of(context).size;
    final double screenHeight = size.height;
    final double screenWidth = size.width;

    // Responsive o'lchamlar
    final double titleFontSize = screenWidth * 0.08; // 8% of screen width
    final double buttonHeight = screenHeight * 0.08; // 7% of screen height
    final double buttonFontSize = screenWidth * 0.045; // 4.5% of screen width
    final double imageHeight = screenHeight * 0.45; // 45% of screen height
    final double topPadding = screenHeight * 0.05; // 5% of screen height
    final double buttonSpacing = screenHeight * 0.02; // 2% of screen height
    final double imageTopPadding = screenHeight * 0.03; // 3% of screen height
    final double buttonSectionTopPadding =
        screenHeight * 0.12; // 12% of screen height
    final double horizontalPadding = screenWidth * 0.05; // 5% of screen width

    // Tugma yaratish funksiyasi
    Widget _buildButton(BuildContext context, String text, VoidCallback onPressed) {
      return SizedBox(
        width: screenWidth * 0.8,
        height: buttonHeight,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(142, 92, 94, 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 43, 0, 0),
      body: Column(
        children: <Widget>[
          SizedBox(height: topPadding),
          Center(
            child: Text(
              'A  D  M  I  N',
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
          SizedBox(height: screenWidth * 0.2),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              children: [
                _buildButton(
                  context,
                  'Yangi QR kod',
                  () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: const Color.fromARGB(255, 43, 0, 0),
                          title: const Text(
                            'Yangi QR kod',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: const Text(
                            'Yangi QR kod yaratilsinmi?',
                            style: TextStyle(color: Colors.white),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context); // Oynani yopish
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const QrCodeGenerate(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Ha',
                                style: TextStyle(
                                  color: Color.fromRGBO(142, 92, 94, 1),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context); // Oynani yopish
                              },
                              child: const Text(
                                'Yo\'q',
                                style: TextStyle(
                                  color: Color.fromRGBO(142, 92, 94, 1),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                SizedBox(height: buttonSpacing),
                _buildButton(
                  context,
                  'Yangi Ishchi qo\'shish',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NewWorker(),
                      ),
                    );
                  },
                ),
                SizedBox(height: buttonSpacing),
                _buildButton(
                  context,
                  'STATUS',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StatusPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
