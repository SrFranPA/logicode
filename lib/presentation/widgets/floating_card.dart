import 'package:flutter/material.dart';

class FloatingCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double widthFactor; // 0..1

  const FloatingCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.widthFactor = 0.9,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * widthFactor;
    return Center(
      child: Card(
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: width,
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
