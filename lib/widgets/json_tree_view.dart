import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class JsonTreeView extends StatefulWidget {
  final dynamic data;
  final List<String> path;
  final Map<String, String> comments;
  final Set<String> selectedPaths;
  final void Function(
    String pathType,
    String keyName,
    String? valueStr,
    bool isKey,
  )
  onSelect;
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
          if (!isRoot) _buildFieldRow(context, path.last, '{...}', path),
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
          if (!isRoot) _buildFieldRow(context, path.last, '[...]', path),
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
      return _buildFieldRow(
        context,
        path.isNotEmpty ? path.last : '',
        data,
        path,
      );
    }
  }

  Widget _buildFieldRow(
    BuildContext context,
    String key,
    dynamic value,
    List<String> path, {
    bool isEmpty = false,
  }) {
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
        GestureDetector(
          onTap: () {
            handleSelectKey();
          },
          onSecondaryTapDown: (details) async {
            if (!isKeySelected) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('请先单击选中字段')));
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
                const PopupMenuItem(value: 'copy', child: Text('复制 Python 路径')),
                const PopupMenuItem(value: 'comment', child: Text('添加/编辑注释')),
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
        const Text(': ', style: TextStyle(fontFamily: 'monospace')),
        Flexible(
          child: value is Map || value is List
              ? GestureDetector(
                  onTap: () {
                    handleSelectValue();
                  },
                  child: Container(
                    color: isValueSelected
                        ? Colors.lightBlue.withOpacity(0.2)
                        : null,
                    child: Text(
                      value is Map ? '{...}' : '[...]',
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontFamily: 'monospace',
                      ),
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
                        color: isValueSelected
                            ? Colors.lightBlue.withOpacity(0.2)
                            : null,
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