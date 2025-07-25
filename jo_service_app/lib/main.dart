import 'package:flutter/material.dart';
import 'package:jo_service_app/screens/provider_detail_screen.dart'; // Added import
import 'package:jo_service_app/services/auth_service.dart'; // Added import
import 'package:jo_service_app/services/theme_service.dart'; // Import ThemeService
import 'package:jo_service_app/services/background_service.dart'; // Import BackgroundService
import 'package:jo_service_app/services/app_lifecycle_manager.dart'; // Import AppLifecycleManager
import 'package:provider/provider.dart'; // Added import
// import 'screens/splash_screen.dart'; // New initial screen // Commented out as SplashScreen is deleted
import './screens/auth_check_screen.dart'; // Import AuthCheckScreen
import './screens/role_selection_screen.dart';
import './screens/user_home_screen.dart';
import './screens/user_profile_screen.dart'; // Import UserProfileScreen
import './screens/provider_dashboard_screen.dart';
import './screens/user_login_screen.dart'; // Import UserLoginScreen
import './screens/provider_login_screen.dart'; // Import ProviderLoginScreen
import './screens/user_signup_screen.dart'; // Import UserSignupScreen
import './screens/provider_signup_screen.dart'; // Import ProviderSignupScreen
import './screens/user_bookings_screen.dart'; // Import UserBookingsScreen
import './screens/provider_bookings_screen.dart'; // Import ProviderBookingsScreen
import './screens/booking_detail_screen.dart'; // Import BookingDetailScreen
import './screens/admin_login_screen.dart'; // Import AdminLoginScreen
import './screens/admin_dashboard_screen.dart'; // Import AdminDashboardScreen
// import './screens/create_booking_screen.dart'; // Import CreateBookingScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize background service
  await BackgroundService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppLifecycleManager _lifecycleManager = AppLifecycleManager();

  @override
  void initState() {
    super.initState();
    // Initialize lifecycle manager
    _lifecycleManager.initialize();
  }

  @override
  void dispose() {
    _lifecycleManager.dispose();
    super.dispose();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Wrap with MultiProvider for multiple services
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()),
        ChangeNotifierProvider(create: (context) => ThemeService()),
      ],
      child: Consumer<ThemeService>(builder: (context, themeService, child) {
        return MaterialApp(
          title: 'Service Marketplace',
          theme: themeService.currentTheme,
          initialRoute:
              AuthCheckScreen.routeName, // Set AuthCheckScreen as initial route
          home: const RoleSelectionScreen(), // Fallback home screen
          onGenerateRoute: (settings) {
            switch (settings.name) {
              // Home route
              case '/':
                return MaterialPageRoute(
                    builder: (_) => const RoleSelectionScreen());
              // case SplashScreen.routeName: // Commented out
              // return MaterialPageRoute(builder: (_) => const SplashScreen()); // Commented out
              // Add your other primary routes here if they don't take arguments
              // For example, if you have a LoginScreen, HomeScreen, etc.
              // case LoginScreen.routeName:
              //   return MaterialPageRoute(builder: (_) => const LoginScreen());
              case AuthCheckScreen.routeName:
                return MaterialPageRoute(
                    builder: (_) => const AuthCheckScreen());
              case RoleSelectionScreen.routeName:
                return MaterialPageRoute(
                    builder: (_) => const RoleSelectionScreen());
              case UserHomeScreen.routeName:
                return MaterialPageRoute(
                    builder: (_) => const UserHomeScreen());
              case UserProfileScreen.routeName: // Add UserProfileScreen route
                return MaterialPageRoute(
                    builder: (_) => const UserProfileScreen());
              case UserBookingsScreen.routeName: // Add UserBookingsScreen route
                return MaterialPageRoute(
                    builder: (_) => const UserBookingsScreen());
              case ProviderBookingsScreen
                    .routeName: // Add ProviderBookingsScreen route
                return MaterialPageRoute(
                    builder: (_) => const ProviderBookingsScreen());
              case ProviderDashboardScreen.routeName:
                return MaterialPageRoute(
                    builder: (_) => const ProviderDashboardScreen());
              case UserLoginScreen.routeName: // Added UserLoginScreen route
                return MaterialPageRoute(
                    builder: (_) => const UserLoginScreen());
              case ProviderLoginScreen
                    .routeName: // Added ProviderLoginScreen route
                return MaterialPageRoute(
                    builder: (_) => const ProviderLoginScreen());
              case UserSignUpScreen.routeName: // Added UserSignUpScreen route
                return MaterialPageRoute(
                    builder: (_) => const UserSignUpScreen());
              case ProviderSignUpScreen
                    .routeName: // Added ProviderSignUpScreen route
                return MaterialPageRoute(
                    builder: (_) => const ProviderSignUpScreen());
              // Admin routes
              case AdminLoginScreen.routeName: // Added AdminLoginScreen route
                return MaterialPageRoute(
                    builder: (_) => const AdminLoginScreen());
              case AdminDashboardScreen.routeName: // Added AdminDashboardScreen route
                return MaterialPageRoute(
                    builder: (_) => const AdminDashboardScreen());
              case ProviderDetailScreen.routeName:
                if (settings.arguments is String) {
                  final providerId = settings.arguments as String;
                  return MaterialPageRoute(
                    builder: (_) =>
                        ProviderDetailScreen(providerId: providerId),
                  );
                } else {
                  // Handle error: incorrect argument type
                  return MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('Error')),
                      body: const Center(
                          child: Text('Invalid arguments for Provider Detail')),
                    ),
                  );
                }
              case BookingDetailScreen.routeName:
                if (settings.arguments is String) {
                  final bookingId = settings.arguments as String;
                  return MaterialPageRoute(
                    builder: (_) => BookingDetailScreen(bookingId: bookingId),
                  );
                } else {
                  // Handle error: incorrect argument type
                  return MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('Error')),
                      body: const Center(
                          child: Text('Invalid arguments for Booking Detail')),
                    ),
                  );
                }
              // Default or unknown route - redirect to role selection
              default:
                // Instead of showing 404, redirect to role selection screen
                return MaterialPageRoute(
                  builder: (_) => const RoleSelectionScreen(),
                );
            }
          },
          debugShowCheckedModeBanner: false,
        );
      }),
    );
  }
}

// MyHomePage is no longer used as the primary entry point for UI content in this setup.
// You can remove it if it's not used elsewhere or keep it if you plan to use it later.
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
