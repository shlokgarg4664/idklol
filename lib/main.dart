import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sports_app/ui/root_shell.dart';
import 'package:sports_app/ui/theme/theme_controller.dart';
import 'package:sports_app/ui/auth/login_screen.dart';
import 'package:sports_app/core/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize other services
  await ThemeController.instance.load();
  await UserService().initialize();
  
  // Set up error handling
  FlutterError.onError = (errorDetails) {
    print('Flutter Error: ${errorDetails.exception}');
  };
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([ThemeController.instance, UserService()]),
      builder: (context, _) => Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'SAI Talent Assessment',
              themeMode: ThemeController.instance.themeMode,
              theme: ThemeData(
                brightness: Brightness.light,
                scaffoldBackgroundColor: const Color(0xFFF7F7F7),
                appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
                textTheme: GoogleFonts.firaCodeTextTheme(),
              ),
              darkTheme: ThemeData(
                brightness: Brightness.dark,
                scaffoldBackgroundColor: const Color(0xFF121212),
                appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
                textTheme: GoogleFonts.firaCodeTextTheme(
                  Theme.of(context).textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
                ),
              ),
              home: UserService().isLoggedIn ? const RootShell() : const LoginScreen(),
            ),
            if (ThemeController.instance.isTransitioning)
              Container(
                color: ThemeController.instance.themeMode == ThemeMode.dark 
                    ? const Color(0xFF121212) 
                    : const Color(0xFFF7F7F7),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

