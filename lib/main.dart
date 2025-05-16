import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:rexplore/firebase_service.dart';
import 'package:rexplore/pages/home_page.dart';
import 'package:rexplore/pages/landing_page.dart';
import 'package:rexplore/services/ThemeProvider.dart';
import 'package:rexplore/theme.dart/darkTheme.dart';
import 'package:rexplore/theme.dart/lightTheme.dart';
import 'package:rexplore/viewmodel/yt_videoview_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

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
      home: const HomePage(),
    );
  }
}
