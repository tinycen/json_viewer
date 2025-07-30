import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';
import 'package:flutter/foundation.dart';
import '../widgets/json_tree_view.dart';

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
  Set<String> selectedPaths = {};
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('加载失败: $e')));
    }
  }

  String _buildYamlPath(List<String> path) {
    return path.join('.');
  }

  Future<void> _showAddCommentDialog(
    BuildContext context,
    String fieldKey,
  ) async {
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('注释加载失败: $e')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载失败: $e')));
      }
    }
  }

  dynamic _compressJsonData(dynamic data) {
    if (data is String) {
      if (data.length > 10) {
        return data.substring(0, 10) + '...';
      }
      return data;
    } else if (data is List) {
      if (data.length > 2) {
        return [
          if (data.length > 0) _compressJsonData(data[0]),
          if (data.length > 1) _compressJsonData(data[1]),
        ];
      }
      return data.map((item) => _compressJsonData(item)).toList();
    } else if (data is Map) {
      final compressedMap = <String, dynamic>{};
      int count = 0;
      data.forEach((key, value) {
        if (count < 2) {
          compressedMap[key] = _compressJsonData(value);
          count++;
        }
      });
      return compressedMap;
    }
    return data;
  }

  Future<void> _saveCompressedFile() async {
    if (jsonData == null) return;
    
    final compressedData = _compressJsonData(jsonData);
    final jsonString = jsonEncode(compressedData);
    
    final file = File(filePath);
    final directory = file.parent;
    final nameWithoutExtension = file.uri.pathSegments.lastWhere((segment) => segment.contains('.')).split('.').first;
    final newPath = '${directory.path}${Platform.pathSeparator}${nameWithoutExtension}_compressed.json';
    
    try {
      final newFile = File(newPath);
      await newFile.writeAsString(jsonString);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('压缩文件已保存到: $newPath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          final isCtrlC = 
              (event.isControlPressed || 
                  (defaultTargetPlatform == TargetPlatform.macOS && 
                      event.isMetaPressed)) && 
              event.logicalKey.keyLabel.toLowerCase() == 'c';
          if (isCtrlC) {
            if (selectedPaths.isNotEmpty) {
              final sel = selectedPaths.first;
              if (sel.endsWith('.key') && 
                  lastSelectedKey != null && 
                  lastSelectedKey!.isNotEmpty) {
                Clipboard.setData(ClipboardData(text: lastSelectedKey!));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('已复制字段名')));
              } else if (sel.endsWith('.value') && 
                  lastSelectedValue != null && 
                  lastSelectedValue!.isNotEmpty) {
                Clipboard.setData(ClipboardData(text: lastSelectedValue!));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('已复制字段值')));
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
                filePath.isNotEmpty
                    ? filePath.split(Platform.pathSeparator).last
                    : 'JSON Viewer',
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
            IconButton(
              icon: const Icon(Icons.compress),
              onPressed: jsonData == null ? null : _saveCompressedFile,
              tooltip: '压缩并保存 JSON 文件',
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
                  onSelect: 
                      (
                        String pathType,
                        String keyName,
                        String? valueStr,
                        bool isKey,
                      ) {
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