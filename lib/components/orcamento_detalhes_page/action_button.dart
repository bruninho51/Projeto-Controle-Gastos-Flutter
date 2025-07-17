import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final double verticalPadding;
  final double iconSpacing;
  final TextStyle? textStyle;
  final Color? iconColor;

  const ActionButton({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
    this.onPressed,
    this.verticalPadding = 16,
    this.iconSpacing = 8,
    this.textStyle,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor ?? Colors.white),
          SizedBox(width: iconSpacing),
          Text(
            text,
            style: textStyle ?? const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}