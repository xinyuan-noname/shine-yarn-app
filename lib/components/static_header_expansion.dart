import 'package:flutter/material.dart';
import 'package:shine/components/line.dart';

class StaticHeaderExpansion extends StatefulWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final List<Widget> children;
  final bool initiallyExpanded;
  final VoidCallback? onLeadingTap; // 单独处理 leading 点击
  final VoidCallback? onHeaderTap; // 单独处理整个头部点击
  final Duration animationDuration;
  final Curve animationCurve;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? trailingColor;

  const StaticHeaderExpansion({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.children,
    this.initiallyExpanded = false,
    this.onLeadingTap,
    this.onHeaderTap,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
    this.padding,
    this.backgroundColor,
    this.trailingColor,
  });

  @override
  State<StaticHeaderExpansion> createState() => _StaticHeaderExpansionState();
}

class _StaticHeaderExpansionState extends State<StaticHeaderExpansion>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;

    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _heightAnimation = CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    );

    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
    widget.onHeaderTap?.call();
  }

  void _handleLeadingTap() {
    if (widget.onLeadingTap != null) {
      widget.onLeadingTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _toggleExpansion,
            child: Padding(
              padding:
                  widget.padding ??
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  if (widget.leading != null)
                    GestureDetector(
                      onTap: _handleLeadingTap,
                      behavior: HitTestBehavior.opaque,
                      child: widget.leading,
                    )
                  else
                    const SizedBox.shrink(),

                  if (widget.leading != null) const SizedBox(width: 16.0),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        widget.title,
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 4.0),
                          DefaultTextStyle(
                            style: Theme.of(context).textTheme.bodySmall!,
                            child: widget.subtitle!,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 8.0),

                  widget.trailing ??
                      RotationTransition(
                        turns: Tween(
                          begin: 0.0,
                          end: 0.5,
                        ).animate(_heightAnimation),
                        child: Icon(
                          Icons.expand_more,
                          color: widget.trailingColor,
                        ),
                      ),
                ],
              ),
            ),
          ),

          SizeTransition(
            sizeFactor: _heightAnimation,
            axisAlignment: -1.0,
            child: GestureDetector(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [bottomLine, ...widget.children],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
