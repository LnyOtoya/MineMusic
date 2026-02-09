// Isolate 工具类，用于在单独的隔离区中执行耗时操作

import 'dart:isolate';
import 'dart:convert' as json;
import 'dart:async';

class IsolateUtils {
  // 解析 JSON 数据
  static Future<dynamic> parseJson(String jsonString) async {
    final port = ReceivePort();
    final isolate = await Isolate.spawn(
      _parseJsonIsolate,
      {
        'jsonString': jsonString,
        'sendPort': port.sendPort,
      },
    );

    try {
      final result = await port.first;
      if (result['error'] != null) {
        throw result['error'];
      }
      return result['result'];
    } finally {
      isolate.kill(priority: Isolate.immediate);
    }
  }

  // 解析 JSON 的隔离区入口点
  static void _parseJsonIsolate(Map<String, dynamic> message) {
    final jsonString = message['jsonString'] as String;
    final sendPort = message['sendPort'] as SendPort;

    Future.microtask(() {
      try {
        final result = json.jsonDecode(jsonString);
        sendPort.send({'result': result, 'error': null});
      } catch (error, stackTrace) {
        sendPort.send({'result': null, 'error': error.toString()});
        print('解析 JSON 失败: $error');
        print(stackTrace);
      }
    });
  }

  // 处理大量数据过滤
  static Future<List<dynamic>> filterData(
    List<dynamic> data,
    String predicateIdentifier,
  ) async {
    // 注意：这里只能处理简单的过滤逻辑，复杂的函数无法传递到隔离区
    // 实际项目中，可能需要根据具体需求实现不同的过滤函数
    final port = ReceivePort();
    final isolate = await Isolate.spawn(
      _filterDataIsolate,
      {
        'data': data,
        'predicateIdentifier': predicateIdentifier,
        'sendPort': port.sendPort,
      },
    );

    try {
      final result = await port.first;
      if (result['error'] != null) {
        throw result['error'];
      }
      return result['result'] as List<dynamic>;
    } finally {
      isolate.kill(priority: Isolate.immediate);
    }
  }

  // 过滤数据的隔离区入口点
  static void _filterDataIsolate(Map<String, dynamic> message) {
    final data = message['data'] as List<dynamic>;
    final predicateIdentifier = message['predicateIdentifier'] as String;
    final sendPort = message['sendPort'] as SendPort;

    Future.microtask(() {
      try {
        List<dynamic> result = [];
        // 根据标识符执行不同的过滤逻辑
        switch (predicateIdentifier) {
          case 'nonEmpty':
            result = data.where((item) => item != null && item.toString().isNotEmpty).toList();
            break;
          case 'isNumber':
            result = data.where((item) => item is num).toList();
            break;
          default:
            result = data;
        }
        sendPort.send({'result': result, 'error': null});
      } catch (error, stackTrace) {
        sendPort.send({'result': null, 'error': error.toString()});
        print('过滤数据失败: $error');
        print(stackTrace);
      }
    });
  }

  // 处理大量数据映射
  static Future<List<dynamic>> mapData(
    List<dynamic> data,
    String mapperIdentifier,
  ) async {
    // 注意：这里只能处理简单的映射逻辑，复杂的函数无法传递到隔离区
    // 实际项目中，可能需要根据具体需求实现不同的映射函数
    final port = ReceivePort();
    final isolate = await Isolate.spawn(
      _mapDataIsolate,
      {
        'data': data,
        'mapperIdentifier': mapperIdentifier,
        'sendPort': port.sendPort,
      },
    );

    try {
      final result = await port.first;
      if (result['error'] != null) {
        throw result['error'];
      }
      return result['result'] as List<dynamic>;
    } finally {
      isolate.kill(priority: Isolate.immediate);
    }
  }

  // 映射数据的隔离区入口点
  static void _mapDataIsolate(Map<String, dynamic> message) {
    final data = message['data'] as List<dynamic>;
    final mapperIdentifier = message['mapperIdentifier'] as String;
    final sendPort = message['sendPort'] as SendPort;

    Future.microtask(() {
      try {
        List<dynamic> result = [];
        // 根据标识符执行不同的映射逻辑
        switch (mapperIdentifier) {
          case 'toString':
            result = data.map((item) => item.toString()).toList();
            break;
          case 'toUpperCase':
            result = data.map((item) => item is String ? item.toUpperCase() : item).toList();
            break;
          default:
            result = data;
        }
        sendPort.send({'result': result, 'error': null});
      } catch (error, stackTrace) {
        sendPort.send({'result': null, 'error': error.toString()});
        print('映射数据失败: $error');
        print(stackTrace);
      }
    });
  }
}

