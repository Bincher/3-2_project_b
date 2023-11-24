// menu_fetcher.dart
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuFetcher {
  static Future<Map<String, dynamic>> fetchMenuDataFromFirestore(
      DateTime selectedDate) async {
    print("go");
    try {
      final today = DateFormat('MM-dd').format(selectedDate);

      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('Menu')
              .where('selectedDate', isEqualTo: today)
              .where('selectedLocation', isEqualTo: 'snack') // 추가 조건
              .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();

        return {
          'menuLines': List<String>.from(data['menuLines']),
          'selectedDate': data['selectedDate'],
          'selectedLocation': data['selectedLocation'],
          'time': data['time'],
        };
      } else {
        return {'error': '해당 날짜의 메뉴가 존재하지 않습니다.'};
      }
    } catch (e) {
      return {'error': '오류: $e'};
    }
  }
}
