import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with AutomaticKeepAliveClientMixin {
  bool _isDisposed = false;
  Future<List<Map<String, dynamic>>>? _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _getHistoryData();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  Future<List<Map<String, dynamic>>> _getHistoryData() async {
    if (_isDisposed) return [];
    
    try {
      // Bugungi sana
      final now = DateTime.now();
      final todayStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      // Barcha kunlik_tarix hujjatlarini olish
      final datesSnapshot =
          await FirebaseFirestore.instance.collection('kunlik_tarix').get();

      if (_isDisposed) return [];

      // Barcha sanalarni to'plash (bugungi sana bilan)
      final Set<String> allDates = {todayStr};
      for (var doc in datesSnapshot.docs) {
        allDates.add(doc.id);
      }

      List<Map<String, dynamic>> historyData = [];

      // Har bir sana uchun
      for (var dateStr in allDates) {
        if (_isDisposed) return [];

        // Barcha xodimlarni olish
        final usersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'hodim')
            .get();

        if (_isDisposed) return [];

        // Shu kuni kelganlarni olish
        final attendanceSnapshot = await FirebaseFirestore.instance
            .collection('kunlik_tarix')
            .doc(dateStr)
            .collection('records')
            .where('action', isEqualTo: '➡️KELDI')
            .get();

        if (_isDisposed) return [];

        // Kelgan xodimlar ID larini to'plash
        final Set<String> presentWorkers = {};
        for (var doc in attendanceSnapshot.docs) {
          presentWorkers.add(doc.data()['username']);
        }

        // Kelmaganlarni aniqlash
        final List<String> absentWorkers = [];
        for (var doc in usersSnapshot.docs) {
          if (!presentWorkers.contains(doc.data()['username'])) {
            absentWorkers.add(doc.data()['name']);
          }
        }

        // Barcha sanalar uchun ma'lumotlarni qo'shamiz
        historyData.add({
          'date': dateStr,
          'absent': absentWorkers,
        });
      }

      // Sanalar bo'yicha tartiblash (eng yangi sana yuqorida)
      historyData.sort((a, b) => b['date'].compareTo(a['date']));

      return historyData;
    } catch (e) {
      if (_isDisposed) return [];
      rethrow;
    }
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return DateFormat('dd.MM.yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: const Color.fromRGBO(43, 0, 0, 1),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(43, 0, 0, 1),
        title: const Text(
          'Tarix',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyFuture,
        builder: (context, snapshot) {
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

          final historyData = snapshot.data!;

          if (historyData.isEmpty) {
            return const Center(
              child: Text(
                'Ma\'lumot topilmadi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: historyData.length,
            itemBuilder: (context, index) {
              final data = historyData[index];
              final date = _formatDate(data['date']);
              final absentList = data['absent'] as List<String>;

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(142, 92, 94, 1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (absentList.isEmpty)
                      const Text(
                        'Hamma kelgan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      )
                    else
                      ...absentList
                          .map((name) => Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ))
                          .toList(),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
