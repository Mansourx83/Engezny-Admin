import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutterfirebase/auth/login.dart';
import 'package:flutterfirebase/firebase_options.dart';
import 'package:flutterfirebase/view/veiw_statioon.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
      } else {
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          fontFamily: "LamaSans",
          primaryColor: Colors.blue,
          textSelectionTheme: TextSelectionThemeData(
              selectionColor: Colors.blue,
              cursorColor: Colors.blue,
              selectionHandleColor: Colors.blue)),
      builder: (context, widget) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: widget!,
        );
      },
      debugShowCheckedModeBanner: false,
      home: FirebaseAuth.instance.currentUser == null
          ? const LogIn()
          : const StationName(),
      routes: {
        "login": (context) => const LogIn(),
        "homepage": (context) => const StationName(),
      },
    );
  }
}
