import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // ── Controllers ────────────────────────────────────────────
  AnimationController? _logoController;
  AnimationController? _textController;
  AnimationController? _ringController;

  // ── Animations ─────────────────────────────────────────────
  Animation<double>?  _logoScale;
  Animation<double>?  _logoOpacity;
  Animation<double>?  _textOpacity;
  Animation<Offset>?  _textSlide;

  // ── Design tokens ──────────────────────────────────────────
  static const _bgTop    = Color(0xFF021B34);
  static const _bgMid    = Color(0xFF06335B);
  static const _bgBot    = Color(0xFF0A4D7A);
  static const _gold     = Color(0xFFC8A84B);
  static const _goldGlow = Color(0xFFFFD670);

  @override
  void initState() {
    super.initState();

    // Make status bar transparent over the dark splash
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _logoScale = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _logoController!, curve: Curves.easeOutExpo),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController!, curve: Curves.easeIn),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController!, curve: Curves.easeIn),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController!, curve: Curves.easeOut),
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await _logoController?.forward();
    await Future.delayed(const Duration(milliseconds: 250));
    await _textController?.forward();
    await Future.delayed(const Duration(milliseconds: 2200));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _logoController?.dispose();
    _textController?.dispose();
    _ringController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _bgTop,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bgTop, _bgMid, _bgBot],
          ),
        ),
        child: Stack(
          children: [
            // ── Soft particles ───────────────────────────────
            ...List.generate(14, (i) => _Particle(index: i, size: size)),

            // ── Main content ─────────────────────────────────
            SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _textOpacity ??
                      const AlwaysStoppedAnimation(1.0),
                  child: SlideTransition(
                    position: _textSlide ??
                        const AlwaysStoppedAnimation(Offset.zero),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          // ── Logo with spinning ring ───────
                          FadeTransition(
                            opacity: _logoOpacity ??
                                const AlwaysStoppedAnimation(1.0),
                            child: ScaleTransition(
                              scale: _logoScale ??
                                  const AlwaysStoppedAnimation(1.0),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer spinning gold ring
                                  RotationTransition(
                                    turns: _ringController ??
                                        const AlwaysStoppedAnimation(0),
                                    child: Container(
                                      width: 170,
                                      height: 170,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _gold.withValues(alpha: 0.65),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Inner static ring
                                  Container(
                                    width: 158,
                                    height: 158,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _gold.withValues(alpha: 0.25),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  // Logo circle
                                  Container(
                                    width: 142,
                                    height: 142,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _goldGlow.withValues(alpha: 0.18),
                                          blurRadius: 30,
                                          spreadRadius: 4,
                                        ),
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.35),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Image.asset(
                                          'assets/images/bdphs.png',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 42),

                          // ── School name ───────────────────
                          Text(
                            'BLOOMING DALE',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 3,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'PUBLIC HIGH SCHOOL',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              color: Colors.white60,
                              letterSpacing: 5,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Gold divider ──────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 1,
                                color: _gold.withValues(alpha: 0.4),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: _gold,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 40,
                                height: 1,
                                color: _gold.withValues(alpha: 0.4),
                              ),
                            ],
                          ),

                          const SizedBox(height: 22),

                          // ── Tagline ───────────────────────
                          Text(
                            'Where Young Minds Bloom',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.playfairDisplay(
                              color: Colors.white70,
                              fontSize: 17,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w400,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            'and Bright Futures Begin.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.playfairDisplay(
                              color: _gold,
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 20),

                          Text(
                            'Student Management System',
                            style: GoogleFonts.dmSans(
                              color: Colors.white38,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),

                          const SizedBox(height: 18),

                          // ── Est. badge ────────────────────
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: _gold.withValues(alpha: 0.55),
                              ),
                            ),
                            child: Text(
                              'EST. 1982',
                              style: GoogleFonts.dmSans(
                                color: _gold,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                letterSpacing: 2,
                              ),
                            ),
                          ),

                          const SizedBox(height: 60),

                          // ── Loader ────────────────────────
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(_gold),
                            ),
                          ),

                          const SizedBox(height: 14),

                          Text(
                            'Loading...',
                            style: GoogleFonts.dmSans(
                              color: Colors.white38,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Particle widget (stateless, deterministic) ─────────────────
class _Particle extends StatelessWidget {
  final int index;
  final Size size;

  const _Particle({required this.index, required this.size});

  @override
  Widget build(BuildContext context) {
    final rng    = Random(index);
    final left   = rng.nextDouble() * size.width;
    final top    = rng.nextDouble() * size.height;
    final dotSize = rng.nextDouble() * 3.5 + 1.5;
    final opacity = rng.nextDouble() * 0.25 + 0.05;

    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: opacity),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}