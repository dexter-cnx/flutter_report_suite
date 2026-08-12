import 'package:flutter/material.dart';

import 'design_system/designer_theme.dart';
import 'pages/template_gallery_page.dart';

void main() {
  runApp(const DesignerApp());
}

class DesignerApp extends StatelessWidget {
  const DesignerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Report Designer - Web/Desktop/Mobile',
      theme: DesignerTheme.light(),
      home: const TemplateGalleryPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
