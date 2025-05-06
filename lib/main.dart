import 'package:flutter/material.dart';
import 'package:flutter_application_1/shopping_listPage.dart';

void main() async {
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shopping List',
      theme: ThemeData.dark(),
      home: const ShoppingListPage(),
    );
  }
}
