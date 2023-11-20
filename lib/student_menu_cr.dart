// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:html/parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../firebase_options.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

class Content {
  List<String> menuLines;
  String selectedDate;
  String selectedLocation;
  String time;

  Content({
    required this.menuLines,
    required this.selectedDate,
    required this.selectedLocation,
    required this.time,
  });

  Content.fromJson(Map<String, dynamic> json)
      : menuLines = json['menuLines'],
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
    );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Remove the debug banner
      debugShowCheckedModeBanner: false,
      title: 'Kindacode.com',
      home: InputScreen(selectedDate: DateTime.now()),
    );
  }
}

class InputScreen extends StatefulWidget {
  final DateTime selectedDate;

  InputScreen({required this.selectedDate});

  @override
  InputScreenState createState() => InputScreenState();
}

class InputScreenState extends State<InputScreen> {
  
  List<String>? menuLines;
  String? selectedDate;
  String? selectedLocation;
  String? time;

  final CollectionReference _menu =
      FirebaseFirestore.instance.collection('Menu');

  Future getData() async {
      final response = await http.get(
        Uri.parse(
            'https://www.kumoh.ac.kr/ko/restaurant04.do?mode=menuList&srDt=${DateFormat('yyyy').format(widget.selectedDate)}-${DateFormat('MM').format(widget.selectedDate)}-${DateFormat('dd').format(widget.selectedDate)}'),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36',
        },
      );
      if (response.statusCode == 200) {
        final document = parse(response.body);
        final foodElements = document.querySelectorAll(
            ".menu-list-box table tbody tr:nth-child(1) td:nth-child(${widget.selectedDate.weekday * 2 - 1})");

        if (foodElements.isNotEmpty) {
          final foodMenu = foodElements[0].text;
          final modifiedFoodMenu = foodMenu.replaceAll(RegExp(r'\s{2,}'), '\n');
          List<String> foodMenuLines = modifiedFoodMenu.split('\n');
          foodMenuLines.removeWhere((element) => element.trim().isEmpty);
          menuLines = foodMenuLines;
          selectedDate =
              DateFormat('MM-dd').format(widget.selectedDate);
          selectedLocation = "snack";
          time = "none";
        }
        else{
          menuLines = ["오","류"];
          selectedDate =
              DateFormat('MM-dd').format(widget.selectedDate);
          selectedLocation = "snack";
          time = "none";
        }
        await _menu.add({
          'menuLines': menuLines,
          'selectedDate': selectedDate,
          'selectedLocation': selectedLocation,
          'time': time,
        });

      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Store, Storage Test'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.photo_album),
            onPressed: getData,
          ),
        ],
      ),
    );
  }
}