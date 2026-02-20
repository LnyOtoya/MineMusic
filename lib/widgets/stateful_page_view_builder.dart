import 'package:flutter/material.dart';

class StatefulPageViewBuilder extends StatefulWidget {
  final int index;
  final Widget Function(BuildContext, int) itemBuilder;
  final int? itemCount;
  final ScrollPhysics? physics;
  final void Function(int)? onPageChanged;

  const StatefulPageViewBuilder({
    super.key,
    required this.index,
    required this.itemBuilder,
    this.itemCount,
    this.physics,
    this.onPageChanged,
  });

  @override
  State<StatefulPageViewBuilder> createState() => StatefulPageViewBuilderState();
}

class StatefulPageViewBuilderState extends State<StatefulPageViewBuilder> {
  late final PageController _controller = PageController(
    initialPage: widget.index,
    viewportFraction: 0.9999999999,
  );

  @override
  void didUpdateWidget(covariant StatefulPageViewBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      final duration = const Duration(milliseconds: 300);
      if ((oldWidget.index - widget.index).abs() > 5) {
        _controller.jumpToPage(widget.index);
      } else {
        _controller.animateToPage(
          widget.index,
          duration: duration,
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      physics: widget.physics,
      itemCount: widget.itemCount,
      onPageChanged: (index) {
        widget.onPageChanged?.call(index);
      },
      itemBuilder: (context, index) => widget.itemBuilder(context, index),
    );
  }
}
