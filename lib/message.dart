import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fb/firebase_options.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
    );
  String? _fcmToken = await FirebaseMessaging.instance.getToken();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  @override
  void initState() {
    super.initState();

    // FCM에서 푸시 알람 수신을 처리하는 핸들러 등록
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      
      print("onMessage: $message");
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // 앱이 백그라운드에서 실행 중이거나 종료된 상태에서 푸시 알람을 터치하여 앱을 열 때 실행되는 코드
      print("onMessageOpenedApp: $message");
    });

    // 앱이 꺼져 있을 때 푸시 알람을 터치하여 앱을 열 때 실행되는 코드
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your App'),
      ),
      body: Center(
        child: Text('Welcome to your app!'),
      ),
    );
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    FirebaseMessaging.instance.deleteToken();
    var fcmToken = await FirebaseMessaging.instance.getToken(vapidKey: "BOeBIiobFfeKVQ3t6ReVyADtG1fotxDYBKPGStWyWFupULdt5w_RloOk56x3z4NqTLoHkM9DGC84rxf4KXVDj_U");
  });
  print("Handling a background message: ${message.messageId}");
}

var channel = const AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // name
  description: 'This channel is used for important notifications.', // description
  importance: Importance.high,
);

