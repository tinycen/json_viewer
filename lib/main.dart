import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';

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
  Set<String> selectedPaths = {};

  String _buildYamlPath(List<String> path) {
    return path.join('.');
  }

  Future<void> _showAddCommentDialog(BuildContext context, String fieldKey) async {
    final controller = TextEditingController(text: comments[fieldKey] ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('为 $fieldKey 添加注释'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '输入你的注释'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() {
        comments[fieldKey] = result;
      });
      await _saveComments();
    }
  }

  Future<void> _saveComments() async {
    if (filePath.isEmpty) return;
    final commentFile = File('${filePath}_comments.yaml');
    final writer = YAMLWriter();
    final yamlStr = writer.write(comments);
    await commentFile.writeAsString(yamlStr);
  }

  Future<void> _loadComments() async {
    if (filePath.isEmpty) return;
    final commentFile = File('${filePath}_comments.yaml');
    if (await commentFile.exists()) {
      try {
        final contents = await commentFile.readAsString();
        final yamlMap = loadYaml(contents);
        setState(() {
          comments = Map<String, String>.from(yamlMap);
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('注释加载失败: $e')),
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
          selectedPaths.clear();
        });
        await _loadComments();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
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
            tooltip: '打开 JSON 文件',
          ),
        ],
      ),
      body: jsonData == null
          ? const Center(child: Text('未加载 JSON 文件'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: JsonTreeView(
                data: jsonData,
                path: [],
                comments: comments,
                selectedPaths: selectedPaths,
                onSelect: (String path) {
                  setState(() {
                    if (selectedPaths.contains(path)) {
                      selectedPaths.remove(path);
                    } else {
                      selectedPaths.clear();
                      selectedPaths.add(path);
                    }
                  });
                },
                onCopyPath: (String pythonPath) async {
                  await Clipboard.setData(ClipboardData(text: pythonPath));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已复制 Python 路径')),
                  );
                },
                onAddComment: (String yamlPath) async {
                  await _showAddCommentDialog(context, yamlPath);
                },
              ),
            ),
    );
  }
}

class JsonTreeView extends StatefulWidget {
  final dynamic data;
  final List<String> path;
  final Map<String, String> comments;
  final Set<String> selectedPaths;
  final void Function(String path) onSelect;
  final void Function(String pythonPath) onCopyPath;
  final void Function(String yamlPath) onAddComment;

  const JsonTreeView({
    super.key,
    required this.data,
    required this.path,
    required this.comments,
    required this.selectedPaths,
    required this.onSelect,
    required this.onCopyPath,
    required this.onAddComment,
  });

  @override
  State<JsonTreeView> createState() => _JsonTreeViewState();
}

class _JsonTreeViewState extends State<JsonTreeView> {
  bool expanded = true;

  String _buildPythonPath(List<String> path) {
    return path.map((e) => '["$e"]').join('');
  }

  String _buildYamlPath(List<String> path) {
    return path.join('.');
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final path = widget.path;
    final comments = widget.comments;
    final selectedPaths = widget.selectedPaths;
    final isRoot = path.isEmpty;

    if (data is Map) {
      if (data.isEmpty) {
        return _buildFieldRow(context, '{}', '{}', path, isEmpty: true);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isRoot)
            _buildFieldRow(context, path.last, '{...}', path),
          if (isRoot || expanded)
            Padding(
              padding: EdgeInsets.only(left: isRoot ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final entry in data.entries)
                    JsonTreeView(
                      data: entry.value,
                      path: [...path, entry.key.toString()],
                      comments: comments,
                      selectedPaths: selectedPaths,
                      onSelect: widget.onSelect,
                      onCopyPath: widget.onCopyPath,
                      onAddComment: widget.onAddComment,
                    ),
                ],
              ),
            ),
        ],
      );
    } else if (data is List) {
      if (data.isEmpty) {
        return _buildFieldRow(context, '[]', '[]', path, isEmpty: true);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isRoot)
            _buildFieldRow(context, path.last, '[...]', path),
          if (isRoot || expanded)
            Padding(
              padding: EdgeInsets.only(left: isRoot ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < data.length; i++)
                    JsonTreeView(
                      data: data[i],
                      path: [...path, i.toString()],
                      comments: comments,
                      selectedPaths: selectedPaths,
                      onSelect: widget.onSelect,
                      onCopyPath: widget.onCopyPath,
                      onAddComment: widget.onAddComment,
                    ),
                ],
              ),
            ),
        ],
      );
    } else {
      return _buildFieldRow(context, path.isNotEmpty ? path.last : '', data, path);
    }
  }

  Widget _buildFieldRow(BuildContext context, String key, dynamic value, List<String> path, {bool isEmpty = false}) {
    final yamlPath = _buildYamlPath(path);
    final pythonPath = _buildPythonPath(path);
    final isSelected = widget.selectedPaths.contains(yamlPath);
    final comment = widget.comments[yamlPath];
    return GestureDetector(
      onDoubleTap: () {
        widget.onSelect(yamlPath);
      },
      onSecondaryTapDown: (details) async {
        if (!isSelected) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请先双击选中字段')), // 右键前需双击
          );
          return;
        }
        final selected = await showMenu<String>(
          context: context,
          position: RelativeRect.fromLTRB(
            details.globalPosition.dx,
            details.globalPosition.dy,
            details.globalPosition.dx,
            details.globalPosition.dy,
          ),
          items: [
            const PopupMenuItem(
              value: 'copy',
              child: Text('复制 Python 路径'),
            ),
            const PopupMenuItem(
              value: 'comment',
              child: Text('添加/编辑注释'),
            ),
          ],
        );
        if (selected == 'copy') {
          widget.onCopyPath(pythonPath);
        } else if (selected == 'comment') {
          widget.onAddComment(yamlPath);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: isSelected ? Colors.lightBlue.withOpacity(0.2) : null,
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isEmpty)
              GestureDetector(
                onTap: () {
                  setState(() {
                    expanded = !expanded;
                  });
                },
                child: value is Map || value is List
                    ? Icon(
                        expanded ? Icons.expand_more : Icons.chevron_right,
                        size: 16,
                        color: Colors.blueGrey,
                      )
                    : const SizedBox(width: 16),
              ),
            if (!isEmpty) const SizedBox(width: 2),
            Text(
              key,
              style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
            ),
            const Text(': ', style: TextStyle(fontFamily: 'monospace')),
            Flexible(
              child: value is Map || value is List
                  ? Text(
                      value is Map ? '{...}' : '[...]',
                      style: const TextStyle(color: Colors.blueGrey, fontFamily: 'monospace'),
                    )
                  : Text(
                      value.toString(),
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
            ),
            if (comment != null && comment.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.comment, size: 16, color: Colors.orange),
              ),
          ],
        ),
      ),
    );
  }
}
