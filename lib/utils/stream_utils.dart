// Stream 工具类，用于处理异步数据流

import 'dart:async';

class StreamUtils {
  // 创建一个周期性的 Stream
  static Stream<T> periodic<T>(
    Duration period,
    T Function(int) computation,
    {bool cancelOnError = false}
  ) {
    return Stream.periodic(period, computation).asBroadcastStream(
      onCancel: (subscription) => subscription.cancel(),
    );
  }

  // 创建一个延迟的 Stream
  static Stream<T> delayed<T>(
    Duration duration,
    T value,
  ) {
    return Stream.fromFuture(
      Future.delayed(duration, () => value),
    ).asBroadcastStream();
  }

  // 合并多个 Stream
  static Stream<T> merge<T>(List<Stream<T>> streams) {
    return StreamGroup.merge(streams).asBroadcastStream();
  }

  // 转换 Stream 的值
  static Stream<R> map<T, R>(
    Stream<T> stream,
    R Function(T) mapper,
  ) {
    return stream.map(mapper).asBroadcastStream();
  }

  // 过滤 Stream 的值
  static Stream<T> where<T>(
    Stream<T> stream,
    bool Function(T) test,
  ) {
    return stream.where(test).asBroadcastStream();
  }

  // 限制 Stream 的值数量
  static Stream<T> take<T>(
    Stream<T> stream,
    int count,
  ) {
    return stream.take(count).asBroadcastStream();
  }

  // 跳过 Stream 的前几个值
  static Stream<T> skip<T>(
    Stream<T> stream,
    int count,
  ) {
    return stream.skip(count).asBroadcastStream();
  }

  // 监听 Stream 的值并执行回调
  static StreamSubscription<T> listen<T>(
    Stream<T> stream,
    void Function(T) onData,
    {
      Function? onError,
      void Function()? onDone,
      bool cancelOnError = false
    }
  ) {
    return stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  // 缓冲 Stream 的值
  static Stream<List<T>> buffer<T>(
    Stream<T> stream,
    Duration duration,
  ) {
    final controller = StreamController<List<T>>.broadcast();
    final buffer = <T>[];
    Timer? timer;

    final subscription = stream.listen(
      (data) {
        buffer.add(data);
        timer ??= Timer(duration, () {
          controller.add(List.from(buffer));
          buffer.clear();
          timer = null;
        });
      },
      onError: controller.addError,
      onDone: () {
        if (buffer.isNotEmpty) {
          controller.add(List.from(buffer));
        }
        controller.close();
        timer?.cancel();
      },
    );

    controller.onCancel = () {
      subscription.cancel();
      timer?.cancel();
    };

    return controller.stream;
  }

  // 去抖动 Stream 的值
  static Stream<T> debounce<T>(
    Stream<T> stream,
    Duration duration,
  ) {
    final controller = StreamController<T>.broadcast();
    Timer? timer;

    final subscription = stream.listen(
      (data) {
        timer?.cancel();
        timer = Timer(duration, () {
          controller.add(data);
        });
      },
      onError: controller.addError,
      onDone: () {
        controller.close();
        timer?.cancel();
      },
    );

    controller.onCancel = () {
      subscription.cancel();
      timer?.cancel();
    };

    return controller.stream;
  }

  // 节流 Stream 的值
  static Stream<T> throttle<T>(
    Stream<T> stream,
    Duration duration,
  ) {
    final controller = StreamController<T>.broadcast();
    bool isThrottled = false;

    final subscription = stream.listen(
      (data) {
        if (!isThrottled) {
          isThrottled = true;
          controller.add(data);
          Timer(duration, () {
            isThrottled = false;
          });
        }
      },
      onError: controller.addError,
      onDone: () {
        controller.close();
      },
    );

    controller.onCancel = () {
      subscription.cancel();
    };

    return controller.stream;
  }

  // 转换 Stream 为 Future
  static Future<T> first<T>(Stream<T> stream) {
    return stream.first;
  }

  // 转换 Stream 为 Future，获取最后一个值
  static Future<T> last<T>(Stream<T> stream) {
    return stream.last;
  }

  // 转换 Stream 为 Future，获取所有值
  static Future<List<T>> toList<T>(Stream<T> stream) {
    return stream.toList();
  }
}

// Stream 分组工具
class StreamGroup {
  // 合并多个 Stream
  static Stream<T> merge<T>(List<Stream<T>> streams) {
    final controller = StreamController<T>.broadcast();
    final subscriptions = <StreamSubscription>[];

    for (final stream in streams) {
      StreamSubscription? subscription;
      subscription = stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: () {
          if (subscription != null) {
            subscriptions.remove(subscription);
            if (subscriptions.isEmpty) {
              controller.close();
            }
          }
        },
      );
      subscriptions.add(subscription);
    }

    return controller.stream;
  }
}
