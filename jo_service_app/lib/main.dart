import 'package:flutter/material.dart';
import 'package:jo_service_app/screens/provider_detail_screen.dart'; // Added import
import 'package:jo_service_app/services/auth_service.dart'; // Added import
import 'package:provider/provider.dart'; // Added import
// import 'screens/splash_screen.dart'; // New initial screen // Commented out as SplashScreen is deleted
import './screens/auth_check_screen.dart'; // Import AuthCheckScreen
import './screens/role_selection_screen.dart';
import './screens/user_home_screen.dart';
import './screens/provider_dashboard_screen.dart';
import './screens/user_login_screen.dart'; // Import UserLoginScreen
import './screens/provider_login_screen.dart'; // Import ProviderLoginScreen
import './screens/user_signup_screen.dart'; // Import UserSignupScreen
import './screens/provider_signup_screen.dart'; // Import ProviderSignupScreen
// Import other screens that might be navigated to via onGenerateRoute if they have arguments
// For example, UserLoginScreen, ProviderLoginScreen, etc. if they take args or you want explicit case for them.

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Wrap with ChangeNotifierProvider for AuthService
    return ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: MaterialApp(
        title: 'Service Marketplace',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          colorScheme:
              ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(
            secondary: Colors.amber, // Example secondary color
            primaryContainer: Colors.blue[100],
            onPrimaryContainer: Colors.blue[900],
          ),
        ),
        // home: const SplashScreen(), // We will use initialRoute or onGenerateRoute for splash logic
        initialRoute:
            AuthCheckScreen.routeName, // Set AuthCheckScreen as initial route
        onGenerateRoute: (settings) {
          switch (settings.name) {
            // case SplashScreen.routeName: // Commented out
            // return MaterialPageRoute(builder: (_) => const SplashScreen()); // Commented out
            // Add your other primary routes here if they don't take arguments
            // For example, if you have a LoginScreen, HomeScreen, etc.
            // case LoginScreen.routeName:
            //   return MaterialPageRoute(builder: (_) => const LoginScreen());
            case AuthCheckScreen.routeName:
              return MaterialPageRoute(builder: (_) => const AuthCheckScreen());
            case RoleSelectionScreen.routeName:
              return MaterialPageRoute(
                  builder: (_) => const RoleSelectionScreen());
            case UserHomeScreen.routeName:
              return MaterialPageRoute(builder: (_) => const UserHomeScreen());
            case ProviderDashboardScreen.routeName:
              return MaterialPageRoute(
                  builder: (_) => const ProviderDashboardScreen());
            case UserLoginScreen.routeName: // Added UserLoginScreen route
              return MaterialPageRoute(builder: (_) => const UserLoginScreen());
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
            case ProviderDetailScreen.routeName:
              if (settings.arguments is String) {
                final providerId = settings.arguments as String;
                return MaterialPageRoute(
                  builder: (_) => ProviderDetailScreen(providerId: providerId),
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
            // Add cases for other screens if they need to be handled by onGenerateRoute,
            // especially if they take arguments (like UserLoginScreen, ProviderLoginScreen, etc.)
            // Example:
            // case UserLoginScreen.routeName: // Assuming UserLoginScreen has a routeName
            //   return MaterialPageRoute(builder: (_) => const UserLoginScreen());
            // Default or unknown route
            default:
              // You can navigate to a 404 page or a default screen
              return MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Page Not Found')),
                  body: const Center(
                      child: Text('Sorry, this page doesn\'t exist.')),
                ),
              );
          }
        },
        debugShowCheckedModeBanner: false,
      ),
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
