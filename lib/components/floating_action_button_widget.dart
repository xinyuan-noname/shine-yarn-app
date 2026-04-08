import 'package:flutter/material.dart';
import 'package:shine/theme.dart';

/// 浮动操作按钮组件
class FloatingActionButtonWidget extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final Color? iconColor;
  final double? iconSize;
  final Gradient? gradient;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final List<BoxShadow>? boxShadow;
  final List<Shadow>? iconShadows;
  final Widget? child;

  const FloatingActionButtonWidget({
    super.key,
    this.onTap,
    this.icon = Icons.add,
    this.iconColor,
    this.iconSize,
    this.gradient,
    this.backgroundColor,
    this.margin,
    this.padding,
    this.boxShadow,
    this.iconShadows,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin ?? const EdgeInsets.all(10),
        padding: padding ?? const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: gradient ?? blueLinearGradient,
          color: backgroundColor,
          boxShadow:
              boxShadow ??
              [
                const BoxShadow(
                  color: Colors.white,
                  spreadRadius: 1,
                  blurRadius: 10,
                ),
              ],
          shape: BoxShape.circle,
        ),
        child:
            child ??
            Icon(
              icon,
              color: iconColor ?? mainColorPurple,
              size: iconSize ?? largeIconSize,
              shadows:
                  iconShadows ??
                  [const Shadow(color: Colors.white, blurRadius: 5)],
            ),
      ),
    );
  }
}
