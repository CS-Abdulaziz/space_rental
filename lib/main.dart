import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/auth/login_page.dart';
import 'screens/auth/signup_page.dart';
import 'screens/renter/renter_home.dart';
import 'screens/owner/owner_home.dart';

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
        brightness: Brightness.light,
        useMaterial3: true,
        fontFamily: 'Georgia',
      ),

      home: SignupPage(),

      routes: {
        '/renter': (context) => RenterHomePage(),

        '/login': (context) => LoginPage(),

        '/owner': (context) => const OwnerHomePage(),
        '/signup':(context) => SignupPage(),
      },
    );
  }
}