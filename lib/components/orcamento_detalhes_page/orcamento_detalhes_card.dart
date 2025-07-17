import 'package:flutter/material.dart';

class OrcamentoDetalhesCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
  final bool showChevron;
  final double iconSize;
  final double titleFontSize;
  final double valueFontSize;
  final Color? titleColor;

  const OrcamentoDetalhesCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.onTap,
    this.showChevron = true,
    this.iconSize = 24,
    this.titleFontSize = 14,
    this.valueFontSize = 18,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: iconSize),
                  ),
                  if (onTap != null && showChevron)
                    Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      color: titleColor ?? Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: valueFontSize,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}