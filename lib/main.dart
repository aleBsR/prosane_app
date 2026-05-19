import 'package:flutter/material.dart';

void main() {
  runApp(const ProsaneApp());
}

class ProsaneApp extends StatelessWidget {
  const ProsaneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PROSANE App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('PROSANE App - Inicio'),
        ),
      ),
    );
  }
}
