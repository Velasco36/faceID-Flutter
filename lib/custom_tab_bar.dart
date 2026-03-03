// lib/custom_tab_bar.dart
import 'package:flutter/material.dart';

const Color kPrimary = Color(0xFF137FEC);
const Color kInactive = Color(0xFF9CA3AF);

class CustomTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const int itemCount = 4;
    const double itemWidth = 1 / itemCount; // fracción por item

    // Centro del indicador como fracción del ancho total
    final double indicatorFraction =
        (currentIndex + 0.5) / itemCount;
    final double indicatorLeft =
        screenWidth * indicatorFraction - 5;

    return SizedBox(
      height: 90,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Fondo con curva animada ──
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: currentIndex.toDouble(),
                end: currentIndex.toDouble(),
              ),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubic,
              builder: (context, value, _) {
                return CustomPaint(
                  painter: NavBarPainter(activeIndex: value),
                );
              },
            ),
          ),

          // ── Indicador dot animado ──
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            top: 0,
            left: indicatorLeft,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color.fromARGB(255, 233, 231, 231), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),

          // ── Items ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 80,
            child: Row(
              children: [
                _buildItem(0, Icons.home_outlined, 'Inicio'),
                _buildItem(1, Icons.history, 'Historial'),
                _buildItem(2, Icons.location_on_outlined, 'Sucursal'),
                _buildItem(3, Icons.person_outline, 'Usuarios'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(int index, IconData icon, String label) {
    final bool isActive = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                icon,
                key: ValueKey(isActive),
                color: isActive ? kPrimary : kInactive,
                size: isActive ? 26 : 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? kPrimary : kInactive,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Painter con curva interpolada ───────────────────────────────────────────

class NavBarPainter extends CustomPainter {
  /// activeIndex puede ser decimal durante la animación (TweenAnimationBuilder)
  final double activeIndex;

  NavBarPainter({required this.activeIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    const int itemCount = 4;
    final double itemWidth = size.width / itemCount;
    final double dipCenter = itemWidth * (activeIndex + 0.5);
    const double dipRadius = 30.0;
    const double dipDepth = 16.0;

    final path = Path();
    path.moveTo(0, dipDepth);
    path.quadraticBezierTo(0, 0, 20, 0);
    path.lineTo(dipCenter - dipRadius - 20, 0);
    path.cubicTo(
      dipCenter - dipRadius - 5, 0,
      dipCenter - dipRadius, dipDepth,
      dipCenter, dipDepth,
    );
    path.cubicTo(
      dipCenter + dipRadius, dipDepth,
      dipCenter + dipRadius + 5, 0,
      dipCenter + dipRadius + 20, 0,
    );
    path.lineTo(size.width - 20, 0);
    path.quadraticBezierTo(size.width, 0, size.width, dipDepth);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(NavBarPainter old) => old.activeIndex != activeIndex;
}
