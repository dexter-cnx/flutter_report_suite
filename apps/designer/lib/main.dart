
import 'package:flutter/material.dart';
import 'pages/designer_page.dart';

void main() {
  runApp(const DesignerApp());
}

class DesignerApp extends StatelessWidget {
  const DesignerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Report Designer - Web/Desktop/Mobile',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo, brightness: Brightness.light),
      home: const DesignerPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
