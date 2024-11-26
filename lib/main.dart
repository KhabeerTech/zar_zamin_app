import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zar_zamin_app/firebase_options.dart';
import 'package:zar_zamin_app/sign_in_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Supabase-ni ishga tushirish
    await Supabase.initialize(
      url: 'https://uopouylhjvhosgiyncwy.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVvcG91eWxoanZob3NnaXluY3d5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzI1MTc2NzYsImV4cCI6MjA0ODA5MzY3Nn0.6QLERZMZtXtEm86P4o3in-3_m8DPR3l5aJhJ9BdbrdA',
    );
    debugPrint('Supabase initialized successfully');

    // Firebase-ni ishga tushirish
    final FirebaseApp app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (app.name == '[DEFAULT]') {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    }
  } catch (e, stackTrace) {
    debugPrint('Initialization error: $e');
    debugPrint('Stack trace: $stackTrace');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zar Zamin',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
        ),
        useMaterial3: true,
      ),
      home: const SignInPage(),
    );
  }
}
