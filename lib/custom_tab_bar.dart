// lib/custom_tab_bar.dart
import 'package:flutter/material.dart';
import './main_screen.dart';

const Color kPrimary = Color(0xFF137FEC);
const Color kInactive = Color(0xFF9CA3AF);

class CustomTabBar extends StatelessWidget {
  final int currentIndex; // ✅ recibe el índice
  final ValueChanged<int> onTap; // ✅ recibe el callback

  const CustomTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      height: 90,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: NavBarPainter(activeIndex: currentIndex),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            top: 0,
            left: _getIndicatorLeft(screenWidth, currentIndex),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _getIndicatorLeft(double screenWidth, int index) {
    final itemWidth = screenWidth / 3;
    return itemWidth * index + itemWidth / 2 - 5;
  }

  Widget _buildItem(int index, IconData icon, String label) {
    final bool isActive = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index), // ✅ usa el callback directo
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? kPrimary : kInactive, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isActive ? kPrimary : kInactive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NavBarPainter extends CustomPainter {
  final int activeIndex;

  NavBarPainter({required this.activeIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final double itemWidth = size.width / 3;
    final double dipCenter = itemWidth * activeIndex + itemWidth / 2;
    const double dipRadius = 28.0;
    const double dipDepth = 18.0;

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
  bool shouldRepaint(NavBarPainter oldDelegate) =>
      oldDelegate.activeIndex != activeIndex;
}
