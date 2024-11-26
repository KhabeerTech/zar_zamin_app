import 'package:flutter/material.dart';
import 'package:zar_zamin_app/pages/worker_page/worker_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zar_zamin_app/pages/worker_page/qr_scanner.dart';

class WorkerOnboard extends StatefulWidget {
  const WorkerOnboard({super.key});

  @override
  State<WorkerOnboard> createState() => _WorkerOnboardState();
}

class _WorkerOnboardState extends State<WorkerOnboard> {
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ekran o'lchamlari
    final Size size = MediaQuery.of(context).size;
    final double screenHeight = size.height;
    final double screenWidth = size.width;

    // Responsive o'lchamlar
    final double titleFontSize = screenWidth * 0.08;
    final double buttonHeight = screenHeight * 0.08;
    final double buttonFontSize = screenWidth * 0.045;
    final double imageHeight = screenHeight * 0.45;
    final double topPadding = screenHeight * 0.05;
    final double buttonSpacing = screenHeight * 0.02;
    final double imageTopPadding = screenHeight * 0.03;
    final double horizontalPadding = screenWidth * 0.05;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 43, 0, 0),
      body: Column(
        children: <Widget>[
          SizedBox(height: topPadding),
          Center(
            child: Text(
              'H O D I M',
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
          SizedBox(height: screenWidth * 0.4),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              children: [
                _buildButton(
                  context,
                  'Hodim',
                  () {
                    if (userId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WorkerProfile(userId: userId!),
                        ),
                      );
                    }
                  },
                ),
                SizedBox(height: buttonSpacing),
                _buildButton(
                  context,
                  'Keldi-ketdi',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QRScannerPage(),
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

  Widget _buildButton(
      BuildContext context, String text, VoidCallback onPressed) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      height: 65,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromRGBO(142, 92, 94, 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 27,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
