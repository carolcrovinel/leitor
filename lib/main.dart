import 'package:flutter/material.dart';
import 'leitor_page.dart';

void main() {
  runApp(LeitorApp());
}

class LeitorApp extends StatefulWidget {
  @override
  _LeitorAppState createState() => _LeitorAppState();
}

class _LeitorAppState extends State<LeitorApp> {
  ThemeMode themeMode = ThemeMode.dark;

  void alternarTema() {
    setState(() {
      themeMode = themeMode == ThemeMode.dark
          ? ThemeMode.light
          : themeMode == ThemeMode.light
              ? ThemeMode.system
              : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leitor Palavra por Palavra',
      themeMode: themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: LeitorPage(onToggleTheme: alternarTema),
    );
  }
}
