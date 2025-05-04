import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uni_links/uni_links.dart';
import 'services/auth_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  const secureStorage = FlutterSecureStorage();

  try {
    final initialUri = await getInitialUri();
    if (initialUri != null) {
    }
  } catch (e) {
    debugPrint('Error getting initial uri: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthService(secureStorage),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Civic Auth Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3DB6BA),
          primary: const Color(0xFF3DB6BA),
          secondary: const Color(0xFF0F1E35),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF3DB6BA),
          foregroundColor: Colors.white,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/wallet': (context) => const WalletScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name != null && settings.name!.startsWith('/auth/')) {
          final uri = Uri.parse(settings.name!);
          if (uri.path == '/auth/success') {
            return MaterialPageRoute(
              builder: (context) => const HomeScreen(initialSuccessMessage: 'Authentication successful!'),
            );
          } else if (uri.path == '/auth/error') {
            final errorMessage = uri.queryParameters['message'] ?? 'Authentication failed';
            return MaterialPageRoute(
              builder: (context) => LoginScreen(initialErrorMessage: errorMessage),
            );
          }
        }
        return null;
      },
    );
  }
}