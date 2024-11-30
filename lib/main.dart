import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'welcome_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Supabase.initialize(
    url: 'https://jilwqxsjqajywcguwblb.supabase.co',        // Your Supabase URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImppbHdxeHNqcWFqeXdjZ3V3YmxiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzI5NTQzMDYsImV4cCI6MjA0ODUzMDMwNn0.XO_3KRaCxYjrJIikafCL5mdYtqJKuNLin1kHm_NoKBI', // Your Supabase Anonymous Key
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Firebase Auth',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const WelcomePage(),
      routes: {
        '/dashboard': (context) => const Dashboard(),
      },
    );
  }
}
