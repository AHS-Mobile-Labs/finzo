import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/finance_provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/database_service.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  if (Platform.isAndroid) {
    await DatabaseService.migrateToPublicStorage();
  }

  final onboarded = await DatabaseService.isOnboarded();

  runApp(FinzoApp(onboarded: onboarded));
}

class FinzoApp extends StatefulWidget {
  final bool onboarded;
  const FinzoApp({super.key, required this.onboarded});

  @override
  State<FinzoApp> createState() => _FinzoAppState();
}

class _FinzoAppState extends State<FinzoApp> {
  late bool _onboarded;

  @override
  void initState() {
    super.initState();
    _onboarded = widget.onboarded;
  }

  void _completeOnboarding() async {
    await DatabaseService.markOnboarded();
    setState(() => _onboarded = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_onboarded) {
      return MaterialApp(
        title: 'Finzo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: OnboardingScreen(onComplete: _completeOnboarding),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => FinanceProvider()..init(),
      child: MaterialApp(
        title: 'Finzo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const HomeScreen(),
      ),
    );
  }
}
