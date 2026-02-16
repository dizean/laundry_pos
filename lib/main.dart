import 'package:flutter/material.dart';
import 'package:laundry_pos/layout.dart';
import 'package:provider/provider.dart';
import 'screens/login.dart';
// import 'screens/dashboard.dart';
import 'helpers/session.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:laundry_pos/service/main.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON']!,
  );
  runApp(
    MultiProvider(providers: [
        Provider(create: (_) => CustomerService()),
        Provider(create: (_) => OrderService()),
        Provider(create: (_) => ProductService()),
        Provider(create: (_) => ServiceService()),
        Provider(create: (_) => PackageService()),
      ],
    child: const MyApp(),
    ),
    );
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Laundry POS',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),

      // Decide which screen to show
      home: userSession.isLoggedIn
          ? const MainLayout()
          : const LoginScreen(),
    );
  }
}
