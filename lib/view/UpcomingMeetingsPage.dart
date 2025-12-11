import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class UpcomingMeetingsPage extends StatefulWidget {
  const UpcomingMeetingsPage({super.key});

  @override
  State<UpcomingMeetingsPage> createState() => _UpcomingMeetingsPageState();
}

class _UpcomingMeetingsPageState extends State<UpcomingMeetingsPage> {
  List<dynamic> meetings = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchMeetings();
  }

  Future<void> fetchMeetings() async {
    try {
      final url = Uri.parse("https://servernewapp.rentalsprime.in/api/meetings");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          meetings = data;
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Upcoming Meetings", style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.indigo,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : meetings.isEmpty
          ? Center(child: Text("No upcoming meetings", style: GoogleFonts.poppins()))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: meetings.length,
        itemBuilder: (_, i) {
          final m = meetings[i];

          final List<dynamic> mandatoryMembers = m["team_members"] ?? [];
          final List<dynamic> optionalMembers = m["optional_team_members"] ?? [];
          final List<dynamic> teams = m["teams"] ?? [];

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(m["title"], style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                  Text(m["meeting_type"].toString().toUpperCase(),
                      style: GoogleFonts.poppins(color: Colors.grey)),
                ]),
                Text("Date: ${m["date"]}",
                    style: GoogleFonts.poppins(color: Colors.grey)),
                const SizedBox(height: 10),
                Text("Time: ${m["start_time"]} - ${m["end_time"]}",
                    style: GoogleFonts.poppins(color: Colors.grey)),
                SizedBox(height: 10),


                /// Mandatory Members
                Text("Attendees:",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                Wrap(
                  spacing: 8,
                  children: mandatoryMembers
                      .map(
                        (e) => Chip(
                      label: Text(e["name"]),
                      backgroundColor: Colors.blue.shade100,
                    ),
                  )
                      .toList(),
                ),

                /// Optional Members
                if (optionalMembers.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text("Optional Members:",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  Wrap(
                    spacing: 8,
                    children: optionalMembers
                        .map(
                          (e) => Chip(
                        label: Text(e["name"]),
                        backgroundColor: Colors.orange.shade200,
                      ),
                    )
                        .toList(),
                  ),
                ],

                /// Teams (NEW)
                if (teams.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text("Teams:",
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, color: Colors.indigo)),
                  Wrap(
                    spacing: 8,
                    children: teams
                        .map(
                          (t) => Chip(
                        label: Text(t["name"]),
                        backgroundColor: Colors.green.shade200,
                      ),
                    )
                        .toList(),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
