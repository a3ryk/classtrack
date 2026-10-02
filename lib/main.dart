import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_theme.dart';
import 'core/ui/theme_transition_wrapper.dart';
import 'presentation/providers/app_state_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/app_theme_style_provider.dart';
import 'presentation/screens/main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ),
  );
  runApp(
    const ProviderScope(
      child: AttendlyApp(),
    ),
  );
}

class AttendlyApp extends ConsumerWidget {
  const AttendlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final themeStyle = ref.watch(appThemeStyleProvider);
    final initAsync = ref.watch(appInitializationProvider);

    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);

    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );

    SystemChrome.setSystemUIOverlayStyle(overlayStyle);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: MaterialApp(
        title: 'Attendly',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.buildTheme(styleId: themeStyle, brightness: Brightness.light),
        darkTheme: AppTheme.buildTheme(styleId: themeStyle, brightness: Brightness.dark),
        themeMode: themeMode,
        themeAnimationDuration: Duration.zero,
        locale: const Locale('en', 'IN'),
        supportedLocales: const [
          Locale('en', 'IN'),
          Locale('en', 'GB'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => ThemeTransitionWrapper(
          child: child ?? const SizedBox.shrink(),
        ),
        home: _AppLaunchGate(
          initAsync: initAsync,
          child: const MainShell(),
        ),
      ),
    );
  }
}

class _AppLaunchGate extends StatefulWidget {
  final AsyncValue<bool> initAsync;
  final Widget child;

  const _AppLaunchGate({
    required this.initAsync,
    required this.child,
  });

  @override
  State<_AppLaunchGate> createState() => _AppLaunchGateState();
}

class _AppLaunchGateState extends State<_AppLaunchGate> {
  static const MethodChannel _splashChannel = MethodChannel('com.attendly/splash');
  bool _dismissSent = false;

  void _notifyReady() {
    if (_dismissSent) return;
    _dismissSent = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _splashChannel.invokeMethod('dismissSplash').catchError((_) {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final isReady = widget.initAsync.hasValue || widget.initAsync.hasError;

    if (isReady) {
      _notifyReady();
    }

    return widget.child;
  }
}

/// Backward compatibility alias for tests and existing integrations
typedef ClasstrackApp = AttendlyApp;
