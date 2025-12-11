import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:server_maintance/view/profilescreen.dart';
import 'package:server_maintance/view/weeklyhostingpage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:server_maintance/view/Hostingpage.dart';
import 'package:server_maintance/view/cilentformsubmission.dart';
import 'package:server_maintance/view/Meetings.dart';
import 'package:table_calendar/table_calendar.dart';

import '../Provider/UserProvider.dart';
import 'CalendarScreen.dart';
import 'Domainpage.dart';
import 'followupspage.dart';
import 'loginview.dart';
import 'notificationpage.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  List<dynamic> todayFollowUps = [];
  int thisWeekFollowUpCount = 0;
  bool _showAllActivities = false;
  int _hostingCount = 0;
  List<dynamic> _domainRenewals = [];
  int dextraCount = 0;
  int clientCount = 0;
  int thisWeekHostingCount = 0;
  String thisWeekHostingAmount = "0.00";

  Timer? _countdownTimer;
  List<Duration> _countdowns = [];

  Timer? _refreshTimer;
  final Map<DateTime, List<String>> _events = {
    DateTime.utc(2025, 7, 10): [
      'Follow-up: Client X',
      'Domain Renewal: ABC.com'
    ],
    DateTime.utc(2025, 7, 11): ['Domain Renewal: XYZ.com'],
  };

  String _monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month];
  }

  Future<void> _fetchDomainRenewals() async {
    final url = Uri.parse(
        "https://servernewapp.rentalsprime.in/api/hostings-this-week");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _hostingCount = data['count'] ?? 0;
          _domainRenewals = data['data'];
        });
      }
    } catch (e) {
      print("❌ Error fetching domain renewals: $e");
    }
  }

  void fetchWeeklyHostingSummary() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://servernewapp.rentalsprime.in/api/hosting/weekly-summary'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == true && jsonData['data'] != null) {
          setState(() {
            thisWeekHostingCount = jsonData['count'] ?? 0;
            thisWeekHostingAmount = jsonData['total_amount'] ?? "0.00";
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


  final Set<DateTime> followUpDates = {
    DateTime.utc(2025, 7, 12),
    DateTime.utc(2025, 7, 15),
  };

  final Set<DateTime> renewalDates = {
    DateTime.utc(2025, 7, 14),
    DateTime.utc(2025, 7, 17),
  };

  Future<void> _fetchThisWeekFollowUpCount() async {
    final url = Uri.parse(
        "https://servernewapp.rentalsprime.in/api/enquiries-this-week");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final count = responseData['count'] ?? 0;
        print("🔁 Updating count state to: $count");

        setState(() {
          thisWeekFollowUpCount = count;
        });
      } else {
        print("❌ Failed to load count: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching count: $e");
    }
  }

  Widget _getSelectedPage() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return const ClientFormScreen();
      case 2:
        return LeadsScreen();
      case 3:
        return MeetingsPage();
      default:
        return _buildDashboardContent();
    }
  }

  Future<void> _loadFollowUpDatesFromApi() async {
    try {
      final response = await http.get(
          Uri.parse("https://servernewapp.rentalsprime.in/api/enquiries"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> all = data['data'];

        final dates = all
            .map((entry) {
              final rawDate = entry['follow_up'];
              if (rawDate == null) return null;

              final parsed = DateTime.tryParse(rawDate)?.toLocal();
              if (parsed == null) return null;

              return DateTime(parsed.year, parsed.month, parsed.day);
            })
            .whereType<DateTime>()
            .toSet();

        setState(() {
          followUpDates.clear();
          followUpDates.addAll(dates);
        });
      }
    } catch (e) {
      print("❌ Error loading follow-up dates: $e");
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRenewalsForDate(
      DateTime date) async {
    try {
      final response = await http.get(
        Uri.parse('https://servernewapp.rentalsprime.in/api/hosting'),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<dynamic> allItems = jsonData['data'];

        final selectedDate =
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

        final filteredRenewals = allItems.where((item) {
          final expiry = item['expiring_date'];
          return expiry == selectedDate;
        }).toList();

        return filteredRenewals.cast<Map<String, dynamic>>();
      } else {
        print("❌ Failed to fetch renewals: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("❌ Error fetching renewals: $e");
      return [];
    }
  }

  Future<List<dynamic>> _fetchFollowUpsForDate(DateTime date) async {
    try {
      final response = await http.get(
          Uri.parse("https://servernewapp.rentalsprime.in/api/enquiries"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> all = data['data'];

        final selectedOnly = DateTime(date.year, date.month, date.day);
        print("🔎 Selected Date: $selectedOnly");

        final filtered = all.where((entry) {
          final rawDate = entry['follow_up'];
          print("📅 Raw follow_up from API: $rawDate");

          if (rawDate == null) return false;

          final parsed = DateTime.tryParse(rawDate)?.toLocal();
          if (parsed == null) {
            print("❌ Failed to parse: $rawDate");
            return false;
          }

          final parsedOnly = DateTime(parsed.year, parsed.month, parsed.day);
          final matches = parsedOnly == selectedOnly;
          print("👉 Comparing: $parsedOnly == $selectedOnly => $matches");

          return matches;
        }).toList();

        print("✅ Filtered clients count: ${filtered.length}");
        return filtered;
      } else {
        print("❌ API status code: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Exception: $e");
    }

    return [];
  }

  @override
  void initState() {
    super.initState();

    _loadFollowUpDatesFromApi();
    _fetchThisWeekFollowUpCount();
    _fetchThisWeekHostings();
    _fetchHostingCountOnly();
    _fetchTodayFollowUps();
    fetchHostingCounts();
    fetchWeeklyHostingSummary();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTodayFollowUps() async {
    final today = DateTime.now();
    final todayStr =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    try {
      final response = await http.get(
          Uri.parse("https://servernewapp.rentalsprime.in/api/enquiries"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> all = data['data'];

        final filtered = all.where((entry) {
          final rawDate = entry['follow_up'];
          if (rawDate == null) return false;

          final parsed = DateTime.tryParse(rawDate);
          if (parsed == null) return false;

          return parsed.year == today.year &&
              parsed.month == today.month &&
              parsed.day == today.day;
        }).toList();

        print("🔍 Today: $todayStr");
        for (var entry in all) {
          print("👉 ${entry['name']} follow_up: ${entry['follow_up']}");
        }

        setState(() {
          todayFollowUps = filtered;
        });
      }
    } catch (e) {
      debugPrint("❌ Error fetching followups: $e");
    }
  }

  void fetchHostingCounts() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://servernewapp.rentalsprime.in/api/hosting/hosted-by-count'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == true && jsonData['data'] != null) {
          setState(() {
            dextraCount = jsonData['data']['dextra_count'] ?? 0;
            clientCount = jsonData['data']['client_count'] ?? 0;
          });
        } else {
          print("API success=false or data null");
        }
      } else {
        print("Failed to fetch counts. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching hosting counts: $e");
    }
  }

  void _showClientActionDialog(
    BuildContext context,
    String clientName,
    int clientId,
    VoidCallback onStatusCompleted,
  ) {
    String selectedOption = 'converted';
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Client Update',
                    style: GoogleFonts.notoSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RadioListTile<String>(
                    title: Text('Yes, I spoke and converted to client',
                        style: GoogleFonts.notoSans(fontSize: 14)),
                    value: 'converted',
                    groupValue: selectedOption,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) =>
                        setState(() => selectedOption = value!),
                  ),
                  RadioListTile<String>(
                    title: Text('Need follow-up again',
                        style: GoogleFonts.notoSans(fontSize: 14)),
                    value: 'followup',
                    groupValue: selectedOption,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) =>
                        setState(() => selectedOption = value!),
                  ),
                  if (selectedOption == 'followup') ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(52100),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          selectedDate != null
                              ? 'Date: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                              : 'Select Follow-up Date',
                          style: GoogleFonts.notoSans(
                              fontSize: 14, color: Colors.black87),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setState(() => selectedTime = picked);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          selectedTime != null
                              ? 'Time: ${selectedTime!.format(context)}'
                              : 'Select Follow-up Time',
                          style: GoogleFonts.notoSans(
                              fontSize: 14, color: Colors.black87),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        child: Text("Cancel",
                            style: GoogleFonts.notoSans(fontSize: 14)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        onPressed: () async {
                          if (selectedOption == 'converted') {
                            final response = await http.post(
                              Uri.parse(
                                  "https://servernewapp.rentalsprime.in/api/enquiries/update-status"),
                              headers: {'Content-Type': 'application/json'},
                              body: jsonEncode(
                                  {"id": clientId, "status": "Completed"}),
                            );

                            print("📥 Status API Response: ${response.body}");

                            if (response.statusCode == 200) {
                              onStatusCompleted();
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text("✅ Status updated to Completed")),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("❌ Failed to update status")),
                              );
                            }
                          } else if (selectedOption == 'followup' &&
                              selectedDate != null) {
                            final formattedDate =
                                "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";

                            final response = await http.post(
                              Uri.parse(
                                  "https://servernewapp.rentalsprime.in/api/enquiries/update-followup-created"),
                              headers: {'Content-Type': 'application/json'},
                              body: jsonEncode({
                                "id": clientId,
                                "follow_up": formattedDate,
                              }),
                            );

                            print(
                                "📥 Follow-up API Response: ${response.body}");

                            if (response.statusCode == 200) {
                              onStatusCompleted();
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("📅 Follow-up scheduled")),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text("❌ Failed to schedule follow-up")),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("⚠️ Please select a date")),
                            );
                          }
                        },
                        child: Text("Submit",
                            style: GoogleFonts.notoSans(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  List<dynamic> _thisWeekHostings = [];

  Future<void> _fetchThisWeekHostings() async {
    final url = Uri.parse(
        "https://servernewapp.rentalsprime.in/api/hostings-this-week");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> list = data['data'];

        setState(() {
          _thisWeekHostings = list;
          _countdowns = list.map((item) {
            final expDate = DateTime.tryParse(item['expiring_date'] ?? '');
            return expDate != null
                ? expDate.difference(DateTime.now())
                : Duration.zero;
          }).toList();
        });

        _startCountdownTimer();
      }
    } catch (e) {
      //print("❌ Error: $e");
    }
  }

  Future<void> _fetchHostingCountOnly() async {
    final url = Uri.parse(
        "https://servernewapp.rentalsprime.in/api/hostings-this-week");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        print("✅ Hosting count from server: $_hostingCount");
        final data = json.decode(response.body);
        setState(() {
          _hostingCount = data['count'] ?? 0;
        });
      } else {
        print("❌ Failed to fetch count. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching hosting count: $e");
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _countdowns = _countdowns.map((d) {
          final updated = d - Duration(seconds: 1);
          return updated.isNegative ? Duration.zero : updated;
        }).toList();
      });
    });
  }

  void _showDayFollowUps(BuildContext context, DateTime selectedDay) async {
    final clients = await _fetchFollowUpsForDate(selectedDay);
    final renewals = await _fetchRenewalsForDate(selectedDay);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          minChildSize: 0.3,
          initialChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: (clients.isEmpty && renewals.isEmpty)
                  ? Center(
                      child: Text("No follow-ups or renewals",
                          style: GoogleFonts.notoSans()))
                  : SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Activities on ${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}",
                            style: GoogleFonts.notoSans(
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          if (clients.isNotEmpty)
                            ...clients.map((item) => _buildClientMessage(
                                  id: item['id'],
                                  title: item['name'],
                                  content: item['company_name'],
                                  time: "Follow-up",
                                  enquiry: item['enquiry'],
                                  phone: item['phone'],
                                  onStatusCompleted: () {
                                    setState(() {
                                      clients.removeWhere((element) =>
                                          element['id'] == item['id']);
                                    });
                                  },
                                )),
                          if (renewals.isNotEmpty)
                            ...renewals.map((item) {
                              final expDate =
                                  DateTime.parse(item['expiring_date']);
                              final date =
                                  expDate.day.toString().padLeft(2, '0');
                              final month = _monthName(expDate.month);

                              return _buildActivityItem(
                                date: date,
                                month: month,
                                title: item['company_name'] ?? '',
                                subtitle: item['hosting_name'] ?? '',
                                time: 'Renewal Due',
                                duration: "00 : 00 : 00",
                              );
                            }),
                        ],
                      ),
                    ),
            );
          },
        );
      },
    );
  }

  void _showCalendarDialog(BuildContext rootContext) {
    DateTime focusedDay = DateTime.now();

    showModalBottomSheet(
      context: rootContext,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Select Date',
                    style: GoogleFonts.notoSans(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: focusedDay,
                    calendarStyle: CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        color: Colors.indigo,
                        shape: BoxShape.circle,
                      ),
                      defaultTextStyle: GoogleFonts.notoSans(fontSize: 13),
                      weekendTextStyle: GoogleFonts.notoSans(
                          fontSize: 13, color: Colors.grey),
                    ),
                    selectedDayPredicate: (day) => false,
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, _) {
                        final dayOnly = DateTime(day.year, day.month, day.day);
                        final isFollowup = followUpDates.contains(dayOnly);
                        final isRenewal = renewalDates.contains(dayOnly);
                        final isToday = isSameDay(dayOnly, DateTime.now());

                        if (isFollowup || isRenewal) {
                          return Container(
                            margin: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          );
                        }

                        if (isToday) {
                          return Container(
                            margin: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.indigo,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          );
                        }

                        return null;
                      },
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      Navigator.pop(bottomSheetContext);

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (rootContext.mounted) {
                          _showDayFollowUps(rootContext, selectedDay);
                        }
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> handleLogout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // remove token + userData

    Provider.of<UserProvider>(context, listen: false).logout();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginModalScreen()),
          (route) => false,
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // keyboard pushes only body
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()));
            },
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 30,
              child: ClipOval(
                child: Image.asset(
                  "assets/logo.png",
                  height: 122,
                  width: 150,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        centerTitle: true,
        title: Text(
          'Dextra Workspace',
          style: GoogleFonts.notoSans(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GestureDetector(
              onTap: () => handleLogout(context),
              child: const Icon(Icons.logout,
                  color: Colors.black),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationPage()),
                );
              },
              child: const Icon(Icons.notification_add_outlined,
                  color: Colors.black),
            ),
          ),
        ],
      ),

      /// 🔥 THIS SAFEAREA FIXES THE WHITE SPACE PROBLEM
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(Duration(milliseconds: 500));
            await _fetchThisWeekHostings();
            await _fetchTodayFollowUps();
            await _fetchThisWeekFollowUpCount();
            await _loadFollowUpDatesFromApi();
            fetchHostingCounts();
            fetchWeeklyHostingSummary();
            await _fetchHostingCountOnly();
            print("✅ Dashboard refreshed via pull-down swipe");
          },
          child: _getSelectedPage(),
        ),
      ),

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 10,
        color: Colors.white,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _bottomIcon(
                index: 0,
                icon: Icons.home,
                label: "Home",
              ),
              _bottomIcon(
                index: 1,
                icon: Icons.assignment_ind_outlined,
                label: "Client",
              ),

              const SizedBox(width: 45), // FAB space

              _bottomIcon(
                index: 2,
                icon: Icons.access_time,
                label: "Domain",
              ),
              _bottomIcon(
                index: 3,
                icon: Icons.group_add_rounded,
                label: "Meetings",
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        elevation: 6,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CalendarScreen()),
          );
        },
        child: const Icon(Icons.calendar_month, size: 30, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }



  Widget _bottomIcon({required int index, required IconData icon, required String label}) {
    return InkWell(
      onTap: () {
        setState(() => _currentIndex = index);
      },
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 27,
              color: _currentIndex == index ? Colors.indigo : Colors.grey,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: _currentIndex == index ? Colors.indigo : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(
            Duration(milliseconds: 600)); // optional smoother feel
        await _fetchThisWeekHostings();
        await _fetchTodayFollowUps();
        await _fetchThisWeekFollowUpCount();
        await _loadFollowUpDatesFromApi();
        await _fetchHostingCountOnly();
        print("✅ Dashboard refreshed via swipe.");
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Dashboard",
                    style: GoogleFonts.notoSans(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          await _loadFollowUpDatesFromApi();
                          _showCalendarDialog(context);
                        },
                        child: Text("This Week",
                            style: GoogleFonts.notoSans(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            /// Your two cards
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => FollowUpsPage()));
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      color: const Color(0xFFE8F0FF),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text("+$thisWeekFollowUpCount",
                                style: GoogleFonts.notoSans(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            const Icon(Icons.timer,
                                size: 26, color: Colors.blue),
                            const SizedBox(height: 6),
                            Text("Follow Ups",
                                style: GoogleFonts.notoSans(fontSize: 12)),
                            Text("This Week",
                                style: GoogleFonts.notoSans(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 6),
                            Text("View Status",
                                style: GoogleFonts.notoSans(
                                    color: Colors.blue, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LeadsScreen()));
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      color: const Color(0xFFFFF2E6),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text("+$_hostingCount",
                                style: GoogleFonts.notoSans(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            const Icon(Icons.attach_money,
                                size: 26, color: Colors.orange),
                            const SizedBox(height: 6),
                            Text("Server Renewal",
                                style: GoogleFonts.notoSans(fontSize: 12)),
                            Text("This Week",
                                style: GoogleFonts.notoSans(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 6),
                            Text("View Report",
                                style: GoogleFonts.notoSans(
                                    color: Colors.orange, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const WeeklyHostingSummaryPage()),
                      );
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      color: const Color(0xFFE7CDF1),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              "₹$thisWeekHostingAmount",
                              style: GoogleFonts.notoSans(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const Icon(Icons.money_rounded,
                                size: 26, color: Colors.purpleAccent),
                            const SizedBox(height: 6),
                            Text(
                              "$thisWeekHostingCount Hosting(s)",
                              style: GoogleFonts.notoSans(fontSize: 12),
                            ),
                            Text(
                              "This Week",
                              style: GoogleFonts.notoSans(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "View Status",
                              style: GoogleFonts.notoSans(
                                  color: Colors.purpleAccent, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => DomainPage()));
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      color: const Color(0xB7CBE9F6),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              "$dextraCount / $clientCount",
                              style: GoogleFonts.notoSans(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const Icon(Icons.safety_divider_outlined,
                                size: 26, color: Colors.teal),
                            const SizedBox(height: 6),
                            Text("Dextra/Client server",
                                style: GoogleFonts.notoSans(fontSize: 12)),
                            Text("This Week",
                                style: GoogleFonts.notoSans(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 6),
                            Text("View Report",
                                style: GoogleFonts.notoSans(
                                    color: Colors.teal, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// Activity Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Activity",
                    style: GoogleFonts.notoSans(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showAllActivities = !_showAllActivities;
                    });
                  },
                  child: Text(
                    _showAllActivities ? "View Less" : "View All",
                    style:
                        GoogleFonts.notoSans(color: Colors.blue, fontSize: 12),
                  ),
                ),
              ],
            ),
            ...(_showAllActivities
                    ? _thisWeekHostings
                    : _thisWeekHostings.take(3))
                .where((item) {
                  final expDate =
                      DateTime.tryParse(item['expiring_date'] ?? '');
                  if (expDate == null) return false;

                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  final expiry =
                      DateTime(expDate.year, expDate.month, expDate.day);

                  return !expiry.isBefore(today);
                })
                .toList()
                .asMap()
                .entries
                .map((entry) {
                  final i = entry.key;
                  final item = entry.value;

                  final expDate =
                      DateTime.tryParse(item['expiring_date'] ?? '');
                  final date = expDate != null
                      ? expDate.day.toString().padLeft(2, '0')
                      : '--';
                  final month =
                      expDate != null ? _monthName(expDate.month) : '--';

                  final d =
                      i < _countdowns.length ? _countdowns[i] : Duration.zero;
                  final days = d.inDays.toString().padLeft(2, '0');
                  final hours = (d.inHours % 24).toString().padLeft(2, '0');
                  final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');

                  return _buildActivityItem(
                    date: date,
                    month: month,
                    title: item['company_name'] ?? '',
                    subtitle: item['hosting_name'] ?? '',
                    time: "10:00 AM - 12:00 PM",
                    duration: "$days : $hours : $minutes",
                  );
                })
                .toList(),

            const SizedBox(height: 20),

            Text("Client Follow-ups",
                style: GoogleFonts.notoSans(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (todayFollowUps.isEmpty)
              Text("No follow-ups for today",
                  style:
                      GoogleFonts.notoSans(color: Colors.grey, fontSize: 12)),
            ...todayFollowUps.map((item) => _buildClientMessage(
                  id: item['id'],
                  title: item['name'],
                  content: item['company_name'],
                  time: "Today",
                  enquiry: item['enquiry'],
                  phone: item['phone'],
                  onStatusCompleted: () {
                    setState(() {
                      todayFollowUps.removeWhere(
                          (element) => element['id'] == item['id']);
                    });
                  },
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required String date, // e.g., "11"
    required String month, // e.g., "Jul"
    required String title, // e.g., "Tech Corp"
    required String subtitle, // e.g., "HostGator"
    required String time, // e.g., "10:00 AM - 12:00 PM"
    required String duration, // e.g., "03 : 12 : 45"
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      color: Colors.white,
      child: ListTile(
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(date,
                style: GoogleFonts.notoSans(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            Text(month,
                style: GoogleFonts.notoSans(color: Colors.grey, fontSize: 12)),
          ],
        ),
        title: Text(title,
            style: GoogleFonts.notoSans(
                fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle, style: GoogleFonts.notoSans(fontSize: 12)),
            Text(time, style: GoogleFonts.notoSans(fontSize: 12)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer, color: Colors.green, size: 20),
            const SizedBox(height: 4),
            Text(duration, style: GoogleFonts.notoSans(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildClientMessage({
    required int id,
    required String title,
    required String content,
    required String time,
    required String enquiry,
    required String phone,
    required VoidCallback onStatusCompleted,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.notoSans(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 14),
                      onPressed: () {
                        _showClientActionDialog(
                          context,
                          title,
                          id,
                          () {
                            setState(() {
                              todayFollowUps.removeWhere(
                                  (element) => element['id'] == id);
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () async {
                        final Uri launchUri = Uri(scheme: 'tel', path: phone);
                        try {
                          if (!await launchUrl(launchUri)) {
                            throw Exception('Could not launch $launchUri');
                          }
                        } catch (_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Could not open dialer')),
                          );
                        }
                      },
                      child:
                          const Icon(Icons.call, color: Colors.green, size: 14),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              "Enquiry: $enquiry",
              style: GoogleFonts.notoSans(
                  color: Colors.blue,
                  fontSize: 11,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(content, style: GoogleFonts.notoSans(fontSize: 12)),
            const SizedBox(height: 2),
            Text(time,
                style: GoogleFonts.notoSans(color: Colors.grey, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
