import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const JsonViewerApp());
}

class JsonViewerApp extends StatelessWidget {
  const JsonViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JSON Viewer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const JsonViewerPage(),
    );
  }
}

class JsonViewerPage extends StatefulWidget {
  const JsonViewerPage({super.key});

  @override
  State<JsonViewerPage> createState() => _JsonViewerPageState();
}

class _JsonViewerPageState extends State<JsonViewerPage> {
  dynamic jsonData;
  String filePath = '';
  Map<String, String> comments = {};
  
  String getFieldPath(dynamic data, String key, [List<String> path = const []]) {
    if (data is Map) {
      final newPath = List<String>.from(path)..add(key);
      return newPath.map((e) => '["$e"]').join('');
    }
    return '';
  }
  
  void _showAddCommentDialog(BuildContext context, String fieldKey) {
    final controller = TextEditingController(text: comments[fieldKey] ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add comment for $fieldKey'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter your comment'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                comments[fieldKey] = controller.text;
              });
              _saveComments();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _saveComments() async {
    if (filePath.isEmpty) return;
    
    final commentFile = File('${filePath}_comments.json');
    await commentFile.writeAsString(jsonEncode(comments));
  }
  
  Future<void> _loadComments() async {
    if (filePath.isEmpty) return;
    
    final commentFile = File('${filePath}_comments.json');
    if (await commentFile.exists()) {
      try {
        final contents = await commentFile.readAsString();
        setState(() {
          comments = Map<String, String>.from(jsonDecode(contents));
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading comments: $e')),
        );
      }
    }
  }

  Future<void> openFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    
    if (result != null) {
      filePath = result.files.single.path!;
      try {
        final file = File(filePath);
        final contents = await file.readAsString();
        setState(() {
          jsonData = jsonDecode(contents);
        });
        await _loadComments();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JSON Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: openFile,
            tooltip: 'Open JSON file',
          ),
        ],
      ),
      body: jsonData == null
          ? const Center(child: Text('No JSON file loaded'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                JsonEncoder.withIndent('  ').convert(jsonData),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
    );
  }
}
