import 'package:flutter/material.dart';

typedef BackPressHandler<T> = Future<T?> Function();

class CustomBackHandler extends StatefulWidget {
  final Widget child;
  final BackPressHandler<bool>? onWillPop;

  const CustomBackHandler({
    super.key,
    required this.child,
    this.onWillPop,
  });

  @override
  State<CustomBackHandler> createState() => _CustomBackHandlerState();
}

class _CustomBackHandlerState extends State<CustomBackHandler> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        if (!mounted) return;
        
        bool shouldPop = true;
        
        if (widget.onWillPop != null) {
          shouldPop = await widget.onWillPop!() ?? true;
        }
        
        if (shouldPop) {
          Navigator.of(context).pop();
        }
      },
      child: widget.child,
    );
  }
}