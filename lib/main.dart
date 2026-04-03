import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const PureFocusApp());
}

class PureFocusApp extends StatelessWidget {
  const PureFocusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PureFocus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5C3D99),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// ─── SPLASH ──────────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 1800), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const PureFocusHome(),
        transitionDuration: const Duration(milliseconds: 700),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0816),
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'PURE',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 14,
                  color: const Color(0xFFB0B7E8).withAlpha(230),
                ),
              ),
              Text(
                'focus',
                style: TextStyle(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 8,
                  color: const Color(0xFFB0B7E8).withAlpha(115),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── MAIN HOME ────────────────────────────────────────────────────────────────
class PureFocusHome extends StatefulWidget {
  const PureFocusHome({super.key});

  @override
  State<PureFocusHome> createState() => _PureFocusHomeState();
}

class _PureFocusHomeState extends State<PureFocusHome>
    with WidgetsBindingObserver {
  InAppWebViewController? _webCtrl;

  // Tracks whether JS has signalled the app is interactive
  bool _appReady = false;

  // Pre-loaded HTML — avoids blank WebView frame on first render
  String? _htmlContent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _preloadHtml();
    _requestPermissions();
  }

  Future<void> _preloadHtml() async {
    try {
      final html = await rootBundle.loadString('assets/purefocus.html');
      if (mounted) setState(() => _htmlContent = html);
    } catch (e) {
      debugPrint('PureFocus: failed to load HTML asset — $e');
    }
  }

  Future<void> _requestPermissions() async {
    await Permission.notification.request();
  }

  void _handleWakelock(bool enable) {
    try {
      enable ? WakelockPlus.enable() : WakelockPlus.disable();
    } catch (e) {
      debugPrint('PureFocus: wakelock error — $e');
    }
  }

  // Handlers registered BEFORE loadData — fixes race condition
  void _registerJsHandlers(InAppWebViewController ctrl) {
    ctrl.addJavaScriptHandler(
      handlerName: 'wakelockEnable',
      callback: (_) => _handleWakelock(true),
    );
    ctrl.addJavaScriptHandler(
      handlerName: 'wakelockDisable',
      callback: (_) => _handleWakelock(false),
    );
    ctrl.addJavaScriptHandler(
      handlerName: 'appReady',
      callback: (_) {
        if (mounted) setState(() => _appReady = true);
      },
    );
  }

  // Injection wrapped in IIFE + DOMContentLoaded guard
  // Null-checks all functions before hooking to avoid overwrite errors
  static const String _jsInjection = r'''
(function() {
  function init() {
    window._pfWakelockEnable = function() {
      try { window.flutter_inappwebview.callHandler('wakelockEnable'); } catch(e) {}
    };
    window._pfWakelockDisable = function() {
      try { window.flutter_inappwebview.callHandler('wakelockDisable'); } catch(e) {}
    };

    var origStart = window.startTimer;
    window.startTimer = function() {
      if (typeof origStart === 'function') origStart.apply(this, arguments);
      window._pfWakelockEnable();
    };

    var origEnd = window.endSession;
    window.endSession = function() {
      if (typeof origEnd === 'function') origEnd.apply(this, arguments);
      window._pfWakelockDisable();
    };

    var origReset = window.resetTimer;
    window.resetTimer = function() {
      if (typeof origReset === 'function') origReset.apply(this, arguments);
      window._pfWakelockDisable();
    };

    try { window.flutter_inappwebview.callHandler('appReady'); } catch(e) {}
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
''';

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_htmlContent == null) {
      return const _LoadingScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0816),
      body: Stack(
        children: [
          InAppWebView(
            initialData: InAppWebViewInitialData(
              data: _htmlContent!,
              mimeType: 'text/html',
              encoding: 'utf-8',
              baseUrl: WebUri(
                'file:///android_asset/flutter_assets/assets/',
              ),
            ),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              mediaPlaybackRequiresUserGesture: false,
              allowFileAccessFromFileURLs: true,
              allowUniversalAccessFromFileURLs: true,
              transparentBackground: true,
              verticalScrollBarEnabled: false,
              horizontalScrollBarEnabled: false,
              supportZoom: false,
              builtInZoomControls: false,
              displayZoomControls: false,
              useWideViewPort: true,
              loadWithOverviewMode: true,
              disableLongPressContextMenuOnLinks: true,
              useHybridComposition: true,
            ),
            onWebViewCreated: (ctrl) {
              _webCtrl = ctrl;
              // Register handlers before page starts loading
              _registerJsHandlers(ctrl);
            },
            onLoadStop: (ctrl, url) async {
              // Skip injection on about:blank (initial empty frame)
              final urlStr = url?.toString() ?? '';
              if (urlStr == 'about:blank' || urlStr.isEmpty) return;
              await ctrl.evaluateJavascript(source: _jsInjection);
            },
            onReceivedError: (ctrl, request, error) {
              debugPrint(
                'PureFocus WebView error [${error.type}]: ${error.description}',
              );
            },
          ),

          // Smooth fade-out once JS fires appReady
          AnimatedOpacity(
            opacity: _appReady ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 600),
            child: IgnorePointer(
              ignoring: _appReady,
              child: const _LoadingScreen(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── LOADING SCREEN ───────────────────────────────────────────────────────────
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0816),
      child: Center(
        child: Text(
          'purefocus',
          style: TextStyle(
            fontSize: 16,
            letterSpacing: 6,
            fontStyle: FontStyle.italic,
            color: const Color(0xFFB0B7E8).withAlpha(100),
          ),
        ),
      ),
    );
  }
}
