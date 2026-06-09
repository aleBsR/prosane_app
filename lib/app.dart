import 'package:flutter/material.dart';

class ProsaneApp extends StatelessWidget {
  const ProsaneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PROSANE',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(body: Center(child: Text('PROSANE'))),
    );
  }
}
