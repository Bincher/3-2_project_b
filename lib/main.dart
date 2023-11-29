import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fb/firebase_options.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'student_menu.dart';
import 'snack_bar_menu.dart';
import 'staff_menu.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase_options.dart';

class Content {
  List<String> menuLines;
  String selectedDate;
  String selectedLocation;
  int time;

  Content({
    required this.menuLines,
    required this.selectedDate,
    required this.selectedLocation,
    required this.time,
  });

  Content.fromJson(Map<String, dynamic> json)
    : menuLines = (json['menuLines'] as List<dynamic>).map((e) => e.toString()).toList(),
      selectedDate = json['selectedDate'],
      selectedLocation = json['selectedLocation'],
      time = json['time'];

  Map<String, dynamic> toJson() => {
        'menuLines': menuLines,
        'selectedDate': selectedDate,
        'selectedLocation': selectedLocation,
        'time' : time,
      };
}

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
    );
  
  try {
    _initLocalNotification();
    await scheduleWeeklyAlarm(); 
  } catch (e) {
    print('Error scheduling alarm: $e');
  }
  
  runApp(const MaterialApp(
    home: MyHomePage(title: '학식 캘린더'),
  ));
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required String title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool showButtons = false;
  DateTime? _selectedDate;
  String? formattedDate;
  int _currentIndex = 0;
  DateTime? selectedDate = DateTime.now();  //날짜 클릭하면 파란색 동그라미 쓸려고 추가함
  late SharedPreferences _prefs;
  void _toggleButtons(DateTime selectedDate, DateTime focusedDate) {
    setState(() {
      showButtons = true; // 학식, 교직, 분식 버튼이 표시하도록 변경
      _selectedDate = selectedDate;
    });
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('학식 캘린더')),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2010, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            focusedDay: DateTime.now(),
            selectedDayPredicate: (DateTime day) {
              return isSameDay(_selectedDate, day);
            },
            onDaySelected: onDaySelected,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 16.0),
            ),
            calendarStyle: const CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
          ),
          if (showButtons)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildButton('학식당', screenWidth * 0.25),
                const SizedBox(
                  width: 20,
                ),
                _buildButton('교직원', screenWidth * 0.25),
                const SizedBox(
                  width: 20,
                ),
                _buildButton('분식당', screenWidth * 0.25),
              ],
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;

            if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AlarmListPage(),
                ),
              );
            } else if (index == 2) { // 추가: 지도 아이콘을 누르면 지도 페이지로 이동
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LocationPage(),
                ),
              );
            }
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Image.asset('assets/calendar.png', width: 50.0, height: 50.0),
            label: '캘린더',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/alert.png', width: 50.0, height: 50.0),
            label: '알림',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/navi.png', width: 50.0, height: 50.0),
            label: '지도',
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String label, double width) {
    return SizedBox(
      
      width: width,
      child: ElevatedButton(
        onPressed: () {
          if (label == '학식당') {
            // '학식당' 버튼을 눌렀을 때 화면을 전환
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MyListWidget(selectedDate: _selectedDate!), // 학식당 메뉴 보기 기능
              ),
            );
          } else if (label == '분식당') {
            // '분식당' 버튼을 눌렀을 때 화면을 전환
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MyListWidget3(selectedDate: _selectedDate!), // 분식당 메뉴 보기 기능
              ),
            );
          }else if (label == '교직원') {
            // '교직원' 버튼을 눌렀을 때 화면을 전환
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MyListWidget2(selectedDate: _selectedDate!), // 교직원 메뉴 보기 기능
              ),
            );
          }
        },
        child: Text(label),
      ),
    );
  }
  
  void onDaySelected(DateTime selectedDate, DateTime focusedDate) {
    setState(() {
      _selectedDate = selectedDate;
      _toggleButtons(selectedDate, focusedDate);
    });
  }

  // 각 식당 페이지 연결 코드
  void showAlertDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }
}

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('식당 위치'),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              _buildLocationCard(
                "학생회관 지하 1층\n휴무일: 주말, 공휴일",
                'images/img_skyview.png',
              ),
              _buildLocationCard(
                "학식당,교직원식당 입구\n08:20~09:20/11:30~13:30/17:00~18:30",
                'images/img_cafeteria_out.jpg',
              ),
              _buildLocationCard(
                "분식당 입구\n11:00~14:00/16:00~18:30",
                'images/img_cafeteria_out1.jpg',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard(String locationName, String imagePath) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16/9,
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
            ),
          ),
          ListTile(
            title: Text(locationName),
          ),
        ],
      ),
    );
  }
}

class AlarmListPage extends StatefulWidget {
  const AlarmListPage({super.key});

  @override
  State<AlarmListPage> createState() => _AlarmListPageState();
}

// 데이터 저장은 크롬에선 X, 안드로이드등의 디바이스에서만 가능
class _AlarmListPageState extends State<AlarmListPage> {
  late SharedPreferences _prefs;
  final TextEditingController _alarmTextController = TextEditingController();

  List<Map<String, dynamic>> _foundAlarms = [];
  final List<Map<String, dynamic>> _alarmList = [];

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _loadAlarmData();
  }

  void _loadAlarmData() {
    final List<String>? alarmListJson = _prefs.getStringList('alarmList');
    
    if (alarmListJson != null) {
      // 저장된 알람 목록을 불러와서 업데이트합니다.
      print("_loadAlarmData:${alarmListJson}");
      setState(() {
        _alarmList.clear();
        _alarmList.addAll(alarmListJson.map((jsonString) => json.decode(jsonString)));
        _foundAlarms = List.from(_alarmList);
      });
    }else{
      print("_loadAlarmData:목록 없음");
    }
  }

  void _runFilter(String enteredKeyword) {
    setState(() {
      if (enteredKeyword.isEmpty) {
        _foundAlarms = List.from(_alarmList);
      } else {
        _foundAlarms = _alarmList
            .where((menu) => menu["menu"].toLowerCase().contains(enteredKeyword.toLowerCase()))
            .toList();
      }
    });
  }

  void _addAlarm() {
    final String newAlarm = _alarmTextController.text;
    if (newAlarm.isNotEmpty) {
      final int newId = _alarmList.length + 1;
      final Map<String, dynamic> newAlarmItem = {"id": newId, "menu": newAlarm};
      setState(() {
        _alarmList.add(newAlarmItem);
        _foundAlarms.add(newAlarmItem);
        _alarmTextController.clear();
      });
      print("_addAlarm : ${newAlarmItem}");

      // 추가된 알람을 저장하는 기능 추가
      List<String>? alarmListJson = _prefs.getStringList('alarmList');
      print("_addAlarm : 저장전 $alarmListJson");
      if (alarmListJson == null) {
        // 저장된 알람 목록이 없으면 새로 생성합니다.
        alarmListJson = [];
      }

      // 새로 추가된 알람을 JSON 형식으로 변환하여 목록에 추가합니다.
      final String newAlarmJson = json.encode(newAlarmItem);
      alarmListJson.add(newAlarmJson);

      print("_addAlarm : 저장후 $alarmListJson");
      // 변경된 알람 목록을 다시 SharedPreferences에 저장합니다.
      _prefs.setStringList('alarmList', alarmListJson);

      _loadAlarmData();
    }
  }

  void _deleteAlarm(Map<String, dynamic> alarm) {
    setState(() {
      _foundAlarms.remove(alarm);
      _alarmList.remove(alarm);
    });

    // 삭제된 알람을 저장하는 기능 추가

    List<String>? alarmListJson = _prefs.getStringList('alarmList');

    if (alarmListJson != null) {
      // 삭제할 알람을 JSON 형식으로 변환하여 목록에서 제거합니다.
      final String alarmJson = json.encode(alarm);
      alarmListJson.remove(alarmJson);

      // 변경된 알람 목록을 다시 SharedPreferences에 저장합니다.
      _prefs.setStringList('alarmList', alarmListJson);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알람 설정'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            const Text(
              "선호 메뉴 추가",
              style: TextStyle(
                fontSize: 22,
              ),
            ),
            TextField(
              controller: _alarmTextController,
              decoration: InputDecoration(
                labelText: '선호 메뉴',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addAlarm,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              onChanged: (value) => _runFilter(value),
              decoration: const InputDecoration(
                labelText: '검색',
                suffixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "<아래 메뉴가 있는 날에는 알람이 전송됩니다>",
              style: TextStyle(
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _foundAlarms.isNotEmpty
                  ? ListView.builder(
                itemCount: _foundAlarms.length,
                itemBuilder: (context, index) {
                  final alarm = _foundAlarms[index];
                  return Card(
                    key: ValueKey(alarm["id"]),
                    color: Colors.blue[100],
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: ListTile(
                      title: Text(
                        alarm['menu'],
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _foundAlarms.remove(alarm);
                            _alarmList.remove(alarm);
                            _deleteAlarm(alarm);
                          });
                        },
                      ),
                    ),
                  );
                },
              )
                  : const Text(
                '추가한 메뉴가 없어요 :(\n좋아하는 메뉴를 추가해주세요',
                style: TextStyle(
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

tz.TZDateTime _timeZoneSetting({
    required int hour,
    required int minute,
    required int day,
    required int month,
    required int year,
  }) {
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, year, month, day, hour, minute);
    return scheduledDate;
  }  

Future<void> _initLocalNotification() async {
    FlutterLocalNotificationsPlugin _localNotification =
        FlutterLocalNotificationsPlugin();
    AndroidInitializationSettings initSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    DarwinInitializationSettings initSettingsIOS =
        const DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );
    InitializationSettings initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );
    await _localNotification.initialize(
      initSettings,
    );
  }

NotificationDetails _details = const NotificationDetails(
      android: AndroidNotificationDetails('alarm 1', '1번 푸시'),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );  

Future<void> scheduleWeeklyAlarm() async {
  FlutterLocalNotificationsPlugin _localNotification =
      FlutterLocalNotificationsPlugin();

  // 현재 날짜 및 시간 가져오기
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
  tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  for (int i = 0; i <= 5 - now.weekday; i++) {
    int dayToAdd = i;

  int nextMonth = now.month;
  int nextYear = now.year;

  // 달이 넘어가거나 년도가 바뀌는 경우에 대한 처리
  if (now.day + i > DateTime(now.year, now.month + 1, 0).day) {
    dayToAdd = dayToAdd - DateTime(now.year, now.month + 1, 0).day;
    nextMonth += 1;
    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear += 1;
    }
  }

  int nextDay = now.day + dayToAdd;

  tz.TZDateTime scheduledDate = tz.TZDateTime(
    tz.local,
    nextYear,
    nextMonth,
    nextDay,
    10,
    50,
  );

  print("${scheduledDate.year}년/${scheduledDate.month}월/${scheduledDate.day}일/10:50 에 알람이 설정됩니다.");

    // 해당 일자에 울릴 알람 예약
    await _localNotification.zonedSchedule(
      i, // 고유한 ID로 일자를 사용
      '이번주 알림',
      await getMenuNotificationMessage(scheduledDate), // 알림 내용 생성
      scheduledDate,
      _details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidAllowWhileIdle: true,
    );
  }
}

Future<String> getMenuNotificationMessage(tz.TZDateTime scheduledDate) async {
  List<Content> menuList = await getMenuDataFromFirestore(scheduledDate);

  // "제육"을 포함하고 있는지 여부 확인
  bool isPorkIncluded = menuList.any((content) =>
      content.menuLines.any((line) => line.toLowerCase().contains('제육')));

  // 알림 내용 생성
  String message = isPorkIncluded ? '포함' : '불포함';

  return '이번주 메뉴에 "제육"이 $message되어 있습니다.';
}

Future<List<Content>> getMenuDataFromFirestore(tz.TZDateTime scheduledDate) async {
  var firestore = FirebaseFirestore.instance;

  var query = firestore.collection('Menu')
      .where('selectedDate', isEqualTo: DateFormat('MM-dd').format(scheduledDate));

  var snapshot = await query.get();

  List<Content> menuList = snapshot.docs
      .map((doc) => Content.fromJson(doc.data() as Map<String, dynamic>))
      .toList();

  return menuList;
}