import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:rexplore/firebase_service.dart';
import 'package:rexplore/pages/auth_page.dart';
import 'package:rexplore/services/ThemeProvider.dart';
import 'package:rexplore/theme.dart/darkTheme.dart';
import 'package:rexplore/theme.dart/lightTheme.dart';
import 'package:rexplore/utilities/disposable_email_checker.dart';
import 'package:rexplore/viewmodel/yt_videoview_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  cameras = await availableCameras();

  // Initialize Supabase and Firebase
  await Supabase.initialize(
    url: 'https://ynjqcaxxofteqfbcnbpy.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InluanFjYXh4b2Z0ZXFmYmNuYnB5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ5OTUzNDEsImV4cCI6MjA3MDU3MTM0MX0.mSqnKhqSmrICZ5B2iCDcQgeOLF3xCgC1MnMnF1FbzMM',
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Load disposable email domains
  await DisposableEmailChecker.loadDisposableDomains();

  GetIt.instance.registerSingleton<FirebaseService>(FirebaseService());
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => YtVideoviewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const AuthPage(),
    );
  }
}
