import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
    final bool isWeb = kIsWeb;
    final double webScaleFactor = 1.2; // Fator de escala para web

    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: isWeb ? 4 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(isWeb ? 20.0 : 16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isWeb ? Border.all(color: Colors.grey[200]!) : null,
            ),
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
                        color: color.withAlpha(isWeb ? 40 : 25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon, 
                        color: color, 
                        size: isWeb ? iconSize * webScaleFactor : iconSize,
                      ),
                    ),
                    if (onTap != null && showChevron)
                      Icon(
                        Icons.chevron_right, 
                        color: Colors.grey[400],
                        size: isWeb ? 28 : 24,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isWeb ? titleFontSize * webScaleFactor : titleFontSize,
                        color: titleColor ?? Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: isWeb ? valueFontSize * webScaleFactor * 1.1 : valueFontSize,
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
      ),
    );
  }
}