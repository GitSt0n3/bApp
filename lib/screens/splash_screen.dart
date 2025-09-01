import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    final curved = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _fade  = Tween(begin: 0.0, end: 1.0).animate(curved);
    _scale = Tween(begin: 0.85, end: 1.0).animate(curved);
    _c.forward();

    Timer(const Duration(milliseconds: 2600), () {
      if (mounted) context.go('/'); // Ajusta a tu ruta inicial real
    });
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/icons/barberiapp.png', width: 140, height: 140),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
