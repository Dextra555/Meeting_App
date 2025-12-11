import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Provider/UserProvider.dart';

class MonthCalendarPage extends StatefulWidget {
  const MonthCalendarPage({super.key});

  @override
  State<MonthCalendarPage> createState() => _MonthCalendarPageState();
}

class _MonthCalendarPageState extends State<MonthCalendarPage> {
  DateTime selectedMonth = DateTime.now();
  List<dynamic> meetings = [];
  bool isLoading = false;
  int? selectedTeamId; // null = no filter
  List<Map<String, dynamic>> allTeams = [];


  final List<Color> colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.brown,
    Colors.pink,
    Colors.deepOrange,
    Colors.indigo
  ];
  final Map<int, Color> teamColorMap = {};

  Color getTeamColor(int teamId) {
    if (!teamColorMap.containsKey(teamId)) {
      teamColorMap[teamId] = colors[teamColorMap.length % colors.length];
    }
    return teamColorMap[teamId]!;
  }

  @override
  void initState() {
    super.initState();
    fetchMonthlyMeetings(selectedMonth);
  }

  Future<void> fetchMonthlyMeetings(DateTime month) async {
    setState(() => isLoading = true);

    String startDate = "01/${DateFormat("MM/yyyy").format(month)}";
    String endDate = DateFormat("dd/MM/yyyy")
        .format(DateTime(month.year, month.month + 1, 0));

    String url =
        "https://servernewapp.rentalsprime.in/api/meetings/summary?start_date=$startDate&end_date=$endDate&group_by=month";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          meetings = (data["grouped_meetings"] != null &&
              data["grouped_meetings"].isNotEmpty)
              ? data["grouped_meetings"][0]["meetings"] ?? []
              : [];
        });
        allTeams.clear();
        for (var m in meetings) {
          for (var team in (m["teams"] as List<dynamic>? ?? [])) {
            if (!allTeams.any((t) => t["id"] == team["id"])) {
              allTeams.add({"id": team["id"], "name": team["name"]});
            }
          }
        }

      }
    } catch (_) {}

    setState(() => isLoading = false);
  }

  void goToPreviousMonth() {
    setState(() =>
    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1, 1));
    fetchMonthlyMeetings(selectedMonth);
  }

  void goToNextMonth() {
    setState(() =>
    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 1));
    fetchMonthlyMeetings(selectedMonth);
  }

  Future<void> pickMonth() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => selectedMonth = picked);
      fetchMonthlyMeetings(selectedMonth);
    }
  }

  // 🔥 Shimmer Loader
  Widget shimmerLoader() {
    return ListView.builder(
      itemCount: 5,
      padding: const EdgeInsets.all(14),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 110,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ✅ Check if meeting is completed
  bool isCompleted(String date, String endTime) {
    try {
      DateTime meetingDate = DateFormat("dd/MM/yyyy").parse(date);
      List<String> parts = endTime.split(":");
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      DateTime meetingEnd = DateTime(
          meetingDate.year, meetingDate.month, meetingDate.day, hour, minute);

      return meetingEnd.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  Future<void> showEditMeetingPopup(Map<String, dynamic> meeting) async {
    DateTime selectedMeetingDate = DateTime.parse(
        "${meeting['date'].split('/')[2]}-${meeting['date'].split('/')[1]}-${meeting['date'].split('/')[0]}");
    TimeOfDay startTime = TimeOfDay(
        hour: int.parse(meeting['start_time'].split(':')[0]),
        minute: int.parse(meeting['start_time'].split(':')[1]));
    TimeOfDay endTime = TimeOfDay(
        hour: int.parse(meeting['end_time'].split(':')[0]),
        minute: int.parse(meeting['end_time'].split(':')[1]));

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 10,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gradient Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.blue, Colors.lightBlueAccent],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        "Edit Meeting",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Date Picker Card
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today, color: Colors.blue),
                      title: Text(
                          "Date: ${selectedMeetingDate.day}/${selectedMeetingDate.month}/${selectedMeetingDate.year}"),
                      trailing: const Icon(Icons.edit, color: Colors.blue),
                      onTap: () async {
                        final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedMeetingDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100));
                        if (picked != null) setState(() => selectedMeetingDate = picked);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Start Time Card
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.access_time, color: Colors.green),
                      title: Text("Start Time: ${startTime.format(context)}"),
                      trailing: const Icon(Icons.edit, color: Colors.green),
                      onTap: () async {
                        final picked = await showTimePicker(
                            context: context, initialTime: startTime);
                        if (picked != null) setState(() => startTime = picked);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),

                  // End Time Card
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.access_time, color: Colors.red),
                      title: Text("End Time: ${endTime.format(context)}"),
                      trailing: const Icon(Icons.edit, color: Colors.red),
                      onTap: () async {
                        final picked = await showTimePicker(
                            context: context, initialTime: endTime);
                        if (picked != null) setState(() => endTime = picked);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[800],
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          await updateMeeting(
                            meeting['id'],
                            meeting['title'],
                            meeting['purpose'],
                            selectedMeetingDate,
                            startTime,
                            endTime,
                            meeting['meeting_type'],
                          );
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Save",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Future<void> updateMeeting(int id, String title, String purpose,
      DateTime date, TimeOfDay start, TimeOfDay end, String meetingType) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final url =
        "https://servernewapp.rentalsprime.in/api/meetings/$id/reschedule";

    final body = {
      "title": title,
      "purpose": purpose,
      "date":
      "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}",
      "start_time":
      "${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}",
      "end_time":
      "${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}",
      "meeting_type": meetingType,
      "team_ids": [], // Add logic to select teams
      "team_member_ids": [],
      "optional_team_member_ids": [],
    };

    try {
      final res = await http.post(Uri.parse(url),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${userProvider.token}",
          },
          body: jsonEncode(body));

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Meeting updated successfully")));
        fetchMonthlyMeetings(selectedMonth);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: ${res.body}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }


  Future<void> showTeamFilterPopup() async {
    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "Filter by Team",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Team List
                Expanded(
                  child: Scrollbar(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: allTeams.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final team = allTeams[index];
                        return RadioListTile<int>(
                          title: Text(
                            team["name"],
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          value: int.parse(team["id"].toString()),
                          groupValue: selectedTeamId,
                          activeColor: Colors.blue, // single professional accent
                          onChanged: (value) {
                            setState(() => selectedTeamId = value);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ),

                const Divider(height: 1),

                // Clear Filter Button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TextButton(
                    onPressed: () {
                      setState(() => selectedTeamId = null);
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Clear Filter",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  Future<void> openLink(String url) async {
    Uri uri;

    if (url.contains("maps.google.com")) {
      // Force open in Maps app
      final query = Uri.encodeComponent(url.split('q=').last);
      uri = Uri.parse("geo:0,0?q=$query");
    } else if (url.contains("meet.google.com")) {
      // Try Meet app first
      uri = Uri.parse(url);
    } else {
      uri = Uri.parse(url);
    }

    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        // Fallback to browser if external app fails
        if (!await launchUrl(Uri.parse(url), mode: LaunchMode.inAppWebView)) {
          throw 'Could not launch $url';
        }
      }
    } catch (e) {
      debugPrint("Error launching URL: $e");
    }
  }

  Widget _detailRow(IconData icon, String label, String? value, {bool bold = false}) {
    if (value == null || value.toString().isEmpty) return SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "$label: $value",
              style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkButton(IconData icon, String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
                fontSize: 15,
                color: color,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // Apply team filter
    final filteredMeetings = selectedTeamId == null
        ? meetings
        : meetings.where((m) {
      final teams = (m["teams"] as List<dynamic>? ?? []);
      return teams.any((t) => t["id"] == selectedTeamId);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: isLoading
          ? shimmerLoader()
          : ListView(
        padding: const EdgeInsets.all(14),
        physics: const BouncingScrollPhysics(),
        children: [
          // Header
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white,
              boxShadow: const [
                BoxShadow(
                  blurRadius: 6,
                  spreadRadius: 1,
                  offset: Offset(0, 3),
                  color: Colors.black12,
                ),
              ],
            ),
            child: Column(
              children: [
                // Title & Month
                Column(
                  children: [
                    const Text(
                      "Monthly Meetings",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat("MMMM yyyy").format(selectedMonth),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Action buttons row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: goToPreviousMonth,
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: goToNextMonth,
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: pickMonth,
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_list, color: Colors.blue),
                      onPressed: showTeamFilterPopup,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Empty State
          if (filteredMeetings.isEmpty)
            Column(
              children: [
                const SizedBox(height: 60),
                Icon(Icons.event_busy_rounded,
                    color: Colors.grey.shade400, size: 70),
                const SizedBox(height: 12),
                Text(
                  "No meetings scheduled this month",
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600),
                ),
              ],
            )
          else
          // Meeting Cards
            ...filteredMeetings.map((m) {
              final teams = (m["teams"] as List<dynamic>?) ?? [];
              final optionalTeams =
                  (m["optional_team_members"] as List<dynamic>?) ?? [];
              final meetingMembers =
                  (m["team_members"] as List<dynamic>?) ?? [];

              bool isToday =
                  m["date"] == DateFormat("dd/MM/yyyy").format(DateTime.now());
              bool completed =
              isCompleted(m["date"] ?? "", m["end_time"] ?? "");

              // Card styling
              Color cardColor;
              TextStyle titleStyle;

              final startTime = DateFormat("HH:mm").parse(m["start_time"]);
              final endTime = DateFormat("HH:mm").parse(m["end_time"]);

              if (isToday) {
                cardColor = Colors.green.shade50;
                titleStyle = const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700);
              } else if (completed) {
                cardColor = Colors.grey.shade200;
                titleStyle = const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey);
              } else {
                cardColor = Colors.white;
                titleStyle = const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700);
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                      color: Colors.black12,
                    ),
                  ],
                  border: isToday
                      ? Border.all(color: Colors.green, width: 2)
                      : completed
                      ? Border.all(color: Colors.grey.shade400, width: 1)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + Edit button
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: isToday
                              ? [Colors.green.shade300, Colors.green.shade600]
                              : completed
                              ? [Colors.grey.shade400, Colors.grey.shade600]
                              : [Colors.blue.shade300, Colors.blue.shade600],
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              m["title"],
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            onPressed: () => showEditMeetingPopup(m),
                          ),
                        ],
                      ),
                    ),

                    if (isToday)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text("🔥 Today", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ),
                    if (completed && !isToday)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text("✔ Completed", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ),

                    const SizedBox(height: 14),
                    Divider(thickness: 1.2),

                    // Timing
                    Row(
                      children: [
                        Icon(Icons.access_time_filled_rounded, size: 20, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          "${m["date"]} • ${DateFormat.jm().format(startTime)} → ${DateFormat.jm().format(endTime)}",
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue.shade800),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Details with icons
                    _detailRow(Icons.category_rounded, "Type", m["meeting_type"]),
                    _detailRow(Icons.info_rounded, "Purpose", m["purpose"]),
                    _detailRow(Icons.business_rounded, "Company", m["company_name"], bold: true),
                    _detailRow(Icons.person_rounded, "Contact", m["contact_person"]),
                    _detailRow(Icons.phone_rounded, "Phone", m["phone"]),
                    _detailRow(Icons.email_rounded, "Email", m["email"]),

                    const SizedBox(height: 14),

                    // Links
                    if (m["meeting_link"] != null)
                      GestureDetector(
                        onTap: () => openLink(m["meeting_link"]),
                        child: _linkButton(Icons.video_call_rounded, "Join Meeting", Colors.blue.shade700),
                      ),

                    if (m["location_map"] != null)
                      GestureDetector(
                        onTap: () => openLink(m["location_map"]),
                        child: _linkButton(Icons.location_on_rounded, "View Location", Colors.red.shade700),
                      ),

                    const SizedBox(height: 16),
                    Divider(thickness: 1.2),

                    // Team Chips
                    if (teams.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: teams.map((t) {
                            final color = getTeamColor(t["id"]);
                            return Chip(
                              elevation: 2,
                              backgroundColor: color.withOpacity(0.18),
                              label: Text(
                                t["name"],
                                style: TextStyle(color: color, fontWeight: FontWeight.w600),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                    if (meetingMembers.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          "👥 Members: ${meetingMembers.map((e) => e["name"]).join(', ')}",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),

                    if (optionalTeams.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          "⭐ Optional: ${optionalTeams.map((e) => e["name"]).join(', ')}",
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}
