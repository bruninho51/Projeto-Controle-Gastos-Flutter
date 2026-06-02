import 'package:flutter/material.dart';

class PillSegmentedControl extends StatefulWidget {
  final List<String> labels;
  final List<IconData> icons;
  final TabController tabController;

  const PillSegmentedControl({
    super.key,
    required this.labels,
    required this.icons,
    required this.tabController,
  });

  @override
  State<PillSegmentedControl> createState() => _PillSegmentedControlState();
}

class _PillSegmentedControlState extends State<PillSegmentedControl> {
  // Posição atual do pill em "índices" (ex: 0.5 = meio entre aba 0 e 1)
  double _pillPosition = 0;
  // Índice da aba ativa (para colorir o texto)
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _pillPosition = widget.tabController.index.toDouble();
    _activeIndex = widget.tabController.index;
    widget.tabController.animation!.addListener(_onAnimation);
  }

  void _onAnimation() {
    if (!mounted) return;
    final value = widget.tabController.animation!.value;
    setState(() {
      _pillPosition = value;
      _activeIndex = value.round();
    });
  }

  @override
  void dispose() {
    widget.tabController.animation!.removeListener(_onAnimation);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemW = constraints.maxWidth / widget.labels.length;

        return Container(
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            children: [
              // Pill — posição calculada diretamente de _pillPosition
              Positioned(
                left: _pillPosition * itemW + 3,
                top: 3,
                bottom: 3,
                width: itemW - 6,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              // Botões
              Positioned.fill(
                child: Row(
                  children: List.generate(widget.labels.length, (i) {
                    final selected = _activeIndex == i;
                    return Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => widget.tabController.animateTo(i),
                          borderRadius: BorderRadius.circular(11),
                          splashColor: Colors.white.withValues(alpha: 0.1),
                          highlightColor: Colors.transparent,
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.icons[i],
                                  size: 15,
                                  color: selected
                                      ? const Color(0xFF3949AB)
                                      : Colors.white.withValues(alpha: 0.65),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.labels[i],
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: selected
                                        ? const Color(0xFF3949AB)
                                        : Colors.white.withValues(alpha: 0.65),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
