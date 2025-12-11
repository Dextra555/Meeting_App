// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// class FollowUpsPage extends StatelessWidget {
//   final List<Map<String, String>> followUps = [
//     {
//       'title': 'Devon Lane',
//       'content': 'Discuss domain renewal pricing options.',
//       'time': 'Today, 10:30 AM',
//       'enquiry': 'Web Hosting'
//     },
//     {
//       'title': 'Floyd Miles',
//       'content': 'Talk about new feature request.',
//       'time': 'Next Week, Tue',
//       'enquiry': 'Mobile App'
//     },
//     {
//       'title': 'Dianne Russell',
//       'content': 'Send updated quotation.',
//       'time': 'Upcoming, 20 July',
//       'enquiry': 'UI/UX Design'
//     },
//   ];
//
//   Widget _buildClientMessage({
//     required String title,
//     required String content,
//     required String time,
//     String enquiry = "Web Application",
//   }) {
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 6),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       elevation: 1,
//       color: Colors.white,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Expanded(
//                   child: Text(
//                     title,
//                     style: GoogleFonts.notoSans(fontWeight: FontWeight.bold, fontSize: 13),
//                   ),
//                 ),
//                 Row(
//                   children: [
//                     IconButton(
//                       icon: const Icon(Icons.edit_outlined, size: 14),
//                       onPressed: () {
//                         // handle edit
//                       },
//                     ),
//                     const SizedBox(width: 6),
//                     const Icon(Icons.call, color: Colors.green, size: 14),
//                   ],
//                 ),
//               ],
//             ),
//             Text(
//               "Enquiry: $enquiry",
//               style: GoogleFonts.notoSans(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.w500),
//             ),
//             const SizedBox(height: 4),
//             Text(content, style: GoogleFonts.notoSans(fontSize: 12)),
//             const SizedBox(height: 2),
//             Text(time, style: GoogleFonts.notoSans(color: Colors.grey, fontSize: 10)),
//           ],
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           "All Follow Ups",
//           style: GoogleFonts.poppins(
//             color: Colors.white,
//             fontWeight: FontWeight.w600,
//             fontSize: 16,
//           ),
//         ),
//         iconTheme: IconThemeData(color: Colors.white),
//         backgroundColor: Colors.indigo,
//       ),
//
//
//       backgroundColor: Colors.white,
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           Text("Today", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
//           const SizedBox(height: 6),
//           _buildClientMessage(
//             title: followUps[0]['title']!,
//             content: followUps[0]['content']!,
//             time: followUps[0]['time']!,
//             enquiry: followUps[0]['enquiry']!,
//           ),
//           const SizedBox(height: 16),
//           Text("Next Week", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
//           const SizedBox(height: 6),
//           _buildClientMessage(
//             title: followUps[1]['title']!,
//             content: followUps[1]['content']!,
//             time: followUps[1]['time']!,
//             enquiry: followUps[1]['enquiry']!,
//           ),
//           const SizedBox(height: 16),
//           Text("Upcoming Weeks", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
//           const SizedBox(height: 6),
//           _buildClientMessage(
//             title: followUps[2]['title']!,
//             content: followUps[2]['content']!,
//             time: followUps[2]['time']!,
//             enquiry: followUps[2]['enquiry']!,
//           ),
//         ],
//       ),
//     );
//   }
// }


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class FollowUpsPage extends StatefulWidget {
  const FollowUpsPage({super.key});

  @override
  State<FollowUpsPage> createState() => _FollowUpsPageState();
}

class _FollowUpsPageState extends State<FollowUpsPage> {
  List<dynamic> today = [];
  List<dynamic> nextWeek = [];
  List<dynamic> upcoming = [];

  @override
  void initState() {
    super.initState();
    _fetchFollowUps();
  }

  Future<void> _fetchFollowUps() async {
    final url = Uri.parse("https://servernewapp.rentalsprime.in/api/enquiries");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        final now = DateTime.now();
        final todayDate = DateTime(now.year, now.month, now.day);

        List<dynamic> todayList = [];
        List<dynamic> nextWeekList = [];
        List<dynamic> upcomingList = [];

        for (var item in data) {
          final rawDate = item['follow_up'];
          if (rawDate == null) continue;

          final parsed = DateTime.tryParse(rawDate);
          if (parsed == null) continue;

          final followDate = DateTime(parsed.year, parsed.month, parsed.day);
          final difference = followDate.difference(todayDate).inDays;

          if (difference == 0) {
            todayList.add(item);
          } else if (difference > 0 && difference <= 7) {
            nextWeekList.add(item);
          } else if (difference > 7) {
            upcomingList.add(item);
          }
        }

        setState(() {
          today = todayList;
          nextWeek = nextWeekList;
          upcoming = upcomingList;
        });
      }
    } catch (e) {
      //print("❌ Error: $e");
    }
  }

  Widget _buildClientMessage({
    required String title,
    required String content,
    required String time,
    required String enquiry,
    required String type,
    required String status,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Name & Action Icons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.notoSans(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 14),
                      onPressed: () {
                        // handle edit
                      },
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.call, color: Colors.green, size: 14),
                  ],
                ),
              ],
            ),

            // 🔹 Company
            Text(
              content,
              style: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),

            // 🔹 Enquiry
            Text(
              "Enquiry: $enquiry",
              style: GoogleFonts.notoSans(fontSize: 11, color: Colors.blue),
            ),

            // 🔹 Type
            Text(
              "Type: $type",
              style: GoogleFonts.notoSans(fontSize: 11, color: Colors.indigo),
            ),

            // 🔹 Status
            Text(
              "Status: $status",
              style: GoogleFonts.notoSans(fontSize: 11, color: Colors.orange),
            ),

            const SizedBox(height: 4),

            // 🔹 Follow-up Date
            Text(
              time,
              style: GoogleFonts.notoSans(color: Colors.grey, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<dynamic> data) {
    if (data.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        ...data.map((item) => _buildClientMessage(
          title: item['name'] ?? '',
          content: item['company_name'] ?? '',
          time: item['follow_up'] ?? '',
          enquiry: item['enquiry'] ?? '',
          type: item['type'] ?? '',
          status: item['status'] ?? '',
        )),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("All Follow Ups",
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.indigo,
      ),
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _fetchFollowUps,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection("Today", today),
            _buildSection("Next Week", nextWeek),
            _buildSection("Upcoming Weeks", upcoming),
          ],
        ),
      ),
    );
  }
}

