import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeeklyHostingSummaryPage extends StatefulWidget {
  const WeeklyHostingSummaryPage({super.key});

  @override
  State<WeeklyHostingSummaryPage> createState() => _WeeklyHostingSummaryPageState();
}

class _WeeklyHostingSummaryPageState extends State<WeeklyHostingSummaryPage> {
  List<dynamic> hostingList = [];
  String totalAmount = "0.00";
  int totalCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchWeeklyHostingSummary();
  }

  void fetchWeeklyHostingSummary() async {
    try {
      final response = await http.get(
        Uri.parse('https://servernewapp.rentalsprime.in/api/hosting/weekly-summary'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == true && jsonData['data'] != null) {
          setState(() {
            totalAmount = jsonData['total_amount'] ?? "0.00";
            totalCount = jsonData['count'] ?? 0;
            hostingList = jsonData['data'];
            isLoading = false;
          });
        } else {
          print("API returned no data");
        }
      } else {
        print("Error ${response.statusCode}: Could not fetch summary.");
      }
    } catch (e) {
      print("Exception: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Weekly Hosting Summary',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.indigo,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6, spreadRadius: 2)
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem("Total Hostings", "$totalCount"),
                const VerticalDivider(),
                _buildSummaryItem("Total Amount", "₹$totalAmount"),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: hostingList.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final item = hostingList[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 2),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['company_name'] ?? '—',
                          style: GoogleFonts.notoSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          )),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _infoTag("Hosting", item['hosting_name']),
                          _infoTag("Hosted By", item['hosted_by']),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _infoTag("Amount", "₹${item['amount'] ?? '0.00'}"),
                          _infoTag("Phone", item['phone_no']),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.notoSans(fontSize: 13, color: Colors.grey[600])),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.notoSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
      ],
    );
  }

  Widget _infoTag(String label, String? value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.notoSans(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(value ?? "-", style: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
