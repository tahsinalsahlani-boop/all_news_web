import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'utils/theme.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ArabicNewsApp());
}

class ArabicNewsApp extends StatelessWidget {
  const ArabicNewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'شكوماكو',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      builder: (context, child) {
        // Apply RTL directionality to the whole app
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
      // Automatically uses native-like transitions for iOS and Android
      home: const HomeScreen(),
    );
  }
}
