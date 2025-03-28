import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'Admin/all_user_screen.dart';
import 'Views/calenderScreen.dart';
import 'Views/loginscreen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AllUserScreen(),
      builder: BotToastInit(), //1. call BotToastInit
      navigatorObservers: [BotToastNavigatorObserver()],
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const platform = MethodChannel('com.example.app/service');

  String statusMessage = "Checking permissions...";

  @override
  void initState() {
    super.initState();
    checkPermissions();
  }

  Future<void> checkPermissions() async {
    try {
      final bool permissionsGranted = await platform.invokeMethod('checkPermissions');
      setState(() {
        statusMessage = permissionsGranted
            ? "All permissions are granted. You can start the service."
            : "Some permissions are missing. Please grant all required permissions.";
      });
    } on PlatformException catch (e) {
      setState(() {
        statusMessage = "Failed to check permissions: ${e.message}";
      });
    }
  }

  Future<void> startService() async {
    try {
      final bool permissionsGranted = await platform.invokeMethod('checkPermissions');
      if (permissionsGranted) {
        await platform.invokeMethod('startSilentService');
        setState(() {
          statusMessage = "Service started successfully!";
        });
      } else {
        setState(() {
          statusMessage = "Cannot start service. Missing permissions!";
        });
      }
    } on PlatformException catch (e) {
      setState(() {
        statusMessage = "Error: ${e.message}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Silent Background Service')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                statusMessage,
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: checkPermissions,
                child: Text('Check Permissions'),
              ),
              ElevatedButton(
                onPressed: startService,
                child: Text('Start Silent Background Service'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
