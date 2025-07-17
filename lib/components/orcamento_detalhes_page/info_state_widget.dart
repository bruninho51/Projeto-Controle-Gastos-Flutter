import 'package:flutter/material.dart';

class InfoStateWidget extends StatelessWidget {
  final String message;
  final String? buttonText;
  final VoidCallback? onPressed;
  final IconData icon;
  final Color iconColor;
  final Color buttonForegroundColor;
  final Color? buttonBackgroundColor;
  final double iconSize;
  final EdgeInsetsGeometry? padding;

  const InfoStateWidget({
    super.key,
    required this.message,
    this.buttonText,
    this.onPressed,
    this.icon = Icons.error_outline,
    this.iconColor = Colors.red,
    this.buttonForegroundColor = Colors.red,
    this.buttonBackgroundColor,
    this.iconSize = 50.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      Icon(
        icon,
        size: iconSize,
        color: iconColor,
      ),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Text(
          message,
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    ];

    if (buttonText != null && onPressed != null) {
      children.addAll([
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            foregroundColor: buttonForegroundColor,
            backgroundColor: buttonBackgroundColor ?? 
                buttonForegroundColor.withAlpha(25),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(buttonText!),
        ),
      ]);
    }

    return Center(
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }
}