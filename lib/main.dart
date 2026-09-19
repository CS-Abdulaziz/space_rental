import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/auth/login_page.dart';
import 'screens/auth/signup_page.dart';
import 'screens/renter/renter_home.dart';
import 'screens/owner/owner_home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

await dotenv.load(fileName: '.env');

final supabaseUrl = dotenv.env['supabase_url']?.trim();
final supabaseKey = dotenv.env['supabase_key'];

debugPrint('KEY VALUE: $supabaseKey');
debugPrint('KEY LENGTH: ${supabaseKey?.length}');

if (supabaseUrl == null || supabaseUrl.isEmpty) {
  throw Exception('Supabase URL is missing');
}

if (supabaseKey == null || supabaseKey.isEmpty) {
  throw Exception('Supabase Key is missing');
}

await Supabase.initialize(
  url: supabaseUrl,
  publishableKey: supabaseKey,
);

//<<<<<<< HEAD

//=======
//>>>>>>> 27c0810844d66c0ea0fc4e639b5b4c51ae8f6950

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
        '/signup': (context) => SignupPage(),
      },
    );
  }
}