import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'core/layout/root_layout.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Üst bildirim çubuğunu şeffaf ve açık renkli metinlere uygun hale getiriyoruz
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const FitpulseApp());
}

class FitpulseApp extends StatelessWidget {
  const FitpulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitpulse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      // Ana iskeletimizi burada çağırıyoruz
      home: const RootLayout(),
    );
  }
}
