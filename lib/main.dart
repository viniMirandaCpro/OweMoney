import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/home_page.dart';

/// Entry point for the OweMoney app
/// 
/// This app helps you track who owes you money and who you owe money to
/// with a clean, Apple-inspired interface and local database persistence
void main() {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style for iOS-like appearance
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const MyApp());
}

/// Root widget of the application
/// 
/// Configures the MaterialApp with Apple-inspired theming
/// following the Human Interface Guidelines
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OweMoney',
      debugShowCheckedModeBanner: false,
      
      // Apple-inspired theme with clean, modern aesthetics
      theme: ThemeData(
        // Use iOS blue as primary color
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF),
          brightness: Brightness.light,
        ),
        
        // SF Pro-inspired typography
        fontFamily: '.SF Pro Text',
        
        // Use Material 3 design system
        useMaterial3: true,
        
        // AppBar theme
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        
        // FAB theme
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 4,
          shape: CircleBorder(),
        ),
      ),
      
      home: const HomePage(),
    );
  }
}
