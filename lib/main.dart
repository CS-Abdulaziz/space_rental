import 'package:flutter/material.dart';
import 'package:space_rental/screens/auth/signup_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/welcome_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yricmfxnruipcgfrmozq.supabase.co',
    anonKey: 'sb_publishable_2B4zCj5Eef11BzV7VCPGfw_19OsV4Lb',
  );

  runApp(const SpaceOraApp());
}

class SpaceOraApp extends StatelessWidget {
  const SpaceOraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SpaceOra',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const SignupPage(),
    );
  }
}