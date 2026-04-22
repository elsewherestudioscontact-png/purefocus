import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5C3D99), brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const PureFocusHome(),
    );
  }
}

class PureFocusHome extends StatefulWidget {
  const PureFocusHome({super.key});
  @override
  State<PureFocusHome> createState() => _PureFocusHomeState();
}

class _PureFocusHomeState extends State<PureFocusHome> {
  bool _appReady = false;
  String? _htmlContent;

  @override
  void initState() {
    super.initState();
    _preloadHtml();
    Permission.notification.request();
  }

  Future<void> _preloadHtml() async {
    try {
      final html = await rootBundle.loadString('assets/purefocus.html');
      if (mounted) setState(() => _htmlContent = html);
    } catch (e) {
      debugPrint('PureFocus: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_htmlContent == null) return const _LoadingScreen();
    return Scaffold(
      backgroundColor: const Color(0xFF0A0816),
      body: Stack(children: [
        InAppWebView(
          initialData: InAppWebViewInitialData(
            data: _htmlContent!,
            mimeType: 'text/html',
            encoding: 'utf-8',
            baseUrl: WebUri('file:///android_asset/flutter_assets/assets/'),
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
            useWideViewPort: true,
            loadWithOverviewMode: true,
            useHybridComposition: true,
          ),
          onWebViewCreated: (ctrl) {
            ctrl.addJavaScriptHandler(
              handlerName: 'appReady',
              callback: (_) { if (mounted) setState(() => _appReady = true); },
            );
          },
          onLoadStop: (ctrl, url) async {
  if (mounted) setState(() => _appReady = true);
},
        ),
        AnimatedOpacity(
          opacity: _appReady ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 600),
          child: IgnorePointer(ignoring: _appReady, child: const _LoadingScreen()),
        ),
      ]),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0816),
      child: Center(
        child: Text('purefocus',
          style: TextStyle(fontSize: 16, letterSpacing: 6, fontStyle: FontStyle.italic,
            color: const Color(0xFFB0B7E8).withAlpha(100))),
      ),
    );
  }
}
