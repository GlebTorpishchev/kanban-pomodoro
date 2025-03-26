import 'package:flutter/material.dart';

class AnimatedTabView extends StatelessWidget {
  final TabController controller;
  final List<Widget> children;

  const AnimatedTabView({
    Key? key,
    required this.controller,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: controller,
      physics: const ClampingScrollPhysics(),
      children: children.map((child) {
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(20 * (1 - value), 0),
                child: child,
              ),
            );
          },
          child: child,
        );
      }).toList(),
    );
  }
} 