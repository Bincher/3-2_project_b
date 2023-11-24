// staff_menu.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyListWidget2(selectedDate: DateTime.now()),
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          color: Colors.transparent,
          toolbarTextStyle: TextTheme(
            headline6: TextStyle(
              color: Colors.brown,
              fontSize: 10.0,
            ),
          ).bodyText2,
          titleTextStyle: TextTheme(
            headline6: TextStyle(
              color: Colors.brown,
              fontSize: 25.0,
            ),
          ).headline6,
        ),
      ),
    );
  }
}

class MenuFetcher {
  static Future<Map<String, dynamic>> fetchMenuDataFromFirestore(
      DateTime selectedDate, int time) async {
    try {
      final today = DateFormat('MM-dd').format(selectedDate);

      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('Menu')
              .where('selectedDate', isEqualTo: today)
              .where('selectedLocation', isEqualTo: 'staff') // 추가 조건
              .where('time', isEqualTo: time)
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

class MyListWidget2 extends StatefulWidget {
  final DateTime selectedDate;

  MyListWidget2({required this.selectedDate});

  @override
  State<StatefulWidget> createState() {
    return _MyListWidgetState();
  }
}

class _MyListWidgetState extends State<MyListWidget2> {
  Map<String, dynamic> menuDataLunch = {
    'menuLines': ["로딩 중..."],
    'selectedLocation': "snack",
    'time': "."
  };
  Map<String, dynamic> menuDataDinner = {
    'menuLines': ["로딩 중..."],
    'selectedLocation': "snack",
    'time': "."
  };

  @override
  void initState() {
    super.initState();
    fetchMenuData();
  }

  void fetchMenuData() async {
    try {
      final dataLunch =
          await MenuFetcher.fetchMenuDataFromFirestore(widget.selectedDate, 1);
      final dataDinner =
          await MenuFetcher.fetchMenuDataFromFirestore(widget.selectedDate, 2);
      print("Fetched menu data: $dataLunch");
      print("Fetched menu data: $dataDinner");
      setState(() {
        menuDataLunch = dataLunch;
        menuDataDinner = dataDinner;
      });
    } catch (e) {
      // 에러 발생 시 에러를 추가
      setState(() {
        menuDataLunch = {'error': '오류: $e'};
        menuDataDinner = {'error': '오류: $e'};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String foodDataLunch;
    String foodDataDinner;
    if (menuDataLunch.containsKey('error')) {
      foodDataLunch = menuDataLunch['error'];
    } else {
      foodDataLunch = menuDataLunch['menuLines'].join('\n');
    }
    if (menuDataDinner.containsKey('error')) {
      foodDataDinner = menuDataDinner['error'];
    } else {
      foodDataDinner = menuDataDinner['menuLines'].join('\n');
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(48.0),
        child: AppBar(
          title: Text('교직원식당'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                Icons.close,
                color: Colors.brown,
              ),
              onPressed: () {
                // 닫기 버튼을 눌렀을 때 수행할 동작
                // 여기에 원하는 동작을 추가할 수 있습니다.
              },
            )
          ],
          elevation: 0,
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 20.0),
          Divider(
            color: Colors.brown,
            thickness: 3.0,
          ),
          SizedBox(height: 20.0),
          Container(
            width: double.infinity,
            height: 250.0,
            margin: EdgeInsets.symmetric(horizontal: 10.0),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.brown,
                width: 2.0,
              ),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      foodDataLunch,
                      style: TextStyle(fontSize: 16.0, color: Colors.black),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "5500원",
                    style: TextStyle(fontSize: 16.0, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.0),
          Divider(
            color: Colors.brown,
            thickness: 3.0,
          ),
          SizedBox(height: 20.0),
          Container(
            width: double.infinity,
            height: 250.0,
            margin: EdgeInsets.symmetric(horizontal: 10.0),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.brown,
                width: 2.0,
              ),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      foodDataDinner,
                      style: TextStyle(fontSize: 16.0, color: Colors.black),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "5500원",
                    style: TextStyle(fontSize: 16.0, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
