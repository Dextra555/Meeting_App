import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Provider/UserProvider.dart';
import 'MonthCalendarPage.dart';
import 'WeekCalendarPage.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int _selectedIndex = 0;
  DateTime _selectedDate = DateTime.now();
  bool isLoading = false;
  Map<String, dynamic>? apiData;
  int? selectedTeamId;
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

  Color getTeamColor(int teamId, {String? teamName}) {
    if (teamName != null && teamName.toLowerCase() == "wordpress app team") {
      return Colors.purple;
    }

    if (!teamColorMap.containsKey(teamId)) {
      final color = colors[teamColorMap.length % colors.length];
      teamColorMap[teamId] = color;
    }
    return teamColorMap[teamId]!;
  }

  @override
  void initState() {
    super.initState();
    fetchMeetings(_selectedDate);
  }

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  Future<void> fetchMeetings(DateTime date) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    String teamId = userProvider.teamId ?? "1";

    setState(() => isLoading = true);

    String url =
        "https://servernewapp.rentalsprime.in/api/meetings?date=${formatDate(date)}";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          apiData = data;
          isLoading = false;

          // Collect unique teams
          allTeams.clear();
          teamColorMap.clear();
          final meetings = data["meetings"] as List<dynamic>? ?? [];
          for (var m in meetings) {
            final teams = m["teams"] as List<dynamic>? ?? [];
            for (var team in teams) {
              final id = team["id"];
              if (!allTeams.any((t) => t["id"] == id)) {
                allTeams.add({"id": id, "name": team["name"]});
              }
            }
          }
        });
      } else {
        setState(() {
          apiData = null;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        apiData = null;
        isLoading = false;
      });
    }
  }

  Widget buildDayTab() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: const Color(0xFF4C7EE9),
              child: TableCalendar(
                firstDay: DateTime(2020),
                lastDay: DateTime(2030),
                focusedDay: _selectedDate,
                selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
                calendarFormat: CalendarFormat.week,
                availableCalendarFormats: const {CalendarFormat.week: ''},
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                  leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white, size: 22),
                  rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white, size: 22),
                ),
                calendarStyle: const CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: TextStyle(
                    color: Color(0xFF4C7EE9),
                    fontWeight: FontWeight.bold,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(
                    color: Color(0xFF4C7EE9),
                    fontWeight: FontWeight.bold,
                  ),
                  defaultTextStyle: TextStyle(color: Colors.white),
                  weekendTextStyle: TextStyle(color: Colors.white70),
                  outsideDaysVisible: false,
                  cellMargin: EdgeInsets.all(4),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(color: Colors.white70),
                  weekendStyle: TextStyle(color: Colors.white60),
                ),
                rowHeight: 52,
                daysOfWeekHeight: 36,
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDate = selectedDay;
                  });
                  fetchMeetings(selectedDay);
                },
              ),
            ),
          ),
        ),

        // Selected Date Display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: Colors.white,
          child: Row(
            children: [
              const Icon(Icons.today, color: Color(0xFF4C7EE9), size: 22),
              const SizedBox(width: 12),
              Text(
                DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),

        // Team Filter Row
        if (allTeams.isNotEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            color: Colors.white,
            child: Row(
              children: [
                const Text("Filter by Team:", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: Text(
                            selectedTeamId == null
                                ? "All Teams"
                                : allTeams.firstWhere(
                                  (t) => t["id"] == selectedTeamId,
                              orElse: () => {"name": "Unknown"},
                            )["name"],
                          ),
                          selected: selectedTeamId != null,
                          avatar: const Icon(Icons.filter_list, size: 18),
                          onSelected: (_) => showTeamFilterPopup(),
                        ),
                        const SizedBox(width: 8),
                        if (selectedTeamId != null)
                          ActionChip(
                            label: const Text("Clear"),
                            onPressed: () => setState(() => selectedTeamId = null),
                          ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: showTeamFilterPopup,
                ),
              ],
            ),
          ),

        // Meetings List (takes maximum space)
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF7F9FC),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: isLoading
                ? shimmerUI()
                : apiData == null || (apiData!["meetings"] as List).isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No Meetings Today",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
                : Builder(
              builder: (context) {
                var meetings = List.from(apiData!["meetings"]);

                // Apply team filter
                if (selectedTeamId != null) {
                  meetings = meetings.where((m) {
                    final teams = m["teams"] as List? ?? [];
                    return teams.any((t) => t["id"] == selectedTeamId);
                  }).toList();
                }

                if (meetings.isEmpty) {
                  return const Center(
                    child: Text("No meetings for selected team"),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80),
                  itemCount: meetings.length,
                  itemBuilder: (context, index) {
                    final meeting = meetings[index];
                    final color = getTeamColor(
                      meeting["teams"].isEmpty ? 0 : meeting["teams"][0]["id"],
                      teamName: meeting["teams"].isEmpty ? null : meeting["teams"][0]["name"],
                    );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ExpansionTile(
                        leading: Container(
                          width: 6,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                        iconColor: Colors.black87,
                        collapsedIconColor: Colors.black54,
                        tilePadding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    meeting["title"] ?? "No Title",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  onPressed: () => showEditMeetingPopup(meeting),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 18, color: color),
                                const SizedBox(width: 8),
                                Text(
                                  "${to12Hour(meeting["start_time"] ?? "")} – ${to12Hour(meeting["end_time"] ?? "")}",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            meeting["purpose"] ?? "No purpose specified",
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ),
                        children: [
                          _detailRow(Icons.category_rounded, "Type",
                              meeting["meeting_type"]),
                          _detailRow(Icons.business_rounded, "Company",
                              meeting["company_name"]),
                          _detailRow(Icons.person_rounded, "Contact",
                              meeting["contact_person"]),
                          _detailRow(
                              Icons.phone_rounded, "Phone", meeting["phone"]),
                          _detailRow(
                              Icons.email_rounded, "Email", meeting["email"]),

                          const SizedBox(height: 16),

                          // 🔗 Links
                          if (meeting["meeting_link"] != null &&
                              meeting["meeting_link"] != "")
                            GestureDetector(
                              onTap: () => openLink(meeting["meeting_link"]),
                              child: _linkButton(Icons.video_call_rounded,
                                  "Join Meeting", Colors.blue.shade700),
                            ),

                          if (meeting["location_map"] != null &&
                              meeting["location_map"] != "")
                            GestureDetector(
                              onTap: () => openLink(meeting["location_map"]),
                              child: _linkButton(
                                  Icons.location_on_rounded,
                                  "View Location",
                                  Colors.red.shade700),
                            ),
                          const SizedBox(height: 10),

                          const SizedBox(height: 10),
                          infoBlock(Icons.groups, "Teams", meeting["teams"], "name"),
                          const SizedBox(height: 12),
                          infoBlock(Icons.person, "Members", meeting["team_members"], "name"),
                          const SizedBox(height: 12),
                          infoBlock(Icons.person_outline, "Optional", meeting["optional_team_members"], "name"),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget infoBlock(IconData icon, String title, List list, String key) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 6),
          Text(title,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 4),
        ...list.map((e) => Padding(
          padding: const EdgeInsets.only(left: 28, top: 2),
          child: Text("• ${e[key]}", style: const TextStyle(fontSize: 15)),
        )),
      ],
    );
  }

  Widget buildWeekTab() {
    return WeekCalendarPage();
  }
  Widget buildMonthTab() {
    return MonthCalendarPage();
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
                  child: allTeams.isEmpty
                      ? const Center(child: Text("No teams available"))
                      : Scrollbar(
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
                          activeColor: Colors.blue,
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

                // Clear Filter
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TextButton(
                    onPressed: () {
                      setState(() => selectedTeamId = null);
                      Navigator.pop(context);
                    },
                    child: const Text("Clear Filter", style: TextStyle(color: Colors.grey)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  String to12Hour(String time) {
    try {
      final parsed = DateFormat("HH:mm").parse(time);
      return DateFormat("hh:mm a").format(parsed); // 12-hour format with AM/PM
    } catch (e) {
      return time;
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
        fetchMeetings(_selectedDate);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: ${res.body}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
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

  Widget _detailRow(IconData icon, String title, String? value,
      {bool bold = false}) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "$title: $value",
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.w500),
            ),
          )
        ],
      ),
    );
  }

  Widget _linkButton(IconData icon, String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withOpacity(0.12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }



  Widget shimmerUI() => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: 6,
    itemBuilder: (_, __) => Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade200,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final screens = [buildDayTab(), buildWeekTab(), buildMonthTab()];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendar"),
        backgroundColor: const Color(0xFF4C7EE9),
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: const Color(0xFF4C7EE9),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: "Days"),
          BottomNavigationBarItem(
              icon: Icon(Icons.view_week), label: "Week"),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: "Month"),
        ],
      ),
    );
  }
}
