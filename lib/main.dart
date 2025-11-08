import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import './login_screen.dart';
import 'dart:io';
import 'package:path/path.dart';

void main() async {
  // Ensure that Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for sqflite on desktop
  sqfliteFfiInit();
  
  // Force deletion of the old, corrupted database file
  try {
    var databasesPath = await getDatabasesPath();
    String oldPath = join(databasesPath, 'tasks_database.db');
    File oldDbFile = File(oldPath);
    if (await oldDbFile.exists()) {
      await oldDbFile.delete();
      print("Old database deleted.");
    }
  } catch (e) {
    print("Error deleting old database: $e");
  }

  databaseFactory = databaseFactoryFfi;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF311B92),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: Colors.grey[850],
          elevation: 1.0,
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
