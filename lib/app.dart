import 'package:flutter/material.dart';
import 'package:prosane_app/core/theme/app_theme.dart';

class ProsaneApp extends StatelessWidget {
  const ProsaneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PROSANE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const Scaffold(body: Center(child: Text('PROSANE'))),
    );
  }
}
