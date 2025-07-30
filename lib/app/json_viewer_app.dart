import 'package:flutter/material.dart';
import '../pages/json_viewer_page.dart';

class JsonViewerApp extends StatelessWidget {
  final List<String> startupArgs;
  const JsonViewerApp({super.key, this.startupArgs = const []});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JSON Viewer',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: JsonViewerPage(startupArgs: startupArgs),
    );
  }
}