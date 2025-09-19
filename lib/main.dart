// lib/main.dart
// Ensures dotenv is loaded before runApp so OPENAI_API_KEY is available to the app.

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:video_player/video_player.dart';

// <- IMPORT THE HOME PAGE
import 'pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env before runApp so dotenv.env values are available immediately.
  try {
    await dotenv.load(fileName: ".env");
    final hasKey = dotenv.env['OPENAI_API_KEY'] != null && dotenv.env['OPENAI_API_KEY']!.isNotEmpty;
    debugPrint('dotenv loaded. OPENAI_API_KEY present: $hasKey');
  } catch (e) {
    debugPrint('dotenv load failed: $e');
  }

  runApp(const EcoWasteIntroApp());
}

class EcoWasteIntroApp extends StatelessWidget {
  const EcoWasteIntroApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedGreen = Color(0xFF00C853);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'E-Wise(Intro)',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedGreen,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.black,
        brightness: Brightness.dark,
      ),
      home: const IntroScreen(),
    );
  }
}

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  late final VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/intro1.mp4')
      ..setLooping(true)
      ..setVolume(0.0)
      ..initialize().then((_) {
        _controller.play();
        setState(() => _initialized = true);
      });
  }

  @override
  void dispose() {
    _controller.pause();
    _controller.dispose();
    super.dispose();
  }

  Widget _videoBackground(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (!_initialized || !_controller.value.isInitialized) {
      return Container(color: cs.background);
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        alignment: Alignment.center,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }

  void _openAuthBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AuthBottomSheet(),
    );
  }

  void _goToLoginDummy() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginDummyPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _videoBackground(context)),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.48),
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.78),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        Icons.eco,
                        color: cs.primary,
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: 34),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "E-Wise",
                      style: TextStyle(
                        color: Colors.white,
                        height: 1.12,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Manage your e-waste the smart and sustainable way.",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _openAuthBottomSheet,
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Get Started',
                        style: TextStyle(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'New to this app? ',
                        style: TextStyle(color: Colors.white70),
                      ),
                      TextButton(
                        onPressed: _goToLoginDummy,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Create an account',
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum AuthLoading { none, google, apple, email }

class _AuthBottomSheet extends StatefulWidget {
  const _AuthBottomSheet({super.key});

  @override
  State<_AuthBottomSheet> createState() => _AuthBottomSheetState();
}

class _AuthBottomSheetState extends State<_AuthBottomSheet> {
  final TextEditingController _emailCtl = TextEditingController();
  final TextEditingController _passCtl = TextEditingController();
  bool _obscure = true;
  AuthLoading _loading = AuthLoading.none;

  @override
  void dispose() {
    _emailCtl.dispose();
    _passCtl.dispose();
    super.dispose();
  }

  Future<void> _signIn(AuthLoading type) async {
    if (_loading != AuthLoading.none) return;
    setState(() => _loading = type);

    try {
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      // when auth simulation completes, go through feature intro pages
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const FeatureIntroPages()));
    } finally {
      if (mounted) setState(() => _loading = AuthLoading.none);
    }
  }

  Widget _roundedSocialButton({
    required AuthLoading type,
    required String assetPath,
    required String text,
    required Widget fallback,
  }) {
    final bool active = _loading == type;
    final bool disabled = _loading != AuthLoading.none && _loading != type;

    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: disabled ? null : () => _signIn(type),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          switchInCurve: Curves.easeIn,
          child: active
              ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            key: const ValueKey('loading'),
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                ),
              ),
              const SizedBox(width: 10),
              const Text('Signing in...', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700)),
            ],
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            key: const ValueKey('idle'),
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, err, st) {
                    return fallback;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Text(text, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);
    final sheetMaxHeight = mq.size.height * 0.92;

    return DraggableScrollableSheet(
      initialChildSize: 0.68,
      minChildSize: 0.42,
      maxChildSize: 0.95,
      builder: (context, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.28),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: SingleChildScrollView(
            controller: scrollCtrl,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: sheetMaxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/intro_collage.png',
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox.shrink();
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  Center(
                    child: Text(
                      'Sign in',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _roundedSocialButton(
                        type: AuthLoading.google,
                        assetPath: 'assets/images/google_logo.webp',
                        text: 'Continue with Google',
                        fallback: const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 12),

                      _roundedSocialButton(
                        type: AuthLoading.apple,
                        assetPath: 'assets/icons/apple_logo.png',
                        text: 'Continue with Apple',
                        fallback: const Icon(Icons.apple, size: 20, color: Colors.black87),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      const Expanded(child: Divider(color: Colors.black12, thickness: 1)),
                      const SizedBox(width: 10),
                      Text('or', style: TextStyle(color: Colors.black45)),
                      const SizedBox(width: 10),
                      const Expanded(child: Divider(color: Colors.black12, thickness: 1)),
                    ],
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: _emailCtl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: cs.primary, width: 1.6),
                      ),
                      hintText: 'you@example.com',
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: _passCtl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: cs.primary, width: 1.6),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: Colors.black45,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (_loading != AuthLoading.none && _loading != AuthLoading.email)
                          ? null
                          : () => _signIn(AuthLoading.email),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 160),
                        child: _loading == AuthLoading.email
                            ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          key: const ValueKey('email_loading'),
                          children: const [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                            ),
                            SizedBox(width: 10),
                            Text('Signing in...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                          ],
                        )
                            : Text(
                          'Sign in',
                          key: const ValueKey('email_idle'),
                          style: TextStyle(color: cs.onPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Forgot your password?',
                          style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text(
                        'Create a new account',
                        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class FeatureIntroPages extends StatefulWidget {
  const FeatureIntroPages({super.key});

  @override
  State<FeatureIntroPages> createState() => _FeatureIntroPagesState();
}

class _FeatureIntroPagesState extends State<FeatureIntroPages> {
  int _index = 0;

  final List<String> titles = [
    "Scan E-waste",
    "Sell, Repair, Manage",
    "Inventory",
    "Nearby pickup locations",
    "You're all set!"
  ];

  final List<String> descriptions = [
    "Quickly scan e-waste to instantly log devices, get device information, repair suggestions, and recycling guidance",
    "List devices for sale, request repair services, and manage service history from one place.",
    "Keep track of devices, stock levels, and maintenance logs. Organize and search your inventory easily.",
    "Find nearby e-waste collection points, view pickup schedules, and request doorstep pickup where available.",
    "Great — you’ve seen the highlights. Ready to explore Ewise and manage your e-waste the smart way."
  ];

  void _next() {
    if (_index < titles.length - 1) {
      setState(() => _index += 1);
    } else {
      // NAVIGATE TO THE REAL HOME PAGE
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomePage()));
    }
  }

  void _back() {
    if (_index > 0) {
      setState(() => _index -= 1);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final double maxH = constraints.maxHeight;
          const double topBarH = 64.0;
          const double bottomControlsH = 140.0;
          double remaining = (maxH - topBarH - bottomControlsH).clamp(260.0, maxH - topBarH - 80.0);
          double imageArea = (remaining * 0.55).clamp(140.0, 520.0);
          final double contentBlockHeight = (remaining - imageArea).clamp(120.0, 220.0);

          return Column(
            children: [
              SizedBox(
                height: 56,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.black87),
                        onPressed: _back,
                        tooltip: 'Back',
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomePage())),
                        child: Text('Skip', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(
                height: imageArea,
                width: double.infinity,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                  child: SizedBox(
                    key: ValueKey<int>(_index),
                    height: imageArea,
                    width: double.infinity,
                    child: Center(
                      child: SizedBox(
                        width: imageArea * 0.9,
                        height: imageArea * 0.9,
                        // <-- updated here to use assets/images/1.png .. assets/images/5.png
                        child: Image.asset(
                          'assets/images/${_index + 1}.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.broken_image, size: 64, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Image missing', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: contentBlockHeight,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeIn,
                        switchOutCurve: Curves.easeOut,
                        transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                        child: _ContentBlock(
                          key: ValueKey<int>(_index),
                          title: titles[_index],
                          description: descriptions[_index],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: _StaticIndicator(total: titles.length, activeIndex: _index),
                    ),

                    const SizedBox(height: 8),

                    SizedBox(
                      height: 64,
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: FilledButton(
                                onPressed: _next,
                                style: FilledButton.styleFrom(
                                  backgroundColor: cs.primary,
                                  foregroundColor: cs.onPrimary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  _index == titles.length - 1 ? "That's great" : 'Next',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _ContentBlock extends StatelessWidget {
  final String title;
  final String description;

  const _ContentBlock({super.key, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaticIndicator extends StatelessWidget {
  final int total;
  final int activeIndex;

  const _StaticIndicator({super.key, required this.total, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const double dotSize = 10;
    const double gap = 14;

    return SizedBox(
      height: dotSize,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (i) {
          return Container(
            width: dotSize,
            height: dotSize,
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : gap),
            decoration: BoxDecoration(
              color: i == activeIndex ? cs.primary : cs.onSurface.withOpacity(0.36),
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}

class LoginDummyPage extends StatelessWidget {
  const LoginDummyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log in (Dummy)'),
        backgroundColor: Colors.black,
        foregroundColor: cs.primary,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const FeatureIntroPages()),
          ),
          child: const Text('Continue (dummy)'),
        ),
      ),
    );
  }
}
