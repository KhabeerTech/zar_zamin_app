import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'history_page.dart';

class StatusPage extends StatelessWidget {
  const StatusPage({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder(
              future: _getAttendanceData(),
              builder: (context, AsyncSnapshot<List<String>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color.fromRGBO(142, 92, 94, 1),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Xatolik yuz berdi: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }

                final absentWorkers = snapshot.data!;

                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bugungi holat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (absentWorkers.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(142, 92, 94, 1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Bugun hamma xodimlar kelgan! 👏',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Kelmaganlar:',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: absentWorkers.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                        color: const Color.fromRGBO(142, 92, 94, 1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        absentWorkers[index],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistoryPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(142, 92, 94, 1),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Tarix',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<String>> _getAttendanceData() async {
    final now = DateTime.now();
    final dateStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // Barcha xodimlarni olish
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'hodim')
        .get();

    // Bugun kelgan xodimlarni olish
    final attendanceSnapshot = await FirebaseFirestore.instance
        .collection('kunlik_tarix')
        .doc(dateStr)
        .collection('records')
        .where('action', isEqualTo: '➡️KELDI')
        .get();

    // Kelgan xodimlar ID larini to'plash
    final Set<String> presentWorkers = {};
    for (var doc in attendanceSnapshot.docs) {
      presentWorkers.add(doc.data()['username']);
    }

    // Kelmagan xodimlarni aniqlash
    final List<String> absentWorkers = [];
    for (var doc in usersSnapshot.docs) {
      if (!presentWorkers.contains(doc.data()['username'])) {
        absentWorkers.add(doc.data()['name']);
      }
    }

    return absentWorkers;
  }
}
