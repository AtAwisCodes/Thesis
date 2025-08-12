import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:rexplore/firebase_service.dart';
import 'package:rexplore/pages/landing_page.dart';
import 'package:rexplore/services/ThemeProvider.dart';
import 'package:rexplore/theme.dart/darkTheme.dart';
import 'package:rexplore/theme.dart/lightTheme.dart';
import 'package:rexplore/viewmodel/yt_videoview_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Supabase.initialize(
    url: "https://dsvxzjwnxwfcbxsljxdl.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRzdnh6andueHdmY2J4c2xqeGRsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ5MDUyNjAsImV4cCI6MjA3MDQ4MTI2MH0.2TXC0QaAAswrgqO_Mz78at0FUlLOWLziRgrUqnzLQGY",
  );

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
      home: const LandingPage(),
    );
  }
}
