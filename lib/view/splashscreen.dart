import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'dashboardscreen.dart';
import 'loginview.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    getToken();
    _checkLoginStatus();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("🔔 Foreground message received: ${message.notification?.title}");
    });
  }

  void getToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    print("📌 FCM Token: $token");
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    String? user = prefs.getString("userData");

    await Future.delayed(const Duration(seconds: 2)); // splash delay

    if (token != null && user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginModalScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/bg.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: Image.asset(
              'assets/img.png',
              width: 160,
              height: 110,
            ),
          ),
        ],
      ),
    );
  }
}
