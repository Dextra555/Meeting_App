import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../Provider/UserProvider.dart';
import 'dashboardscreen.dart';

class LoginModalScreen extends StatefulWidget {
  const LoginModalScreen({super.key});

  @override
  State<LoginModalScreen> createState() => _LoginModalScreenState();
}

class _LoginModalScreenState extends State<LoginModalScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage("Please enter email and password");
      return;
    }

    setState(() => isLoading = true);

    final url = Uri.parse("https://servernewapp.rentalsprime.in/api/login");

    try {
      // 👉 Get FCM Token
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      print("📌 Sending FCM Token: $fcmToken");

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'fcm_token': fcmToken,
        }),
      );

      print("🔵 Raw response: ${response.body}");
      dynamic responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['status'] == true) {
        print("✅ Login successful");

        final userData = responseBody['data']['team_member'];
        final token = responseBody['data']['token'];

        // ➤ Save in Provider
        Provider.of<UserProvider>(context, listen: false)
            .setUserData(userData, token);

        // ➤ Save in SharedPreferences for Auto Login
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("userData", jsonEncode(userData));
        await prefs.setString("token", token);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        _showMessage(responseBody['message'] ?? "Login failed");
      }
    } catch (e) {
      _showMessage("Something went wrong: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.3),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/bg.jpg', fit: BoxFit.cover),

          Positioned(
            top: 30,
            left: 10,
            child: Image.asset(
              'assets/img.png',
              width: 150,
              height: 190,
            ),
          ),

          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 400),
              child: Column(
                children: [
                  Card(
                    color: Colors.white.withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: SizedBox(
                        width: 300,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Welcome Back!',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 10),
                            const Text('Login',
                                style: TextStyle(
                                    fontSize: 26, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 20),
                            TextField(
                              controller: emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(height: 15),
                            TextField(
                              controller: passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 12),
                                child: Text("Login"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
