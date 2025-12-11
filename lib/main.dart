import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'Provider/UserProvider.dart';
import 'view/splashscreen.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("🔔 Background message received: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  NotificationSettings settings =
  await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);

  print('User granted permission: ${settings.authorizationStatus}');

  String? token = await FirebaseMessaging.instance.getToken();
  print("FCM Token: $token");

  // ⬇️ Read saved login data
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? storedUser = prefs.getString("userData");
  String? storedToken = prefs.getString("token");
  Map<String, dynamic>? loadedUser = storedUser != null ? jsonDecode(storedUser) : null;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserProvider()..setUserDataIfExists(loadedUser, storedToken),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
  GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 Foreground message received: ${message.notification?.title}');
      if (message.notification != null) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(message.notification!.title ?? 'No Title')),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 Notification clicked: ${message.notification?.title}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'Splash to Login',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
