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
  final EdgeInsetsGeometry? margin;

  const OrcamentoDetalhesCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.onTap,
    this.showChevron = true,
    this.iconSize = 24,
    this.titleFontSize = 24,
    this.valueFontSize = 24,
    this.titleColor,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final bool isWeb = kIsWeb;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Obtém a largura disponível e calcula o fator de escala
        final screenWidth = constraints.maxWidth;
        final scaleFactor = _calculateScaleFactor(screenWidth, isWeb);
        
        // Aplica escala responsiva a todos os elementos
        final responsiveIconSize = iconSize * scaleFactor;
        final responsiveTitleFontSize = titleFontSize * scaleFactor;
        final responsiveValueFontSize = valueFontSize * scaleFactor;
        final responsivePadding = isWeb ? 20.0 * scaleFactor : 16.0 * scaleFactor;
        final responsiveIconPadding = 8.0 * scaleFactor;
        final responsiveSpacing = 12.0 * scaleFactor;
        final responsiveSmallSpacing = 6.0 * scaleFactor;

        return Container(
          margin: margin,
          child: AspectRatio(
            aspectRatio: 1,
            child: MouseRegion(
              cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
              child: GestureDetector(
                onTap: onTap,
                child: Card(
                  elevation: isWeb ? 4 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12 * scaleFactor),
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(responsivePadding),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12 * scaleFactor),
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
                              padding: EdgeInsets.all(responsiveIconPadding),
                              decoration: BoxDecoration(
                                color: color.withAlpha(isWeb ? 40 : 25),
                                borderRadius: BorderRadius.circular(8 * scaleFactor),
                              ),
                              child: Icon(
                                icon, 
                                color: color, 
                                size: responsiveIconSize,
                              ),
                            ),
                            if (onTap != null && showChevron)
                              Icon(
                                Icons.chevron_right, 
                                color: Colors.grey[400],
                                size: responsiveIconSize * 1.1,
                              ),
                          ],
                        ),
                        SizedBox(height: responsiveSpacing),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: responsiveTitleFontSize,
                                  color: titleColor ?? Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: responsiveSmallSpacing),
                              Text(
                                value,
                                style: TextStyle(
                                  fontSize: responsiveValueFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _calculateScaleFactor(double screenWidth, bool isWeb) {
    if (isWeb) {
      // Escala progressiva para web
      if (screenWidth > 1400) return 1.2;
      if (screenWidth > 1200) return 1.1;
      if (screenWidth > 1000) return 1.0;
      if (screenWidth > 800) return 0.95;
      if (screenWidth > 600) return 0.9;
      if (screenWidth > 500) return 0.85;
      if (screenWidth > 400) return 0.8;
      return 0.75;
    } else {
      // Escala progressiva para mobile
      if (screenWidth > 400) return 1.0;
      if (screenWidth > 380) return 0.95;
      if (screenWidth > 350) return 0.9;
      if (screenWidth > 320) return 0.85;
      if (screenWidth > 300) return 0.8;
      if (screenWidth > 280) return 0.75;
      return 0.7;
    }
  }
}
