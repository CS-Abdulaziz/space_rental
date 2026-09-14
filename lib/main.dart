import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/auth/signup_page.dart';
import 'screens/renter/renter_home.dart';

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
      home:  SignupPage(),

      routes: {
        '/renter': (context) => 
         RenterHomePage(),

        '/owner': (context) => const PlaceholderPage(
          title: 'Owner Home',
        ),
      },
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text(title),
      ),
    );
  }
}