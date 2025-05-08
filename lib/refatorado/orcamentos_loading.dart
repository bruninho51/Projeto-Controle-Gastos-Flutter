import 'package:flutter/material.dart';

class OrcamentosLoading extends StatefulWidget {
  final String? message;

  const OrcamentosLoading({
    super.key,
    this.message,
  });

  @override
  State<OrcamentosLoading> createState() => _OrcamentosLoadingState();
}

class _OrcamentosLoadingState extends State<OrcamentosLoading> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  
  late AnimationController _dotsController;
  late List<Animation<int>> _dotsAnimations;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    
    _dotsAnimations = List.generate(3, (index) {
      return IntTween(begin: 50, end: 255).animate(
        CurvedAnimation(
          parent: _dotsController,
          curve: Interval(
            index * 0.2,
            1.0,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blueColor = Colors.blue[700]!;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: blueColor.withAlpha(20),
                    ),
                  ),
                  Transform.scale(
                    scale: _scaleAnimation.value,
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: Image.asset('assets/icon.png'),
                    ),
                  ),
                ],
              );
            },
          ),
          if(widget.message != null) 
          Column(
            children: [
              const SizedBox(height: 24),
              Text(
                widget.message!,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: blueColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return AnimatedBuilder(
                animation: _dotsAnimations[index],
                builder: (context, child) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: blueColor.withAlpha(_dotsAnimations[index].value),
                        boxShadow: [
                          BoxShadow(
                            color: blueColor.withAlpha(_dotsAnimations[index].value ~/ 2),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
      )],
      ),
    );
  }
}