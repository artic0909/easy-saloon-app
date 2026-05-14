import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easysaloonapp/core/constants/app_colors.dart';

class SalonLoader extends StatefulWidget {
  final double size;
  final String message;

  const SalonLoader({
    super.key,
    this.size = 100,
    this.message = "Preparing your luxury experience...",
  });

  @override
  State<SalonLoader> createState() => _SalonLoaderState();
}

class _SalonLoaderState extends State<SalonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Rotating Outer Gold Ring
            RotationTransition(
              turns: _controller,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
            ),
            // Center Icon (Scissors/Salon related)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.1),
              duration: const Duration(seconds: 1),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Icon(
                    Icons.content_cut,
                    color: AppColors.primary,
                    size: widget.size * 0.4,
                  ),
                );
              },
              onEnd: () {}, // Handled by repeat logic if I used a controller, but TweenAnimationBuilder is simple
            ),
            // Sparkles
            ...List.generate(4, (index) {
              return RotationTransition(
                turns: AlwaysStoppedAnimation(index * 90 / 360),
                child: Transform.translate(
                  offset: Offset(0, -widget.size * 0.45),
                  child: const Icon(Icons.auto_awesome, color: AppColors.primaryLight, size: 12),
                ),
              );
            }),
          ],
        ),
        if (widget.message.isNotEmpty) ...[
          SizedBox(height: 24.h),
          Text(
            widget.message.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ],
    );
  }
}
