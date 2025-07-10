import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';
import 'package:flutter/foundation.dart';

void main(List<String> args) {
  runApp(JsonViewerApp(startupArgs: args));
}

class JsonViewerApp extends StatelessWidget {
  final List<String> startupArgs;
  const JsonViewerApp({super.key, this.startupArgs = const []});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JSON Viewer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: JsonViewerPage(startupArgs: startupArgs),
    );
  }
}

class JsonViewerPage extends StatefulWidget {
  final List<String> startupArgs;
  const JsonViewerPage({super.key, this.startupArgs = const []});

  @override
  State<JsonViewerPage> createState() => _JsonViewerPageState();
}

class _JsonViewerPageState extends State<JsonViewerPage> {
  dynamic jsonData;
  String filePath = '';
  Map<String, String> comments = {};
  Set<String> selectedPaths = {}; // 存储 path.key 或 path.value
  String? lastSelectedKey;
  String? lastSelectedValue;

  @override
  void initState() {
    super.initState();
    if (widget.startupArgs.isNotEmpty) {
      final file = widget.startupArgs.first;
      if (file.endsWith('.json')) {
        filePath = file;
        _loadFileFromPath(filePath);
      }
    }
  }

  Future<void> _loadFileFromPath(String path) async {
    try {
      final file = File(path);
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
    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          final isCtrlC = (event.isControlPressed || (defaultTargetPlatform == TargetPlatform.macOS && event.isMetaPressed)) && event.logicalKey.keyLabel.toLowerCase() == 'c';
          if (isCtrlC) {
            if (selectedPaths.isNotEmpty) {
              final sel = selectedPaths.first;
              if (sel.endsWith('.key') && lastSelectedKey != null && lastSelectedKey!.isNotEmpty) {
                Clipboard.setData(ClipboardData(text: lastSelectedKey!));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制字段名')));
              } else if (sel.endsWith('.value') && lastSelectedValue != null && lastSelectedValue!.isNotEmpty) {
                Clipboard.setData(ClipboardData(text: lastSelectedValue!));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制字段值')));
              }
            }
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                filePath.isNotEmpty ? filePath.split(Platform.pathSeparator).last : 'JSON Viewer',
                style: const TextStyle(fontSize: 20),
              ),
              if (filePath.isNotEmpty)
                Text(
                  filePath,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
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
                  onSelect: (String pathType, String keyName, String? valueStr, bool isKey) {
                    setState(() {
                      if (selectedPaths.contains(pathType)) {
                        selectedPaths.remove(pathType);
                        if (isKey) {
                          lastSelectedKey = null;
                        } else {
                          lastSelectedValue = null;
                        }
                      } else {
                        selectedPaths.clear();
                        selectedPaths.add(pathType);
                        if (isKey) {
                          lastSelectedKey = keyName;
                          lastSelectedValue = null;
                        } else {
                          lastSelectedValue = valueStr;
                          lastSelectedKey = null;
                        }
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
      ),
    );
  }
}

class JsonTreeView extends StatefulWidget {
  final dynamic data;
  final List<String> path;
  final Map<String, String> comments;
  final Set<String> selectedPaths;
  final void Function(String pathType, String keyName, String? valueStr, bool isKey) onSelect;
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
    final isKeySelected = widget.selectedPaths.contains('$yamlPath.key');
    final isValueSelected = widget.selectedPaths.contains('$yamlPath.value');
    final comment = widget.comments[yamlPath];
    
    void handleSelectKey() {
      widget.onSelect('$yamlPath.key', key, null, true);
    }
    void handleSelectValue() {
      widget.onSelect('$yamlPath.value', key, value?.toString(), false);
    }

    Widget rowWidget = Row(
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
          // Key部分 - 可单击选择（右键菜单）
          GestureDetector(
            onTap: () {
              handleSelectKey();
            },
            onSecondaryTapDown: (details) async {
              if (!isKeySelected) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请先单击选中字段')),
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
            child: Container(
              color: isKeySelected ? Colors.lightBlue.withOpacity(0.2) : null,
              child: Text(
                key,
                style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
              ),
            ),
          ),
          const Text(': ', style: TextStyle(fontFamily: 'monospace')),
          // Value部分 - 可单击选择
          Flexible(
            child: value is Map || value is List
                ? GestureDetector(
                    onTap: () {
                      handleSelectValue();
                    },
                    child: Container(
                      color: isValueSelected ? Colors.lightBlue.withOpacity(0.2) : null,
                      child: Text(
                        value is Map ? '{...}' : '[...]',
                        style: const TextStyle(color: Colors.blueGrey, fontFamily: 'monospace'),
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          handleSelectValue();
                        },
                        child: Container(
                          color: isValueSelected ? Colors.lightBlue.withOpacity(0.2) : null,
                          child: Text(
                            value.toString(),
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                      ),
                      if (comment != null && comment.isNotEmpty)
                        Text(
                          '  ( $comment )',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      );

    return rowWidget;
  }
}
