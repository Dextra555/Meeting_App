import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<dynamic> expiringToday = [];
  List<dynamic> clientFollowUps = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    final url = 'https://servernewapp.rentalsprime.in/api/notifications/today';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == true) {
          setState(() {
            expiringToday = jsonData['expiring_today'] ?? [];
            clientFollowUps = jsonData['client_followups'] ?? [];
            isLoading = false;
          });
        }
      } else {
        print("Failed to load notifications. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching notifications: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications', style: GoogleFonts.notoSans(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey.shade100,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (expiringToday.isNotEmpty) ...[
            Text("Expiring Today", style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...expiringToday.map((item) => _buildNotificationCard(
              title: "Hosting Expiry",
              message: "${item['company_name']} hosting is expiring today.",
              time: item['expiring_date'],
              icon: Icons.warning_amber_rounded,
            )),
            const SizedBox(height: 20),
          ],
          if (clientFollowUps.isNotEmpty) ...[
            Text("Client Follow-Ups", style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...clientFollowUps.map((item) => _buildNotificationCard(
              title: "Follow-Up Due",
              message: "Follow-up required for ${item['company_name']} (Client).",
              time: item['expiring_date'],
              icon: Icons.people_alt_outlined,
            )),
          ],
          if (expiringToday.isEmpty && clientFollowUps.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Text(
                  "No notifications for today.",
                  style: GoogleFonts.notoSans(fontSize: 15, color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String message,
    required String time,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: Colors.indigo),
        title: Text(title, style: GoogleFonts.notoSans(fontWeight: FontWeight.bold)),
        subtitle: Text(message, style: GoogleFonts.notoSans(fontSize: 13)),
        trailing: Text(time, style: GoogleFonts.notoSans(color: Colors.grey, fontSize: 11)),
      ),
    );
  }

}
