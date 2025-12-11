import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import 'Domainpage.dart';
class LeadsScreen extends StatefulWidget {
  @override
  _LeadsScreenState createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {

  List<dynamic> today = [];
  String? _selectedHostingType;


  List<dynamic> _thisWeekHostings = [];
  List<dynamic> nextWeek = [];
  List<dynamic> upcoming = [];
  List<dynamic> _domainRenewals = [];

  List<dynamic> _allHostings = [];
  List<dynamic> _filteredHostings = [];

  TextEditingController _searchController = TextEditingController();

  DateTime? _selectedHostingDate;
  DateTime? _selectedExpiringDate;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();


  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _hostingController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _hostingDateController = TextEditingController();
  final TextEditingController _lastDateController = TextEditingController();
  final TextEditingController _expiringDateController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();


  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  void _filterHostings(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      if (q.isEmpty) {
        _filteredHostings = List.from(_thisWeekHostings);
      } else {
        _filteredHostings = _thisWeekHostings.where((item) {
          final company = (item['company_name'] ?? '').toString().toLowerCase();
          final hosting = (item['hosting_name'] ?? '').toString().toLowerCase();
          return company.contains(q) || hosting.contains(q);
        }).toList();
      }
    });
  }



  Future<void> _fetchDomainRenewals() async {
    final url = Uri.parse("https://servernewapp.rentalsprime.in/api/hostings-this-week");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _domainRenewals = data['data'];
          _allHostings = data['data'];
          _filteredHostings = _allHostings;
        });
      } else {
        print("❌ Failed to fetch domain renewals");
      }
    } catch (e) {
      print("❌ Exception: $e");
    }
  }

  void _performSearch(String query) {
    final lowerQuery = query.toLowerCase();

    setState(() {
      _filteredHostings = _allHostings.where((item) {
        final name = (item['company_name'] ?? '').toString().toLowerCase();
        final hosting = (item['hosting_name'] ?? '').toString().toLowerCase();
        final email = (item['email'] ?? '').toString().toLowerCase();

        return name.contains(lowerQuery) || hosting.contains(lowerQuery) || email.contains(lowerQuery);
      }).toList();
    });
  }




  final List<Map<String, String>> leads = [
    {
      'name': 'Devon Lane',
      'email': 'devon.lane@gmail.com',
      'phone': '(684) 123-1234',
      'status': 'New',
      'date': '8 May',
      'initials': 'DL',
    },
    {
      'name': 'Floyd Miles',
      'email': 'floyd.miles@gmail.com',
      'phone': '(684) 432-7654',
      'status': 'In Progress',
      'date': '9 May',
      'initials': 'FM',
    },
    {
      'name': 'Dianne Russell',
      'email': 'dianne.russell@gmail.com',
      'phone': '(684) 256-9842',
      'status': 'No Answer',
      'date': '10 May',
      'initials': 'DR',
    },
    {
      'name': 'Ronald Richards',
      'email': 'ronald.richards@gmail.com',
      'phone': '(684) 342-0912',
      'status': 'Converted',
      'date': '11 May',
      'initials': 'RR',
    },
  ];


  @override
  void initState() {
    super.initState();
    _fetchFollowUps();
    _fetchDomainRenewals();
    _searchController.addListener(() {
      _filterHostings(_searchController.text);
    });
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
        _clearHostingFormFields();
      }

    } catch (e) {
      print("❌ Error fetching leads: $e");
    }
  }

  // Future<void> _pickContact(BuildContext context, TextEditingController controller) async {
  //   // Step 1: Request permission using permission_handler
  //   final status = await Permission.contacts.request();
  //
  //   if (status.isPermanentlyDenied) {
  //     // Show a snackbar with Settings redirection
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: const Text('Contacts permission permanently denied. Please enable it in settings.'),
  //         action: SnackBarAction(
  //           label: 'Settings',
  //           onPressed: () {
  //             openAppSettings();
  //           },
  //         ),
  //       ),
  //     );
  //     return;
  //   }
  //
  //   if (!status.isGranted) {
  //     // Handle normal denial
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('❌ Contacts permission denied')),
  //     );
  //     return;
  //   }
  //
  //   // Step 2: Open external contact picker using flutter_contacts
  //   try {
  //     final contact = await FlutterContacts.openExternalPick();
  //
  //     if (contact != null && contact.phones.isNotEmpty) {
  //       // Extract the first available phone number
  //       final phone = contact.phones.first.number.replaceAll(RegExp(r'\s+'), '');
  //       controller.text = phone;
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('No phone number found in this contact')),
  //       );
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error picking contact: ${e.toString()}')),
  //     );
  //   }
  // }

  Future<void> _pickContact(BuildContext context, TextEditingController controller) async {
    // Step 1: Request permission using permission_handler
    final status = await Permission.contacts.request();

    if (status.isPermanentlyDenied) {
      // Show a snackbar with Settings redirection
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Contacts permission permanently denied. Please enable it in settings.'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              openAppSettings();
            },
          ),
        ),
      );
      return;
    }

    if (!status.isGranted) {
      // Handle normal denial
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Contacts permission denied')),
      );
      return;
    }


    try {
      final contact = await FlutterContacts.openExternalPick();

      if (contact != null && contact.phones.isNotEmpty) {
        // Extract the first available phone number
        final phone = contact.phones.first.number.replaceAll(RegExp(r'\s+'), '');
        controller.text = phone;
      } else {
        // No phone number found — copy contact name (if any) to clipboard
        await Clipboard.setData(ClipboardData(text: contact?.displayName ?? ''));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No phone number found. Name copied to clipboard. Please paste it manually.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking contact: ${e.toString()}')),
      );
    }
  }



  Color getStatusColor(String status) {
    switch (status) {
      case 'New':
        return Colors.blue;
      case 'In Progress':
        return Colors.orange;
      case 'No Answer':
        return Colors.purple;
      case 'Converted':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInputField({
    required String label,
    TextEditingController? controller,
    int maxLines = 1,
    IconData? suffixIcon,
    VoidCallback? onSuffixTap,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: GoogleFonts.poppins(fontSize: 13),
            decoration: InputDecoration(
              hintText: hintText,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              suffixIcon: suffixIcon != null
                  ? IconButton(
                icon: Icon(suffixIcon, color: Colors.blue),
                onPressed: onSuffixTap,
              )
                  : null,
            ),
          ),
        ],
      ),
    );
  }



  // Widget _buildInputField({
  //   required String label,
  //   TextEditingController? controller,
  //   int maxLines = 1,
  // }) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 12),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(label, style: GoogleFonts.poppins(fontSize: 13)),
  //         const SizedBox(height: 6),
  //         TextField(
  //           controller: controller,
  //           maxLines: maxLines,
  //           style: GoogleFonts.poppins(fontSize: 13),
  //           decoration: InputDecoration(
  //             contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  //             border: OutlineInputBorder(
  //               borderRadius: BorderRadius.circular(10),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void _clearHostingFormFields() {
    _companyController.clear();
    _hostingController.clear();
    _emailController.clear();
    _phoneController.clear();
    _hostingDateController.clear();
    _expiringDateController.clear();
    _remarksController.clear();
    _selectedHostingDate = null;
    _selectedExpiringDate = null;
  }


  Widget _buildLeadTile(Map<String, dynamic> lead) {
    final name = lead['name'] ?? 'No Name';
    final phone = lead['phone'] ?? 'No Phone';
    final company = lead['company_name'] ?? 'No Company';
    final address = lead['address'] ?? 'No Address';
    final enquiry = lead['enquiry'] ?? 'No Enquiry';
    final type = lead['type'] ?? 'No Type';
    final status = lead['status'] ?? 'Unknown';
    final followUpDate = lead['follow_up'] ?? 'No Date';

    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'NA';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      leading: CircleAvatar(
        backgroundColor: getStatusColor(status),
        child: Text(
          initials,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      title: Text(
        name,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("📞 $phone", style: GoogleFonts.poppins(fontSize: 12)),
          Text("🏢 $company", style: GoogleFonts.poppins(fontSize: 12)),
          Text("📍 $address", style: GoogleFonts.poppins(fontSize: 12)),
          Text("💬 Enquiry: $enquiry", style: GoogleFonts.poppins(fontSize: 12)),
          Text("📄 Type: $type", style: GoogleFonts.poppins(fontSize: 12)),
        ],
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            followUpDate,
            style: GoogleFonts.poppins(fontSize: 11),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: getStatusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: getStatusColor(status),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      isThreeLine: true,
    );
  }



  // Future<void> _submitDomainRenewal() async {
  //   final url = Uri.parse("https://servernewapp.rentalsprime.in/api/hosting");
  //
  //   final formData = {
  //     "company_name": _companyController.text,
  //     "hosting_name": _hostingController.text,
  //     "email": _emailController.text,
  //     "phone_no": _phoneController.text,
  //     "hosting_date": _hostingDateController.text,
  //     "expiring_date": _expiringDateController.text,
  //     "remarks": _remarksController.text,
  //   };
  //
  //   print("🔼 Sending Hosting Data: $formData");
  //
  //   try {
  //     final response = await http.post(
  //       url,
  //       headers: {"Content-Type": "application/json"},
  //       body: jsonEncode(formData),
  //     );
  //
  //     print("📩 API Response Status: ${response.statusCode}");
  //     print("📦 API Response Body: ${response.body}");
  //
  //     final responseData = json.decode(response.body);
  //
  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       _clearHostingFormFields();
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('✅ Hosting detail added successfully')),
  //       );
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text("❌ Server Error: ${responseData['message'] ?? 'Unknown error'}")),
  //       );
  //     }
  //   } catch (e) {
  //     print("❌ Exception during POST: $e");
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("❌ Something went wrong, check console")),
  //     );
  //   }
  // }

  Future<void> _submitDomainRenewal() async {
    final url = Uri.parse("https://servernewapp.rentalsprime.in/api/hosting");

    final formData = {
      "company_name": _companyController.text,
      "hosting_name": _hostingController.text,
      "email": _emailController.text,
      "phone_no": _phoneController.text,
      "hosting_date": _hostingDateController.text,
      "expiring_date": _expiringDateController.text,
      "last_renewal_date": _lastDateController.text,
      "hosted_by": _selectedHostingType ?? '',
      "amount": _amountController.text,
      "remarks": _remarksController.text,
    };

    print("🔼 Sending Hosting Data: $formData");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          // "Authorization": "Bearer YOUR_TOKEN", // Uncomment if needed
        },
        body: jsonEncode(formData),
      );

      print("📩 API Response Status: ${response.statusCode}");
      print("📩 Content-Type: ${response.headers['content-type']}");
      print("📦 API Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        _clearHostingFormFields();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? '✅ Hosting detail added successfully')),
        );
      } else if (response.statusCode == 302) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Redirected to login or base URL. Check endpoint or auth.")),
        );
      } else if (response.headers['content-type']?.contains('application/json') == true) {
        final responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Server Error: ${responseData['message'] ?? 'Unknown error'}")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Unexpected response format from server.")),
        );
      }
    } catch (e) {
      print("❌ Exception during POST: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Exception: ${e.toString()}")),
      );
    }
  }


  // void _showRenewUpdateBottomSheet(BuildContext context) {
  //   DateTime? renewDate;
  //   DateTime? expiryDate;
  //
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     backgroundColor: Colors.white,
  //     builder: (context) {
  //       return Padding(
  //         padding: EdgeInsets.only(
  //           left: 16,
  //           right: 16,
  //           top: 20,
  //           bottom: MediaQuery.of(context).viewInsets.bottom + 20,
  //         ),
  //         child: StatefulBuilder(
  //           builder: (context, setState) {
  //             return Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Text(
  //                   'Renew / Update Details',
  //                   style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
  //                 ),
  //                 const SizedBox(height: 20),
  //
  //                 // Renew Date
  //                 GestureDetector(
  //                   onTap: () async {
  //                     final picked = await showDatePicker(
  //                       context: context,
  //                       initialDate: DateTime.now(),
  //                       firstDate: DateTime(2020),
  //                       lastDate: DateTime(2100),
  //                     );
  //                     if (picked != null) {
  //                       setState(() => renewDate = picked);
  //                     }
  //                   },
  //                   child: Container(
  //                     width: double.infinity,
  //                     padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
  //                     decoration: BoxDecoration(
  //                       border: Border.all(color: Colors.grey.shade300),
  //                       borderRadius: BorderRadius.circular(10),
  //                     ),
  //                     child: Text(
  //                       renewDate != null
  //                           ? 'Renew Date: ${renewDate!.day}/${renewDate!.month}/${renewDate!.year}'
  //                           : 'Select Renew Date',
  //                       style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
  //                     ),
  //                   ),
  //                 ),
  //                 const SizedBox(height: 12),
  //
  //                 // Expiry Date
  //                 GestureDetector(
  //                   onTap: () async {
  //                     final picked = await showDatePicker(
  //                       context: context,
  //                       initialDate: DateTime.now(),
  //                       firstDate: DateTime(2020),
  //                       lastDate: DateTime(2100),
  //                     );
  //                     if (picked != null) {
  //                       setState(() => expiryDate = picked);
  //                     }
  //                   },
  //                   child: Container(
  //                     width: double.infinity,
  //                     padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
  //                     decoration: BoxDecoration(
  //                       border: Border.all(color: Colors.grey.shade300),
  //                       borderRadius: BorderRadius.circular(10),
  //                     ),
  //                     child: Text(
  //                       expiryDate != null
  //                           ? 'Expiry Date: ${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}'
  //                           : 'Select Expiry Date',
  //                       style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
  //                     ),
  //                   ),
  //                 ),
  //
  //                 const SizedBox(height: 24),
  //
  //                 // Submit Button
  //                 ElevatedButton(
  //                   onPressed: () {
  //                     if (renewDate == null || expiryDate == null) {
  //                       ScaffoldMessenger.of(context).showSnackBar(
  //                         const SnackBar(content: Text('Please select both dates')),
  //                       );
  //                       return;
  //                     }
  //
  //                     // You can print or send these dates to your API here
  //                     print('📅 Renew Date: $renewDate');
  //                     print('📅 Expiry Date: $expiryDate');
  //
  //                     Navigator.pop(context); // Close the bottom sheet
  //
  //                     ScaffoldMessenger.of(context).showSnackBar(
  //                       const SnackBar(content: Text('✅ Dates updated successfully')),
  //                     );
  //                   },
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: Colors.indigo,
  //                     padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
  //                     shape: RoundedRectangleBorder(
  //                       borderRadius: BorderRadius.circular(10),
  //                     ),
  //                   ),
  //                   child: Text(
  //                     'Submit',
  //                     style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
  //                   ),
  //                 ),
  //               ],
  //             );
  //           },
  //         ),
  //       );
  //     },
  //   );
  // }

  // void _showRenewUpdateBottomSheet(BuildContext context) {
  //   DateTime? renewDate;
  //   DateTime? expiryDate;
  //
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     backgroundColor: Colors.white,
  //     builder: (context) {
  //       return Padding(
  //         padding: EdgeInsets.only(
  //           left: 16,
  //           right: 16,
  //           top: 20,
  //           bottom: MediaQuery.of(context).viewInsets.bottom + 20,
  //         ),
  //         child: StatefulBuilder(
  //           builder: (context, setState) {
  //             return Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Text(
  //                   'Renew / Update Details',
  //                   style: GoogleFonts.poppins(
  //                     fontSize: 16,
  //                     fontWeight: FontWeight.w600,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 20),
  //
  //                 // 🔁 Renew Date Field with Icon
  //                 GestureDetector(
  //                   onTap: () async {
  //                     final picked = await showDatePicker(
  //                       context: context,
  //                       initialDate: DateTime.now(),
  //                       firstDate: DateTime(2020),
  //                       lastDate: DateTime(2100),
  //                     );
  //                     if (picked != null) {
  //                       setState(() => renewDate = picked);
  //                     }
  //                   },
  //                   child: Container(
  //                     width: double.infinity,
  //                     padding: const EdgeInsets.symmetric(
  //                         vertical: 14, horizontal: 12),
  //                     decoration: BoxDecoration(
  //                       border: Border.all(color: Colors.grey.shade300),
  //                       borderRadius: BorderRadius.circular(10),
  //                     ),
  //                     child: Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                       children: [
  //                         Text(
  //                           renewDate != null
  //                               ? 'Renew Date: ${renewDate!.day}/${renewDate!.month}/${renewDate!.year}'
  //                               : 'Select Renew Date',
  //                           style: GoogleFonts.poppins(
  //                               fontSize: 14, color: Colors.black87),
  //                         ),
  //                         const Icon(Icons.calendar_today_outlined,
  //                             size: 18, color: Colors.grey),
  //                       ],
  //                     ),
  //                   ),
  //                 ),
  //
  //                 const SizedBox(height: 12),
  //
  //                 // 🔁 Expiry Date Field with Icon
  //                 GestureDetector(
  //                   onTap: () async {
  //                     final picked = await showDatePicker(
  //                       context: context,
  //                       initialDate: DateTime.now(),
  //                       firstDate: DateTime(2020),
  //                       lastDate: DateTime(2100),
  //                     );
  //                     if (picked != null) {
  //                       setState(() => expiryDate = picked);
  //                     }
  //                   },
  //                   child: Container(
  //                     width: double.infinity,
  //                     padding: const EdgeInsets.symmetric(
  //                         vertical: 14, horizontal: 12),
  //                     decoration: BoxDecoration(
  //                       border: Border.all(color: Colors.grey.shade300),
  //                       borderRadius: BorderRadius.circular(10),
  //                     ),
  //                     child: Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                       children: [
  //                         Text(
  //                           expiryDate != null
  //                               ? 'Expiry Date: ${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}'
  //                               : 'Select Expiry Date',
  //                           style: GoogleFonts.poppins(
  //                               fontSize: 14, color: Colors.black87),
  //                         ),
  //                         const Icon(Icons.calendar_today_outlined,
  //                             size: 18, color: Colors.grey),
  //                       ],
  //                     ),
  //                   ),
  //                 ),
  //
  //                 const SizedBox(height: 24),
  //
  //                 // ✅ Submit Button
  //                 ElevatedButton(
  //                   onPressed: () {
  //                     if (renewDate == null || expiryDate == null) {
  //                       ScaffoldMessenger.of(context).showSnackBar(
  //                         const SnackBar(
  //                             content: Text('Please select both dates')),
  //                       );
  //                       return;
  //                     }
  //
  //                     // Print or send to API here
  //                     print('📅 Renew Date: $renewDate');
  //                     print('📅 Expiry Date: $expiryDate');
  //
  //                     Navigator.pop(context); // Close the bottom sheet
  //
  //                     ScaffoldMessenger.of(context).showSnackBar(
  //                       const SnackBar(
  //                           content: Text('✅ Dates updated successfully')),
  //                     );
  //                   },
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: Colors.indigo,
  //                     padding: const EdgeInsets.symmetric(
  //                         horizontal: 30, vertical: 12),
  //                     shape: RoundedRectangleBorder(
  //                       borderRadius: BorderRadius.circular(10),
  //                     ),
  //                   ),
  //                   child: Text(
  //                     'Submit',
  //                     style: GoogleFonts.poppins(
  //                         fontSize: 14, color: Colors.white),
  //                   ),
  //                 ),
  //               ],
  //             );
  //           },
  //         ),
  //       );
  //     },
  //   );
  // }


  void _showRenewUpdateBottomSheet(
      BuildContext context, {
        required int id,
        required VoidCallback onSuccess,
      }) {
    DateTime? renewDate;
    DateTime? expiryDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
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
                children: [
                  Text(
                    'Renew / Update Details',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🔁 Renew Date Field with Icon
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => renewDate = picked);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            renewDate != null
                                ? 'Renew Date: ${renewDate!.day}/${renewDate!.month}/${renewDate!.year}'
                                : 'Select Renew Date',
                            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                          ),
                          const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),


                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => expiryDate = picked);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            expiryDate != null
                                ? 'Expiry Date: ${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}'
                                : 'Select Expiry Date',
                            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                          ),
                          const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),


                  ElevatedButton(
                    onPressed: () async {
                      if (renewDate == null || expiryDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select both dates')),
                        );
                        return;
                      }

                      final body = {
                        "id": id,
                        "hosting_date":
                        "${renewDate!.year}-${renewDate!.month.toString().padLeft(2, '0')}-${renewDate!.day.toString().padLeft(2, '0')}",
                        "expiring_date":
                        "${expiryDate!.year}-${expiryDate!.month.toString().padLeft(2, '0')}-${expiryDate!.day.toString().padLeft(2, '0')}",
                      };

                      try {
                        final response = await http.post(
                          Uri.parse("https://servernewapp.rentalsprime.in/api/hosting/update-dates"),
                          headers: {"Content-Type": "application/json"},
                          body: jsonEncode(body),
                        );

                        print("📥 API Response: ${response.body}");

                        final data = jsonDecode(response.body);


                        if (response.statusCode == 200 && data['success'] == true) {
                          Navigator.pop(context); // ✅ Close the sheet
                          onSuccess(); 
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("✅ ${data['message'] ?? 'Dates updated successfully'}")),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("❌ ${data['message'] ?? 'Update failed'}")),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error: $e")),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Submit',
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }



  // void _showRenewUpdateBottomSheet(
  //     BuildContext context, {
  //       required int id,
  //       required VoidCallback onSuccess,
  //     }) {
  //   DateTime? renewDate;
  //   DateTime? expiryDate;
  //
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     backgroundColor: Colors.white,
  //     builder: (context) {
  //       return Padding(
  //         padding: EdgeInsets.only(
  //           left: 16,
  //           right: 16,
  //           top: 20,
  //           bottom: MediaQuery.of(context).viewInsets.bottom + 20,
  //         ),
  //         child: StatefulBuilder(
  //           builder: (context, setState) {
  //             return Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Text(
  //                   'Renew / Update Details',
  //                   style: GoogleFonts.poppins(
  //                     fontSize: 16,
  //                     fontWeight: FontWeight.w600,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 20),
  //
  //                 // 🔁 Renew Date with Calendar Icon
  //                 GestureDetector(
  //                   onTap: () async {
  //                     final picked = await showDatePicker(
  //                       context: context,
  //                       initialDate: DateTime.now(),
  //                       firstDate: DateTime(2020),
  //                       lastDate: DateTime(2100),
  //                     );
  //                     if (picked != null) {
  //                       setState(() => renewDate = picked);
  //                     }
  //                   },
  //                   child: Container(
  //                     width: double.infinity,
  //                     padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
  //                     decoration: BoxDecoration(
  //                       border: Border.all(color: Colors.grey.shade300),
  //                       borderRadius: BorderRadius.circular(10),
  //                     ),
  //                     child: Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                       children: [
  //                         Text(
  //                           renewDate != null
  //                               ? 'Renew Date: ${renewDate!.day}/${renewDate!.month}/${renewDate!.year}'
  //                               : 'Select Renew Date',
  //                           style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
  //                         ),
  //                         const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
  //                       ],
  //                     ),
  //                   ),
  //                 ),
  //                 const SizedBox(height: 12),
  //
  //                 // 🔁 Expiry Date with Calendar Icon
  //                 GestureDetector(
  //                   onTap: () async {
  //                     final picked = await showDatePicker(
  //                       context: context,
  //                       initialDate: DateTime.now(),
  //                       firstDate: DateTime(2020),
  //                       lastDate: DateTime(2100),
  //                     );
  //                     if (picked != null) {
  //                       setState(() => expiryDate = picked);
  //                     }
  //                   },
  //                   child: Container(
  //                     width: double.infinity,
  //                     padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
  //                     decoration: BoxDecoration(
  //                       border: Border.all(color: Colors.grey.shade300),
  //                       borderRadius: BorderRadius.circular(10),
  //                     ),
  //                     child: Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                       children: [
  //                         Text(
  //                           expiryDate != null
  //                               ? 'Expiry Date: ${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}'
  //                               : 'Select Expiry Date',
  //                           style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
  //                         ),
  //                         const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
  //                       ],
  //                     ),
  //                   ),
  //                 ),
  //
  //                 const SizedBox(height: 24),
  //
  //                 // ✅ Submit Button
  //                 ElevatedButton(
  //                   onPressed: () async {
  //                     if (renewDate == null || expiryDate == null) {
  //                       ScaffoldMessenger.of(context).showSnackBar(
  //                         const SnackBar(content: Text('Please select both dates')),
  //                       );
  //                       return;
  //                     }
  //
  //                     final body = {
  //                       "id": id,
  //                       "hosting_date": "${renewDate!.year}-${renewDate!.month.toString().padLeft(2, '0')}-${renewDate!.day.toString().padLeft(2, '0')}",
  //                       "expiring_date": "${expiryDate!.year}-${expiryDate!.month.toString().padLeft(2, '0')}-${expiryDate!.day.toString().padLeft(2, '0')}",
  //                     };
  //
  //                     try {
  //                       final response = await http.post(
  //                         Uri.parse("https://servernewapp.rentalsprime.in/api/hosting/update-dates"),
  //                         headers: {"Content-Type": "application/json"},
  //                         body: jsonEncode(body),
  //                       );
  //
  //                       print("📥 API Response: ${response.body}");
  //
  //                       final data = jsonDecode(response.body);
  //                       if (response.statusCode == 200 && data['status'] == true) {
  //                         onSuccess(); // ✅ Remove card or refresh UI
  //                         Navigator.pop(context);
  //                         ScaffoldMessenger.of(context).showSnackBar(
  //                           SnackBar(content: Text("✅ ${data['message'] ?? 'Dates updated successfully'}")),
  //                         );
  //                       } else {
  //                         ScaffoldMessenger.of(context).showSnackBar(
  //                           SnackBar(content: Text("❌ ${data['message'] ?? 'Update failed'}")),
  //                         );
  //                       }
  //                     } catch (e) {
  //                       ScaffoldMessenger.of(context).showSnackBar(
  //                         SnackBar(content: Text("Error: $e")),
  //                       );
  //                     }
  //                   },
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: Colors.indigo,
  //                     padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
  //                     shape: RoundedRectangleBorder(
  //                       borderRadius: BorderRadius.circular(10),
  //                     ),
  //                   ),
  //                   child: Text(
  //                     'Submit',
  //                     style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
  //                   ),
  //                 ),
  //               ],
  //             );
  //           },
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget _buildDropdownField({
    required String label,
    required List<String> items,
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 13)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: selectedValue,
            items: items.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: GoogleFonts.poppins(fontSize: 13)),
              );
            }).toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }






  void _showCreateHostingPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Create Hosting Detail',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(label: "Company Name * ", controller: _companyController),
                    _buildInputField(label: "Server Name *", controller: _hostingController),
                    _buildInputField(label: "Email ", controller: _emailController),
                    // _buildInputField(label: "Phone Number", controller: _phoneController), // ✅ Added
                    _buildDropdownField(
                      label: 'Hosted By *',
                      items: ['OWN (DEXTRA)', 'Client Server'],
                      selectedValue: _selectedHostingType,
                      onChanged: (value) {
                        setState(() {
                          _selectedHostingType = value;
                        });
                      },
                    ),

                    _buildInputField(
                      label: 'Amount *',
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      hintText: 'Enter amount',
                    ),


                    _buildInputField(
                      label: 'Phone Number *',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      suffixIcon: Icons.contacts,
                      onSuffixTap: () => _pickContact(context, _phoneController),
                      hintText: 'Tap to pick from contacts',
                    ),


                    // Hosting Date
                    // GestureDetector(
                    //   onTap: () async {
                    //     final picked = await showDatePicker(
                    //       context: context,
                    //       initialDate: DateTime.now(),
                    //       firstDate: DateTime(2020),
                    //       lastDate: DateTime(2100),
                    //     );
                    //     if (picked != null) {
                    //       setState(() {
                    //         _selectedHostingDate = picked;
                    //         _hostingDateController.text = _formatDate(picked);
                    //       });
                    //     }
                    //   },
                    //   child: AbsorbPointer(
                    //     child: _buildInputField(
                    //       label: "Hosting Date *",
                    //       controller: _hostingDateController,
                    //     ),
                    //   ),
                    // ),

                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedHostingDate = picked;
                            _hostingDateController.text = _formatDate(picked);
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: _buildInputField(
                          label: "Hosting Date *",
                          controller: _hostingDateController,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Expiring Date



                    // GestureDetector(
                    //   onTap: () async {
                    //     final picked = await showDatePicker(
                    //       context: context,
                    //       initialDate: DateTime.now(),
                    //       firstDate: DateTime(2020),
                    //       lastDate: DateTime(2100),
                    //     );
                    //     if (picked != null) {
                    //       setState(() {
                    //         _selectedHostingDate = picked;
                    //         _hostingDateController.text = _formatDate(picked);
                    //       });
                    //     }
                    //   },
                    //   child: AbsorbPointer(
                    //     child: _buildInputField(
                    //       label: "Last Renewal Date *",
                    //       controller: _hostingDateController,
                    //     ),
                    //   ),
                    // ),

                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _lastDateController.text = _formatDate(picked);
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: _buildInputField(
                          label: "Last Renewal Date *",
                          controller: _lastDateController,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedExpiringDate = picked;
                            _expiringDateController.text = _formatDate(picked); // ✅ FIXED HERE
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: _buildInputField(
                          label: "Expiring Date *",
                          controller: _expiringDateController,
                        ),
                      ),
                    ),


                    // Expiring Date
                    // GestureDetector(
                    //   onTap: () async {
                    //     final picked = await showDatePicker(
                    //       context: context,
                    //       initialDate: DateTime.now(),
                    //       firstDate: DateTime(2020),
                    //       lastDate: DateTime(2100),
                    //     );
                    //     if (picked != null) {
                    //       setState(() {
                    //         _selectedExpiringDate = picked;
                    //         _lastDateController.text = _formatDate(picked);
                    //       });
                    //     }
                    //   },
                    //   child: AbsorbPointer(
                    //     child: _buildInputField(
                    //       label: "Expiring Date *",
                    //       controller: _expiringDateController,
                    //     ),
                    //   ),
                    // ),

                    _buildInputField(label: "Remarks", controller: _remarksController, maxLines: 3),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _submitDomainRenewal();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Add Hosting Detail",
                          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }








  // void _showCreateHostingPopup(BuildContext context) {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder: (context) {
  //       return Padding(
  //         padding: EdgeInsets.only(
  //           bottom: MediaQuery.of(context).viewInsets.bottom,
  //           left: 16,
  //           right: 16,
  //           top: 24,
  //         ),
  //         child: SingleChildScrollView(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Center(
  //                 child: Text(
  //                   'Create Hosting Detail',
  //                   style: GoogleFonts.poppins(
  //                     fontSize: 16,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //               ),
  //               const SizedBox(height: 20),
  //               _buildInputField(label: "Company Name"),
  //               _buildInputField(label: "Hosting Name"),
  //               _buildInputField(label: "Email"),
  //               _buildInputField(label: "Hosting Date (e.g. 10 Jul 2025)"),
  //               _buildInputField(label: "Expiring Date (e.g. 10 Jul 2025)"),
  //               _buildInputField(label: "Remarks", maxLines: 3),
  //               const SizedBox(height: 20),
  //               SizedBox(
  //                 width: double.infinity,
  //                 child: ElevatedButton(
  //                   onPressed: () {
  //                     Navigator.pop(context);
  //                     // Add your logic to store the data
  //                   },
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: Colors.indigo,
  //                     padding: const EdgeInsets.symmetric(vertical: 14),
  //                     shape: RoundedRectangleBorder(
  //                       borderRadius: BorderRadius.circular(12),
  //                     ),
  //                   ),
  //                   child: Text(
  //                     "Add Hosting Detail",
  //                     style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
  //                   ),
  //                 ),
  //               ),
  //               const SizedBox(height: 20),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.black87,
                    labelStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.indigo,
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: const [
                      Tab(text: 'Domains'),
                      Tab(text: 'Leads'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),
              // Padding(
              //   padding: const EdgeInsets.all(12),
              //   child: TextField(
              //     controller: _searchController,
              //     style: GoogleFonts.poppins(fontSize: 13),
              //     onChanged: _performSearch,
              //     decoration: InputDecoration(
              //       prefixIcon: const Icon(Icons.search),
              //       hintText: 'Search by Company, Hosting, Email',
              //       hintStyle: GoogleFonts.poppins(fontSize: 13),
              //       border: OutlineInputBorder(
              //         borderRadius: BorderRadius.circular(12),
              //       ),
              //       contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              //     ),
              //   ),
              // ),
              //
              // const SizedBox(width: 8),
              // IconButton(
              //   icon: const Icon(Icons.language, color: Colors.indigo),
              //   onPressed: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(builder: (context) => const DomainPage()),
              //     );
              //   },
              // ),


              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Search TextField - takes up most of the row
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.poppins(fontSize: 13),
                        onChanged: _performSearch,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search by Company, Hosting, Email',
                          hintStyle: GoogleFonts.poppins(fontSize: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),

                    // Spacer between search and icon
                    const SizedBox(width: 8),

                    // Domain icon button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.indigo,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.language, color: Colors.white),
                        tooltip: 'View Domain Info',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const DomainPage()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),




              Expanded(
                child: TabBarView(
                  children: [

                    // ListView.builder(
                    //   padding: const EdgeInsets.only(bottom: 80),
                    //   itemCount: _domainRenewals.length,
                    //   itemBuilder: (context, index) {
                    //     final domain = _domainRenewals[index];
                    //
                    //     return Card(
                    //       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    //       elevation: 2,
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(12),
                    //       ),
                    //       color: Colors.white,
                    //       child: Padding(
                    //         padding: const EdgeInsets.all(16),
                    //         child: Column(
                    //           crossAxisAlignment: CrossAxisAlignment.start,
                    //           children: [
                    //             // Company & Date Row
                    //             Row(
                    //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //               crossAxisAlignment: CrossAxisAlignment.start,
                    //               children: [
                    //                 // 👇 Company Name - wrapped, max 3 lines
                    //                 Flexible(
                    //                   child: RichText(
                    //                     maxLines: 3,
                    //                     overflow: TextOverflow.ellipsis,
                    //                     text: TextSpan(
                    //                       style: GoogleFonts.poppins(fontSize: 13),
                    //                       children: [
                    //                         TextSpan(
                    //                           text: 'Company Name: ',
                    //                           style: GoogleFonts.poppins(
                    //                             color: Colors.indigo,
                    //                             fontWeight: FontWeight.w600,
                    //                           ),
                    //                         ),
                    //                         TextSpan(
                    //                           text: domain['company_name'] ?? '',
                    //                           style: GoogleFonts.poppins(
                    //                             color: Colors.black87,
                    //                           ),
                    //                         ),
                    //                       ],
                    //                     ),
                    //                   ),
                    //                 ),
                    //
                    //                 const SizedBox(width: 12), // small spacing between text and date
                    //
                    //                 // 👇 Date - fixed to top right
                    //                 Text(
                    //                   "Date: ${domain['expiring_date'] ?? '--'}",
                    //                   style: GoogleFonts.poppins(fontSize: 12),
                    //                 ),
                    //               ],
                    //             ),
                    //
                    //             const SizedBox(height: 8),
                    //             // Hosting Detail
                    //             RichText(
                    //               text: TextSpan(
                    //                 style: GoogleFonts.poppins(fontSize: 12),
                    //                 children: [
                    //                   TextSpan(
                    //                     text: 'Hosting Detail: ',
                    //                     style: GoogleFonts.poppins(
                    //                       color: Colors.indigo,
                    //                       fontWeight: FontWeight.w500,
                    //                     ),
                    //                   ),
                    //                   TextSpan(
                    //                     text: domain['hosting_name'] ?? '',
                    //                     style: GoogleFonts.poppins(
                    //                       color: Colors.black87,
                    //                     ),
                    //                   ),
                    //                 ],
                    //               ),
                    //             ),
                    //             const SizedBox(height: 4),
                    //             // Email
                    //             RichText(
                    //               text: TextSpan(
                    //                 style: GoogleFonts.poppins(fontSize: 12),
                    //                 children: [
                    //                   TextSpan(
                    //                     text: 'Email: ',
                    //                     style: GoogleFonts.poppins(
                    //                       color: Colors.indigo,
                    //                       fontWeight: FontWeight.w500,
                    //                     ),
                    //                   ),
                    //                   TextSpan(
                    //                     text: domain['email'] ?? '',
                    //                     style: GoogleFonts.poppins(
                    //                       color: Colors.black87,
                    //                     ),
                    //                   ),
                    //                 ],
                    //               ),
                    //             ),
                    //             const SizedBox(height: 12),
                    //             // Renew / Update Button
                    //             Row(
                    //               mainAxisAlignment: MainAxisAlignment.end,
                    //               children: [
                    //                 ElevatedButton(
                    //                   onPressed: () {
                    //                     // Add your update logic here
                    //                   },
                    //                   style: ElevatedButton.styleFrom(
                    //                     backgroundColor: Colors.indigo,
                    //                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    //                     shape: RoundedRectangleBorder(
                    //                       borderRadius: BorderRadius.circular(8),
                    //                     ),
                    //                   ),
                    //                   child: Text(
                    //                     "Renew / Update",
                    //                     style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
                    //                   ),
                    //                 ),
                    //               ],
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     );
                    //   },
                    // ),

                    // ListView.builder(
                    //   padding: const EdgeInsets.only(bottom: 80),
                    //   itemCount: _domainRenewals.length,
                    //   itemBuilder: (context, index) {
                    //     final domain = _domainRenewals[index];
                    //
                    //     return Card(
                    //       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    //       elevation: 2,
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(12),
                    //       ),
                    //       color: Colors.white,
                    //       child: Padding(
                    //         padding: const EdgeInsets.all(16),
                    //         child: Column(
                    //           crossAxisAlignment: CrossAxisAlignment.start,
                    //           children: [
                    //             // 🔹 Company Name + Date
                    //             Row(
                    //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //               crossAxisAlignment: CrossAxisAlignment.start,
                    //               children: [
                    //                 // ✅ Company Name (max 3 lines)
                    //                 Expanded(
                    //                   child: Text.rich(
                    //                     TextSpan(
                    //                       children: [
                    //                         TextSpan(
                    //                           text: 'Company Name: ',
                    //                           style: GoogleFonts.poppins(
                    //                             color: Colors.indigo,
                    //                             fontWeight: FontWeight.w600,
                    //                           ),
                    //                         ),
                    //                         TextSpan(
                    //                           text: domain['company_name'] ?? '',
                    //                           style: GoogleFonts.poppins(
                    //                             color: Colors.black87,
                    //                           ),
                    //                         ),
                    //                       ],
                    //                     ),
                    //                     maxLines: 3,
                    //                     overflow: TextOverflow.ellipsis,
                    //                     style: GoogleFonts.poppins(fontSize: 13),
                    //                   ),
                    //                 ),
                    //
                    //                 const SizedBox(width: 12),
                    //
                    //                 // ✅ Expiring Date
                    //                 Text(
                    //                   "Date: ${domain['expiring_date'] ?? '--'}",
                    //                   style: GoogleFonts.poppins(fontSize: 12),
                    //                 ),
                    //               ],
                    //             ),
                    //
                    //             const SizedBox(height: 8),
                    //
                    //             // 🔹 Hosting Detail
                    //             Text.rich(
                    //               TextSpan(
                    //                 children: [
                    //                   TextSpan(
                    //                     text: 'Hosting Detail: ',
                    //                     style: GoogleFonts.poppins(
                    //                       color: Colors.indigo,
                    //                       fontWeight: FontWeight.w500,
                    //                     ),
                    //                   ),
                    //                   TextSpan(
                    //                     text: domain['hosting_name'] ?? '',
                    //                     style: GoogleFonts.poppins(
                    //                       color: Colors.black87,
                    //                     ),
                    //                   ),
                    //                 ],
                    //               ),
                    //               style: GoogleFonts.poppins(fontSize: 12),
                    //             ),
                    //
                    //             const SizedBox(height: 4),
                    //
                    //             // 🔹 Email
                    //             Text.rich(
                    //               TextSpan(
                    //                 children: [
                    //                   TextSpan(
                    //                     text: 'Email: ',
                    //                     style: GoogleFonts.poppins(
                    //                       color: Colors.indigo,
                    //                       fontWeight: FontWeight.w500,
                    //                     ),
                    //                   ),
                    //                   TextSpan(
                    //                     text: domain['email'] ?? '',
                    //                     style: GoogleFonts.poppins(
                    //                       color: Colors.black87,
                    //                     ),
                    //                   ),
                    //                 ],
                    //               ),
                    //               style: GoogleFonts.poppins(fontSize: 12),
                    //             ),
                    //
                    //             const SizedBox(height: 12),
                    //
                    //             // 🔹 Renew / Update Button
                    //             Row(
                    //               mainAxisAlignment: MainAxisAlignment.end,
                    //               children: [
                    //                 ElevatedButton(
                    //                   onPressed: () {
                    //                     _showRenewUpdateBottomSheet(
                    //                       context,
                    //                       id: item['id'],
                    //                       onSuccess: () {
                    //                         setState(() {
                    //                           allItems.removeWhere((element) => element['id'] == item['id']);
                    //                         });
                    //                       },
                    //                     );
                    //
                    //                   },
                    //                   style: ElevatedButton.styleFrom(
                    //                     backgroundColor: Colors.indigo,
                    //                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    //                     shape: RoundedRectangleBorder(
                    //                       borderRadius: BorderRadius.circular(8),
                    //                     ),
                    //                   ),
                    //                   child: Text(
                    //                     "Renew / Update",
                    //                     style: GoogleFonts.poppins(
                    //                       fontSize: 12,
                    //                       color: Colors.white,
                    //                     ),
                    //                   ),
                    //                 )
                    //
                    //               ],
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     );
                    //   },
                    // ),

                    ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: _domainRenewals.length,
                      itemBuilder: (context, index) {
                        final domain = _domainRenewals[index];

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [

                                    Expanded(
                                      child: Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: 'Company Name: ',
                                              style: GoogleFonts.poppins(
                                                color: Colors.indigo,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            TextSpan(
                                              text: domain['company_name'] ?? '',
                                              style: GoogleFonts.poppins(
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(fontSize: 13),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // ✅ Expiring Date
                                    Text(
                                      "Date: ${domain['expiring_date'] ?? '--'}",
                                      style: GoogleFonts.poppins(fontSize: 12),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // 🔹 Hosting Detail
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Hosting Detail: ',
                                        style: GoogleFonts.poppins(
                                          color: Colors.indigo,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      TextSpan(
                                        text: domain['hosting_name'] ?? '',
                                        style: GoogleFonts.poppins(
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),

                                const SizedBox(height: 4),

                                // 🔹 Email
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Email: ',
                                        style: GoogleFonts.poppins(
                                          color: Colors.indigo,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      TextSpan(
                                        text: domain['email'] ?? '',
                                        style: GoogleFonts.poppins(
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),

                                const SizedBox(height: 4),


                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Amount: ',
                                        style: GoogleFonts.poppins(
                                          color: Colors.indigo,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      TextSpan(
                                        text: domain['amount'] ?? '',
                                        style: GoogleFonts.poppins(
                                          color: Colors.pink,fontSize: 14
                                        ),
                                      ),
                                    ],
                                  ),
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),

                                const SizedBox(height: 12),

                                // 🔹 Renew / Update Button
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        _showRenewUpdateBottomSheet(
                                          context,
                                          id: domain['id'],
                                          onSuccess: () {
                                            setState(() {
                                              _domainRenewals.removeWhere(
                                                    (element) => element['id'] == domain['id'],
                                              );
                                            });
                                          },
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.indigo,
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        "Renew / Update",
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),




                    // ListView.builder(
                    //   padding: const EdgeInsets.only(bottom: 80),
                    //   itemCount: 4,
                    //   itemBuilder: (context, index) {
                    //     final domain = [
                    //       {
                    //         'company': 'GoViral',
                    //         'date': '10 Jul 2025',
                    //         'hosting': 'Goviral Host Pro',
                    //         'email': 'contact@goviral.in',
                    //       },
                    //       {
                    //         'company': 'TechNova',
                    //         'date': '22 Jun 2025',
                    //         'hosting': 'Bluehost India',
                    //         'email': 'info@technova.com',
                    //       },
                    //       {
                    //         'company': 'PixelEdge',
                    //         'date': '05 Sep 2025',
                    //         'hosting': 'Hostinger Business',
                    //         'email': 'support@pixeledge.io',
                    //       },
                    //       {
                    //         'company': 'CodeNest',
                    //         'date': '30 Dec 2025',
                    //         'hosting': 'AWS EC2 Instance',
                    //         'email': 'admin@codenest.org',
                    //       },
                    //     ][index];
                    //
                    //     return Card(
                    //       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    //       elevation: 2,
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(12),
                    //       ),
                    //       color: Colors.white,
                    //       child: Padding(
                    //         padding: const EdgeInsets.all(16),
                    //         child: Column(
                    //           crossAxisAlignment: CrossAxisAlignment.start,
                    //           children: [
                    //             // Company & Date Row
                    //             Row(
                    //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //               children: [
                    //                 RichText(
                    //                   text: TextSpan(
                    //                     style: GoogleFonts.poppins(fontSize: 13),
                    //                     children: [
                    //                       TextSpan(
                    //                         text: 'Company Name: ',
                    //                         style: GoogleFonts.poppins(
                    //                           color: Colors.indigo,
                    //                           fontWeight: FontWeight.w600,
                    //                         ),
                    //                       ),
                    //                       TextSpan(
                    //                         text: domain['company'],
                    //                         style: GoogleFonts.poppins(
                    //                           color: Colors.black87,
                    //                         ),
                    //                       ),
                    //                     ],
                    //                   ),
                    //                 ),
                    //                Text(
                    //                   "Date: ${domain['date']}",
                    //                   style: GoogleFonts.poppins(fontSize: 12),
                    //                 ),
                    //               ],
                    //             ),
                    //             const SizedBox(height: 8),
                    //             // Hosting Detail
                    //             RichText(
                    //               text: TextSpan(
                    //                 style: GoogleFonts.poppins(fontSize: 12),
                    //                 children: [
                    //                   TextSpan(
                    //                     text: 'Hosting Detail: ',
                    //                     style: GoogleFonts.poppins(
                    //                       color: Colors.indigo,
                    //                       fontWeight: FontWeight.w500,
                    //                     ),
                    //                   ),
                    //                   TextSpan(
                    //                     text: domain['hosting'],
                    //                     style: GoogleFonts.poppins(
                    //                       color: Colors.black87,
                    //                     ),
                    //                   ),
                    //                 ],
                    //               ),
                    //             ),
                    //             const SizedBox(height: 4),
                    //             // Email
                    //             RichText(
                    //               text: TextSpan(
                    //                 style: GoogleFonts.poppins(fontSize: 12),
                    //                 children: [
                    //                   TextSpan(
                    //                     text: 'Email: ',
                    //                     style: GoogleFonts.poppins(
                    //                       color: Colors.indigo,
                    //                       fontWeight: FontWeight.w500,
                    //                     ),
                    //                   ),
                    //                   TextSpan(
                    //                     text: domain['email'],
                    //                     style: GoogleFonts.poppins(
                    //                       color: Colors.black87,
                    //                     ),
                    //                   ),
                    //                 ],
                    //               ),
                    //             ),
                    //
                    //
                    //
                    //             const SizedBox(height: 12),
                    //             // Renew / Update Button
                    //             Row(
                    //               mainAxisAlignment: MainAxisAlignment.end,
                    //               children: [
                    //                 ElevatedButton(
                    //                   onPressed: () {},
                    //                   style: ElevatedButton.styleFrom(
                    //                     backgroundColor: Colors.indigo,
                    //                     padding: const EdgeInsets.symmetric(
                    //                         horizontal: 20, vertical: 10),
                    //                     shape: RoundedRectangleBorder(
                    //                       borderRadius: BorderRadius.circular(8),
                    //                     ),
                    //                   ),
                    //                   child: Text(
                    //                     "Renew / Update",
                    //                     style: GoogleFonts.poppins(
                    //                         fontSize: 12, color: Colors.white),
                    //                   ),
                    //                 ),
                    //               ],
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     );
                    //   },
                    // ),

                    // ✅ Leads Tab (Your existing logic remains unchanged)
                    // ListView.builder(
                    //   padding: const EdgeInsets.only(bottom: 80),
                    //   itemCount: leads.length,
                    //   itemBuilder: (context, index) {
                    //     final lead = leads[index];
                    //     return ListTile(
                    //       leading: CircleAvatar(
                    //         backgroundColor: getStatusColor(lead['status']!),
                    //         child: Text(
                    //           lead['initials']!,
                    //           style: GoogleFonts.poppins(
                    //             color: Colors.white,
                    //             fontSize: 13,
                    //             fontWeight: FontWeight.w500,
                    //           ),
                    //         ),
                    //       ),
                    //       title: Text(
                    //         lead['name']!,
                    //         style: GoogleFonts.poppins(
                    //           fontWeight: FontWeight.w600,
                    //           fontSize: 13,
                    //         ),
                    //       ),
                    //       subtitle: Column(
                    //         crossAxisAlignment: CrossAxisAlignment.start,
                    //         children: [
                    //           Text(lead['email']!,
                    //               style: GoogleFonts.poppins(fontSize: 12)),
                    //           Text(lead['phone']!,
                    //               style: GoogleFonts.poppins(fontSize: 12)),
                    //           Text(
                    //             'Client prefers email communication',
                    //             style: GoogleFonts.poppins(fontSize: 11),
                    //           ),
                    //         ],
                    //       ),
                    //       trailing: Column(
                    //         crossAxisAlignment: CrossAxisAlignment.end,
                    //         children: [
                    //           Text(lead['date']!,
                    //               style: GoogleFonts.poppins(fontSize: 12)),
                    //           const SizedBox(height: 6),
                    //           Container(
                    //             padding: const EdgeInsets.symmetric(
                    //                 horizontal: 8, vertical: 4),
                    //             decoration: BoxDecoration(
                    //               color:
                    //               getStatusColor(lead['status']!).withOpacity(0.1),
                    //               borderRadius: BorderRadius.circular(20),
                    //             ),
                    //             child: Text(
                    //               lead['status']!,
                    //               style: GoogleFonts.poppins(
                    //                 fontSize: 11,
                    //                 color: getStatusColor(lead['status']!),
                    //                 fontWeight: FontWeight.w500,
                    //               ),
                    //             ),
                    //           ),
                    //         ],
                    //       ),
                    //       isThreeLine: true,
                    //     );
                    //   },
                    // ),

                    // ListView.builder(
                    //   padding: const EdgeInsets.only(bottom: 80),
                    //   itemCount: today.length,
                    //   itemBuilder: (context, index) {
                    //     final lead = today[index];
                    //
                    //     final name = lead['name'] ?? 'No Name';
                    //     final phone = lead['phone'] ?? 'No Phone';
                    //     final company = lead['company_name'] ?? 'No Company';
                    //     final address = lead['address'] ?? 'No Address';
                    //     final enquiry = lead['enquiry'] ?? 'No Enquiry';
                    //     final type = lead['type'] ?? 'No Type';
                    //     final status = lead['status'] ?? 'Unknown';
                    //     final followUpDate = lead['follow_up'] ?? 'No Date';
                    //
                    //     final initials = name.trim().isNotEmpty
                    //         ? name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                    //         : 'NA';
                    //
                    //     return ListTile(
                    //       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    //       leading: CircleAvatar(
                    //         backgroundColor: getStatusColor(status),
                    //         child: Text(
                    //           initials,
                    //           style: GoogleFonts.poppins(
                    //             color: Colors.white,
                    //             fontWeight: FontWeight.w600,
                    //             fontSize: 13,
                    //           ),
                    //         ),
                    //       ),
                    //       title: Text(
                    //         name,
                    //         style: GoogleFonts.poppins(
                    //           fontSize: 14,
                    //           fontWeight: FontWeight.w600,
                    //         ),
                    //       ),
                    //       subtitle: Column(
                    //         crossAxisAlignment: CrossAxisAlignment.start,
                    //         children: [
                    //           Text("📞 $phone", style: GoogleFonts.poppins(fontSize: 12)),
                    //           Text("🏢 $company", style: GoogleFonts.poppins(fontSize: 12)),
                    //           Text("📍 $address", style: GoogleFonts.poppins(fontSize: 12)),
                    //           Text("💬 Enquiry: $enquiry", style: GoogleFonts.poppins(fontSize: 12)),
                    //           Text("📄 Type: $type", style: GoogleFonts.poppins(fontSize: 12)),
                    //         ],
                    //       ),
                    //       trailing: Column(
                    //         crossAxisAlignment: CrossAxisAlignment.end,
                    //         children: [
                    //           Text(
                    //             followUpDate,
                    //             style: GoogleFonts.poppins(fontSize: 11),
                    //           ),
                    //           const SizedBox(height: 6),
                    //           Container(
                    //             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    //             decoration: BoxDecoration(
                    //               color: getStatusColor(status).withOpacity(0.1),
                    //               borderRadius: BorderRadius.circular(20),
                    //             ),
                    //             child: Text(
                    //               status,
                    //               style: GoogleFonts.poppins(
                    //                 fontSize: 11,
                    //                 color: getStatusColor(status),
                    //                 fontWeight: FontWeight.w500,
                    //               ),
                    //             ),
                    //           ),
                    //         ],
                    //       ),
                    //       isThreeLine: true,
                    //     );
                    //   },
                    // ),


                    ListView(
                      padding: const EdgeInsets.only(bottom: 80),
                      children: [
                        if (today.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text("📅 This Week", style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                          ...today.map((lead) => _buildLeadTile(lead)).toList(),
                        ],
                        if (nextWeek.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text("📌 Next Week", style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                          ...nextWeek.map((lead) => _buildLeadTile(lead)).toList(),
                        ],
                        if (upcoming.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text("📈 Upcoming", style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                          ...upcoming.map((lead) => _buildLeadTile(lead)).toList(),
                        ],
                        if (today.isEmpty && nextWeek.isEmpty && upcoming.isEmpty)
                          const Center(child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text("No Leads Found"),
                          )),
                      ],
                    ),




                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child:ElevatedButton.icon(
                  onPressed: () {
                    _showCreateHostingPopup(context);
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text("Create Domain Renewal", style: GoogleFonts.poppins(fontSize: 14, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

              ),
            ],
          ),
        ),
      ),
    );
  }
}
