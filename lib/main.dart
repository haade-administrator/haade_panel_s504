import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() {
  runApp(MaterialApp(
    title: 'MQTT Tablette',
    home: HomePage(),
    debugShowCheckedModeBanner: false,
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tablette MQTT',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: HomePage(),
    );
  }
}

