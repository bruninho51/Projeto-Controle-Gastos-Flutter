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
    this.iconSize = 48,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: iconSize, color: iconColor),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onPressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(buttonText!, style: const TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonForegroundColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}