// snack_bar_menu.dart
import 'package:flutter/material.dart';
import 'snack_menu_fetcher.dart';
import 'snack_display_widget.dart'; // Update with the correct import path

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyListWidget3(selectedDate: DateTime.now()),
      theme: ThemeData(
          // your theme data here
          ),
    );
  }
}

class MyListWidget3 extends StatefulWidget {
  final DateTime selectedDate;

  const MyListWidget3({super.key, required this.selectedDate});

  @override
  State<StatefulWidget> createState() {
    return _MyListWidgetState();
  }
}

class _MyListWidgetState extends State<MyListWidget3> {
  Map<String, dynamic> menuData = {
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
      final data =
          await MenuFetcher.fetchMenuDataFromFirestore(widget.selectedDate);
      print("Fetched menu data: $data");
      setState(() {
        menuData = data;
      });
    } catch (e) {
      // 에러 발생 시 에러를 추가
      setState(() {
        menuData = {'error': '오류: $e'};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48.0),
        child: AppBar(
          title: const Text('분식당'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(
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
          const SizedBox(height: 20.0),
          const Divider(
            color: Colors.brown,
            thickness: 3.0,
          ),
          const SizedBox(height: 20.0),
          MenuDisplayWidget(menuData: menuData),
        ],
      ),
    );
  }
}
