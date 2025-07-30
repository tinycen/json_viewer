import 'dart:convert';
import 'dart:io';

class JsonCompressor {
  /// 压缩JSON数据
  static dynamic compressJson(dynamic data) {
    if (data is String) {
      if (data.length > 10) {
        return data.substring(0, 10) + '...';
      }
      return data;
    } else if (data is List) {
      if (data.length > 2) {
        return [
          if (data.length > 0) compressJson(data[0]),
          if (data.length > 1) compressJson(data[1]),
        ];
      }
      return data.map((item) => compressJson(item)).toList();
    } else if (data is Map) {
      final compressedMap = <String, dynamic>{};
      int count = 0;
      data.forEach((key, value) {
        if (count < 2) {
          compressedMap[key] = compressJson(value);
          count++;
        }
      });
      return compressedMap;
    }
    return data;
  }

  /// 保存压缩后的JSON文件
  static Future<String?> saveCompressedFile(String filePath, dynamic jsonData) async {
    try {
      final compressedData = compressJson(jsonData);
      final jsonString = jsonEncode(compressedData);

      final file = File(filePath);
      final directory = file.parent;
      final nameWithoutExtension = file.uri.pathSegments
          .lastWhere((segment) => segment.contains('.'))
          .split('.')
          .first;
      final newPath = '${directory.path}${Platform.pathSeparator}${nameWithoutExtension}_compressed.json';

      final newFile = File(newPath);
      await newFile.writeAsString(jsonString);
      return newPath;
    } catch (e) {
      return null;
    }
  }
}