// widgets/skeleton_loader.dart
import 'package:flutter/material.dart';

/// Widget reutilizable de skeleton con animación shimmer.
/// Úsalo en cualquier pantalla mientras cargan los datos.
///
/// Ejemplo de uso:
///   SkeletonLoader()                        // 5 cards por defecto
///   SkeletonLoader(itemCount: 3)            // 3 cards
///   SkeletonLoader(showHeader: true)        // con header arriba
class SkeletonLoader extends StatefulWidget {
  final int itemCount;
  final bool showHeader;

  const SkeletonLoader({
    super.key,
    this.itemCount = 5,
    this.showHeader = false,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _animation = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            if (widget.showHeader) ...[
              _SkeletonHeaderTile(shimmerValue: _animation.value),
              const SizedBox(height: 16),
            ],
            ...List.generate(
              widget.itemCount,
              (i) => _SkeletonCardTile(shimmerValue: _animation.value),
            ),
          ],
        );
      },
    );
  }
}

// ─── Header skeleton ────────────────────────────────────────────
class _SkeletonHeaderTile extends StatelessWidget {
  final double shimmerValue;
  const _SkeletonHeaderTile({required this.shimmerValue});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ShimmerBox(width: 140, height: 20, shimmerValue: shimmerValue, radius: 6),
        _ShimmerBox(width: 80, height: 20, shimmerValue: shimmerValue, radius: 6),
      ],
    );
  }
}

// ─── Card skeleton (replica la estructura de AttendanceCard) ────
class _SkeletonCardTile extends StatelessWidget {
  final double shimmerValue;
  const _SkeletonCardTile({required this.shimmerValue});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar circular
          _ShimmerBox(
            width: 48,
            height: 48,
            shimmerValue: shimmerValue,
            radius: 24,
          ),
          const SizedBox(width: 12),
          // Nombre + cédula + sucursal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(width: 140, height: 13, shimmerValue: shimmerValue, radius: 4),
                const SizedBox(height: 6),
                _ShimmerBox(width: 100, height: 11, shimmerValue: shimmerValue, radius: 4),
                const SizedBox(height: 6),
                _ShimmerBox(width: 80, height: 10, shimmerValue: shimmerValue, radius: 4),
              ],
            ),
          ),
          // Hora + tipo
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _ShimmerBox(width: 52, height: 13, shimmerValue: shimmerValue, radius: 4),
              const SizedBox(height: 6),
              _ShimmerBox(width: 40, height: 11, shimmerValue: shimmerValue, radius: 4),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Caja shimmer base ──────────────────────────────────────────
class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double shimmerValue;
  final double radius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.shimmerValue,
    this.radius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            Color(0xFFE2E8F0),
            Color(0xFFF1F5F9),
            Color(0xFFE2E8F0),
          ],
          stops: const [0.0, 0.5, 1.0],
          transform: _SlidingGradientTransform(shimmerValue),
        ),
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}
