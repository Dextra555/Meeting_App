import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../Models/Model.dart';
import '../Provider/UserProvider.dart';
import 'UpcomingMeetingsPage.dart';
import 'admin_page.dart';
import 'package:provider/provider.dart';

class MeetingsPage extends StatefulWidget {
  const MeetingsPage({super.key});

  @override
  State<MeetingsPage> createState() => _MeetingsPageState();
}

class _MeetingsPageState extends State<MeetingsPage> {
  late String currentUserId;
  int _nextMeetingId = 1;

  List<Employee> employees = [];

  List<Employee> optionalEmployees() {
    return employees
        .where((e) =>
    !selectedTeamIds.contains(e.teamId) &&
        !employeesForTeams(selectedTeamIds.toList()).contains(e))
        .toList();
  }


  List<Team> teams = [];
  final List<Meeting> meetings = [];

  final TextEditingController titleCtrl = TextEditingController();
  final FocusNode titleFocus = FocusNode();
  final Set<String> selectedTeamIds = {};
  final Set<String> selectedMemberIds = {};
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  TimeOfDay? selectedEndTime;
  bool isOnline = true;

  final TextEditingController companyCtrl = TextEditingController();
  final TextEditingController PurposeCtrl = TextEditingController();
  final TextEditingController contactPersonCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController meetLinkCtrl = TextEditingController();
  String? selectedOnlineRoom;


  bool get isSuperAdmin =>
      Provider.of<UserProvider>(context, listen: false).isAdmin;

  Employee? get currentUser {
    try {
      return employees.firstWhere((e) => e.id == currentUserId);
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userData = userProvider.userData;

      if (userData != null) {
        setState(() {
          currentUserId = userData['id'].toString();

          employees.add(
            Employee(
              id: userData['id'].toString(),
              name: userData['name'].toString(),
              category: userData['role'] ?? '',
              teamId: userData['team_id'].toString(),
            ),
          );
        });
      }

      _fetchTeams();
    });
  }

  Future<void> _fetchTeams() async {
    final url = Uri.parse('https://servernewapp.rentalsprime.in/api/teams');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<Team> fetchedTeams = [];
          final List<Employee> fetchedEmployees = [];
          for (var t in data['teams']) {
            final team = Team(
              id: t['id'].toString(),
              name: t['name'],
              description: t['description'] ?? '',
            );
            fetchedTeams.add(team);

            if (t['members'] != null) {
              for (var m in t['members']) {
                fetchedEmployees.add(Employee(
                  id: m['id'].toString(),
                  name: m['name'],
                  category: m['role'] ?? '',
                  teamId: team.id,
                ));
              }
            }
          }

          setState(() {
            teams = fetchedTeams;
            for (var emp in fetchedEmployees) {
              if (!employees.any((e) => e.id == emp.id)) {
                employees.add(emp);
              }
            }
          });

        }
      } else {
        _showSnack('Failed to fetch teams');
      }
    } catch (e) {
      _showSnack('Error fetching teams');
    }
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  List<Employee> employeesForTeams(List<String> teamIds) {
    return employees.where((e) => teamIds.contains(e.teamId)).toList();
  }

  Employee? empById(String id) {
    try {
      return employees.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }




  Future<void> _scheduleMeeting() async {
    final title = titleCtrl.text.trim();
    if (title.isEmpty) return _showSnack('Enter title');

    if (selectedTeamIds.isEmpty) return _showSnack('Select team(s)');
    if (selectedMemberIds.isEmpty) return _showSnack('Select attendees');
    if (selectedDate == null || selectedTime == null || selectedEndTime == null) {
      return _showSnack('Pick date, start time & end time');
    }

    final dateFormatted = DateFormat('dd/MM/yyyy').format(selectedDate!);

    final startTime =
        "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}";

    final endTime =
        "${selectedEndTime!.hour.toString().padLeft(2, '0')}:${selectedEndTime!.minute.toString().padLeft(2, '0')}";

    final apiUrl = Uri.parse("https://servernewapp.rentalsprime.in/api/meetings");

    final body = {
      "title": title,
      "company_name": companyCtrl.text.trim(),
      "purpose": PurposeCtrl.text.trim(),
      "contact_person": contactPersonCtrl.text.trim(),
      "phone": phoneCtrl.text.trim(),
      "email": emailCtrl.text.trim(),
      "date": dateFormatted,
      "start_time": startTime,
      "end_time": endTime,
      "team_ids": selectedTeamIds.toList(),
      "team_member_ids": selectedMemberIds.toList(),
      "optional_team_member_ids": optionalEmployees()
          .where((e) => selectedMemberIds.contains(e.id))
          .map((e) => e.id)
          .toList(),
      "meeting_type": isOnline ? "online" : "offline",
      "room": isOnline ? selectedOnlineRoom : null,
      "meeting_link": isOnline ? meetLinkCtrl.text.trim() : null,
      "location_map": isOnline ? null : meetLinkCtrl.text.trim(),
      "created_by": Provider.of<UserProvider>(context, listen: false).userData!['name'],
    };

    print("Sending request: ${jsonEncode(body)}");

    try {
      final response = await http.post(
        apiUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      print("API Response: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || data["status"] == "success") {
        _showSnack("Meeting created successfully");

        setState(() {
          titleCtrl.clear();
          selectedTeamIds.clear();
          selectedMemberIds.clear();
          selectedDate = null;
          selectedTime = null;
          selectedEndTime = null;
          isOnline = true;
          companyCtrl.clear();
          PurposeCtrl.clear();
          contactPersonCtrl.clear();
          phoneCtrl.clear();
          emailCtrl.clear();
          meetLinkCtrl.clear();
          selectedOnlineRoom = null;

          FocusScope.of(context).unfocus();
        });
      } else {
        _showSnack("Failed: ${response.body}");
      }
    } catch (e) {
      _showSnack("Error: $e");
    }
  }

  Widget _buildDateButton() => ElevatedButton(
    onPressed: () async {
      final d = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2050));
      if (d != null) setState(() => selectedDate = d);
    },
    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
    child: Text(
        selectedDate == null
            ? 'Pick Date'
            : DateFormat('dd-MM-yyyy').format(selectedDate!),
        style: const TextStyle(color: Colors.white)),
  );

  Widget _buildTimeButton() => ElevatedButton(
    onPressed: () async {
      final t = await showTimePicker(
          context: context, initialTime: TimeOfDay.now());
      if (t != null) setState(() => selectedTime = t);
    },
    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
    child: Text(
        selectedTime == null ? 'Pick Start Time' : selectedTime!.format(context),
        style: const TextStyle(color: Colors.white)),
  );

  Widget _buildEndTimeButton() => ElevatedButton(
    onPressed: () async {
      final t = await showTimePicker(
          context: context,
          initialTime: selectedTime ?? TimeOfDay.now());
      if (t != null) setState(() => selectedEndTime = t);
    },
    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
    child: Text(
        selectedEndTime == null
            ? 'Pick End Time'
            : selectedEndTime!.format(context),
        style: const TextStyle(color: Colors.white)),
  );

  @override
  void dispose() {
    titleCtrl.dispose();
    titleFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        Text('Meetings', style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.indigo,
        actions: [
          if (Provider.of<UserProvider>(context).isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminPage(
                      employees: employees,
                      teams: teams,
                      currentUserId: currentUserId,
                      currentUserName: empById(currentUserId)?.name ?? "",
                      onAddEmployee: (emp) =>
                          setState(() => employees.add(emp)),
                      onAddTeam: (team) => setState(() => teams.add(team)),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 8,
              shadowColor: Colors.indigo.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade500, Colors.indigo.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("📅 Schedule a Meeting",
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    const SizedBox(height: 14),
                    TextField(
                      controller: titleCtrl,
                      focusNode: titleFocus,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Meeting Title",
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: companyCtrl,
                      style: TextStyle(color: Colors.white),
                      decoration: _inputDecoration("Company Name"),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: contactPersonCtrl,
                      style: TextStyle(color: Colors.white),
                      decoration: _inputDecoration("Contact Person"),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: Colors.white),
                      decoration: _inputDecoration("Phone Number"),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: Colors.white),
                      decoration: _inputDecoration("Email ID"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: PurposeCtrl,
                      style: TextStyle(color: Colors.white),
                      decoration: _inputDecoration("Purpose"),
                    ),
                    const SizedBox(height: 6),
                    Text("Select Teams",
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: teams.map((t) {
                        final isSelected = selectedTeamIds.contains(t.id);
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          child: FilterChip(
                            label: Text(t.name,
                                style: GoogleFonts.poppins(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.indigo)),
                            selected: isSelected,
                            backgroundColor: Colors.white,
                            selectedColor: Colors.indigo.shade400,
                            onSelected: (v) {
                              setState(() {
                                if (v)
                                  selectedTeamIds.add(t.id);
                                else {
                                  selectedTeamIds.remove(t.id);
                                  selectedMemberIds.removeWhere((id) {
                                    final e = empById(id);
                                    return e == null ||
                                        !selectedTeamIds.contains(e.teamId);
                                  });
                                }
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    Text("Select Attendees",
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    if (selectedTeamIds.isEmpty)
                      Text("Select a team first",
                          style: GoogleFonts.poppins(color: Colors.white70))
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: employeesForTeams(selectedTeamIds.toList())
                                  .map((e) => CheckboxListTile(
                                value: selectedMemberIds.contains(e.id),
                                activeColor: Colors.amber,
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true)
                                      selectedMemberIds.add(e.id);
                                    else
                                      selectedMemberIds.remove(e.id);
                                  });
                                },
                                title: Text(e.name,
                                    style: const TextStyle(
                                        color: Colors.white)),
                                subtitle: Text(e.category,
                                    style: const TextStyle(
                                        color: Colors.white70)),
                              ))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text("Optional Attendees (other teams)",
                              style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.amber)),
                          const SizedBox(height: 4),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: optionalEmployees().map((e) {
                                final teamName = teams.firstWhere(
                                      (t) => t.id == e.teamId,
                                  orElse: () => Team(
                                      id: '-', name: 'Unknown Team', description: ''),
                                ).name;
                                return CheckboxListTile(
                                  value: selectedMemberIds.contains(e.id),
                                  activeColor: Colors.amber,
                                  onChanged: (v) {
                                    setState(() {
                                      if (v == true)
                                        selectedMemberIds.add(e.id);
                                      else
                                        selectedMemberIds.remove(e.id);
                                    });
                                  },
                                  title: Text(e.name,
                                      style: const TextStyle(color: Colors.white)),
                                  subtitle: Text("${e.category} • $teamName",
                                      style: const TextStyle(color: Colors.white70)),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 14),
                    StatefulBuilder(
                      builder: (context, updateTimeState) => Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2050),
                              );
                              if (d != null) updateTimeState(() => selectedDate = d);
                            },
                            child: Text(
                              selectedDate == null
                                  ? 'Pick Date'
                                  : DateFormat('dd-MM-yyyy').format(selectedDate!),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: selectedTime ?? TimeOfDay.now(),
                              );
                              if (t != null) updateTimeState(() => selectedTime = t);
                            },
                            child: Text(
                              selectedTime == null
                                  ? 'Pick Start Time'
                                  : selectedTime!.format(context),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: selectedEndTime ?? selectedTime ?? TimeOfDay.now(),
                              );
                              if (t != null) updateTimeState(() => selectedEndTime = t);
                            },
                            child: Text(
                              selectedEndTime == null
                                  ? 'Pick End Time'
                                  : selectedEndTime!.format(context),
                            ),
                          ),

                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Meeting Type",
                                  style: GoogleFonts.poppins(
                                      fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                              Row(
                                children: [
                                  Text(isOnline ? "Online" : "Offline",
                                      style: const TextStyle(color: Colors.white)),
                                  const SizedBox(width: 8),
                                  Switch(
                                    activeColor: Colors.amber,
                                    value: isOnline,
                                    onChanged: (v) {
                                      setState(() {
                                        isOnline = v;
                                        meetLinkCtrl.clear();
                                        selectedOnlineRoom = null;
                                      });
                                    },
                                  ),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 8),

                          if (isOnline) ...[
                            DropdownButtonFormField<String>(
                              value: selectedOnlineRoom,
                              dropdownColor: Colors.indigo,
                              decoration: _inputDecoration("Select Room"),
                              items: ["Conference", "Pooja Room"]
                                  .map((room) => DropdownMenuItem(
                                value: room,
                                child: Text(room, style: TextStyle(color: Colors.white)),
                              ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() => selectedOnlineRoom = value);
                              },
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: meetLinkCtrl,
                              style: TextStyle(color: Colors.white),
                              decoration: _inputDecoration("Google Meet Link"),
                            ),
                          ] else ...[
                            TextField(
                              controller: meetLinkCtrl,
                              style: TextStyle(color: Colors.white),
                              decoration: _inputDecoration("Google Map Link"),
                            ),
                          ],
                          const SizedBox(height: 12),


                        ],
                      ),
                    ),

                    const SizedBox(height: 14),
                    Center(
                      child: ElevatedButton(
                        onPressed: _scheduleMeeting,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          backgroundColor: Colors.amber,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                          elevation: 6,
                        ),
                        child: Text("🚀 Schedule",
                            style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white24,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
    );
  }
}
