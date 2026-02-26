import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class FaceScanAnimation extends StatefulWidget {
  final double size;
  final bool repeat;
  final VoidCallback? onAnimationFinished;
  final Duration? duration;
  final String animationPath;

  const FaceScanAnimation({
    super.key,
    this.size = 0.7, // Porcentaje del ancho de la pantalla
    this.repeat = true,
    this.onAnimationFinished,
    this.duration,
    this.animationPath = 'assets/animations/face_scan.json',
  });

  @override
  State<FaceScanAnimation> createState() => _FaceScanAnimationState();
}

class _FaceScanAnimationState extends State<FaceScanAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration ?? const Duration(seconds: 3),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !widget.repeat) {
        if (widget.onAnimationFinished != null) {
          widget.onAnimationFinished!();
        }
      }
    });

    if (widget.repeat) {
      _controller.repeat();
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Center(
      child: Lottie.asset(
        widget.animationPath,
        controller: _controller,
        width: size.width * widget.size,
        height: size.width * widget.size,
        fit: BoxFit.contain,
        repeat: widget.repeat,
        onLoaded: (composition) {
          if (!widget.repeat && widget.duration == null) {
            _controller.duration = composition.duration;
          }
        },
      ),
    );
  }
}

// Versión simplificada sin controller (más fácil de usar)
class SimpleFaceScanAnimation extends StatelessWidget {
  final double size;
  final bool repeat;
  final VoidCallback? onFinish;
  final Duration? duration;
  final String animationPath;

  const SimpleFaceScanAnimation({
    super.key,
    this.size = 0.7,
    this.repeat = true,
    this.onFinish,
    this.duration,
    this.animationPath = 'assets/animations/face_scan.json',
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Center(
      child: Lottie.asset(
        animationPath,
        width: screenSize.width * size,
        height: screenSize.width * size,
        fit: BoxFit.contain,
        repeat: repeat,
        onLoaded: (composition) {
          if (!repeat && onFinish != null) {
            Future.delayed(composition.duration, onFinish);
          }
        },
      ),
    );
  }
}

// Componente con fondo semitransparente (útil para loading)
class FaceScanLoadingAnimation extends StatelessWidget {
  final String message;
  final double size;
  final Color backgroundColor;

  const FaceScanLoadingAnimation({
    super.key,
    this.message = 'Procesando...',
    this.size = 0.5,
    this.backgroundColor = Colors.black54,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Container(
      color: backgroundColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/animations/face_scan.json',
              width: screenSize.width * size,
              height: screenSize.width * size,
              fit: BoxFit.contain,
              repeat: true,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
