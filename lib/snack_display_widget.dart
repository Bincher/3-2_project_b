// menu_display_widget.dart

import 'package:flutter/material.dart';

class MenuDisplayWidget extends StatelessWidget {
  final Map<String, dynamic> menuData;

  MenuDisplayWidget({required this.menuData});

  @override
  Widget build(BuildContext context) {
    String foodData;
    if (menuData.containsKey('error')) {
      foodData = menuData['error'];
    } else {
      foodData = menuData['menuLines'].join('\n');
    }

    Map<String, String> menuPrices = {
      "부대찌개": "7000",
      "치즈부대찌개": "7000",
      "제주흑돼지김치찌개": "7000",
      "제주흑돼지스팸김치찌개": "7500",
      "제주흑돼지참치김치찌개": "7500",
      "라면류": "2500~3500",
      "육회비빔밥": "7000",
      "가라아게덮밥": "6500",
      "돈가스류": "4000~4200",
    };

    List<String> selectedMenuPrices = [];

    for (String menu in menuPrices.keys) {
      if (foodData.contains(menu)) {
        selectedMenuPrices.add("$menu: ${menuPrices[menu]}원");
      }
    }

    return Container(
      width: double.infinity,
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
                foodData,
                style: TextStyle(fontSize: 16.0, color: Colors.black),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: selectedMenuPrices.map((item) => Text(item, style: TextStyle(fontSize: 16.0, color: Colors.black))).toList(),
            ),
          ),
        ],
      ),
    );
  }
}