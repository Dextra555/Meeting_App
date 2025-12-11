



import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ClientFormScreen extends StatefulWidget {
  const ClientFormScreen({super.key});

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _enquiryController = TextEditingController();

  String? selectedType;
  String?    selectedStatus;




  // Future<void> _pickContact(BuildContext context, TextEditingController controller) async {
  //   PermissionStatus status = await Permission.contacts.request();
  //
  //   if (status.isPermanentlyDenied) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: const Text('Contacts permission permanently denied. Open settings to enable.'),
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
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('❌ Permission denied')),
  //     );
  //     return;
  //   }
  //
  //   // Open contact picker
  //   try {
  //     final contact = await FlutterContacts.openExternalPick();
  //     if (contact != null && contact.phones.isNotEmpty) {
  //       controller.text = contact.phones.first.number;
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('No phone number found')),
  //       );
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error: ${e.toString()}')),
  //     );
  //   }
  // }


  // Future<void> _pickContact(BuildContext context, TextEditingController controller) async {
  //   // Step 1: Request contact permission
  //   PermissionStatus status = await Permission.contacts.request();
  //
  //   if (status.isPermanentlyDenied) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: const Text('Contacts permission permanently denied. Open settings to enable.'),
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
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('❌ Permission denied')),
  //     );
  //     return;
  //   }
  //
  //   // Step 2: Open contact picker and fetch full contact details
  //   try {
  //     final pickedContact = await FlutterContacts.openExternalPick();
  //
  //     if (pickedContact != null) {
  //       final fullContact = await FlutterContacts.getContact(pickedContact.id);
  //
  //       if (fullContact != null && fullContact.phones.isNotEmpty) {
  //         final phoneNumber = fullContact.phones.first.number.trim();
  //         if (phoneNumber.isNotEmpty) {
  //           controller.text = phoneNumber;
  //         } else {
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             const SnackBar(content: Text('Selected contact has no valid phone number.')),
  //           );
  //         }
  //       } else {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('No phone number found in this contact.')),
  //         );
  //       }
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error while picking contact: ${e.toString()}')),
  //     );
  //   }
  // }
  // Future<void> _pickContact(BuildContext context, TextEditingController controller) async {
  //   final status = await Permission.contacts.request();
  //
  //   if (status.isPermanentlyDenied) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: const Text('Contacts permission permanently denied. Open settings to enable.'),
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
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('❌ Permission denied')),
  //     );
  //     return;
  //   }
  //
  //   try {
  //     final pickedContact = await FlutterContacts.openExternalPick();
  //
  //     if (pickedContact != null) {
  //       final fullContact = await FlutterContacts.getContact(pickedContact.id);
  //
  //       if (fullContact != null && fullContact.phones.isNotEmpty) {
  //         final phoneNumber = fullContact.phones.first.number.trim();
  //         if (phoneNumber.isNotEmpty) {
  //           controller.text = phoneNumber;
  //         } else {
  //           // No number: copy contact name or empty string
  //           await Clipboard.setData(ClipboardData(text: fullContact.displayName ?? ''));
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             const SnackBar(
  //               content: Text('No phone number found. Contact name copied to clipboard. Paste it manually.'),
  //             ),
  //           );
  //         }
  //       } else {
  //         // No phones at all
  //         await Clipboard.setData(ClipboardData(text: fullContact?.displayName ?? ''));
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('No phone number. Name copied to clipboard. Paste manually if needed.'),
  //           ),
  //         );
  //       }
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error while picking contact: ${e.toString()}')),
  //     );
  //   }
  // }

  // Future<void> _pickContact(BuildContext context, TextEditingController controller) async {
  //   final status = await Permission.contacts.request();
  //
  //   if (status.isPermanentlyDenied) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: const Text('Contacts permission permanently denied. Open settings to enable.'),
  //         action: SnackBarAction(
  //           label: 'Settings',
  //           onPressed: () => openAppSettings(),
  //         ),
  //       ),
  //     );
  //     return;
  //   }
  //
  //   if (!status.isGranted) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('❌ Contacts permission denied')),
  //     );
  //     return;
  //   }
  //
  //   try {
  //     final pickedContact = await FlutterContacts.openExternalPick();
  //
  //     if (pickedContact != null) {
  //       Contact? fullContact;
  //
  //       try {
  //         fullContact = await FlutterContacts.getContact(pickedContact.id);
  //       } catch (_) {
  //         fullContact = null;
  //       }
  //
  //       // ✅ First try direct contact retrieval
  //       if (fullContact != null && fullContact.phones.isNotEmpty) {
  //         final phone = fullContact.phones.first.number.trim();
  //         if (phone.isNotEmpty) {
  //           controller.text = phone;
  //           return;
  //         }
  //       }
  //
  //       // ✅ Fallback using displayName match
  //       final allContacts = await FlutterContacts.getContacts(withProperties: true);
  //       final match = allContacts.firstWhere(
  //             (c) => c.displayName == pickedContact.displayName && c.phones.isNotEmpty,
  //         orElse: () => Contact(),
  //       );
  //
  //       if (match.phones.isNotEmpty) {
  //         final fallbackPhone = match.phones.first.number.trim();
  //         if (fallbackPhone.isNotEmpty) {
  //           controller.text = fallbackPhone;
  //           return;
  //         }
  //       }
  //
  //       // ❌ No phone found
  //       await Clipboard.setData(ClipboardData(text: pickedContact.displayName ?? ''));
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('No phone number found. Name copied to clipboard. Paste manually if needed.'),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error while picking contact: $e')),
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
  Future<void> _fetchTodayFollowUps() async {
    final today = DateTime.now();
    final todayStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    try {
      final response = await http.get(Uri.parse("https://servernewapp.rentalsprime.in/api/enquiries"));
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

        });
      }
    } catch (e) {
      debugPrint("❌ Error fetching followups: $e");
    }
  }

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final url = Uri.parse("https://servernewapp.rentalsprime.in/api/enquiries");
    final body = {
      "name": _nameController.text.trim(),
      "company_name": _companyController.text.trim(),
      "phone": _phoneController.text.trim(),
      "address": _addressController.text.trim(),
      "enquiry": _enquiryController.text.trim(),
      "type": selectedType ?? '',
      "follow_up": _dateController.text.trim(),
      "status": selectedStatus ?? ''
    };

    print("📤 Submitting form with data: $body");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Client Follow-up added successfully",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );

        await _fetchTodayFollowUps();

        _formKey.currentState?.reset();
        _dateController.clear();
        _nameController.clear();
        _companyController.clear();
        _phoneController.clear();
        _addressController.clear();
        _enquiryController.clear();
        setState(() {
          selectedType = null;
          selectedStatus = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Something went wrong')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }




  // Future<void> submitForm() async {
  //   if (!_formKey.currentState!.validate()) return;
  //
  //   final url = Uri.parse("https://servernewapp.rentalsprime.in/api/enquiries");
  //   final body = {
  //     "name": _nameController.text.trim(),
  //     "company_name": _companyController.text.trim(),
  //     "phone": _phoneController.text.trim(),
  //     "address": _addressController.text.trim(),
  //     "enquiry": _enquiryController.text.trim(),
  //     "type": selectedType ?? '',
  //     "follow_up": _dateController.text.trim(),
  //     "status": selectedStatus ?? ''
  //   };
  //
  //   try {
  //     final response = await http.post(url,
  //       headers: {"Content-Type": "application/json"},
  //       body: json.encode(body),
  //     );
  //
  //     final data = json.decode(response.body);
  //     if (response.statusCode == 200 && data['status'] == true) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           duration: const Duration(seconds: 3),
  //           backgroundColor: Colors.green,
  //           behavior: SnackBarBehavior.floating,
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(12),
  //           ),
  //           content: Row(
  //             children: const [
  //               Icon(Icons.check_circle, color: Colors.white),
  //               SizedBox(width: 10),
  //               Expanded(
  //                 child: Text(
  //                   "Client Follow-up added successfully",
  //                   style: TextStyle(color: Colors.white),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //
  //       await _fetchTodayFollowUps();
  //
  //       _formKey.currentState?.reset();
  //       _dateController.clear();
  //       _nameController.clear();
  //       _companyController.clear();
  //       _phoneController.clear();
  //       _addressController.clear();
  //       _enquiryController.clear();
  //       setState(() {
  //         selectedType = null;
  //         selectedStatus = null;
  //       });
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text(data['message'] ?? 'Something went wrong')),
  //       );
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error: ${e.toString()}')),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  "Fill the form to add client",
                  style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField("Name", controller: _nameController, hintText: "Enter client name"),
                        _buildTextField("Company Name", controller: _companyController, hintText: "Enter company name"),
                        // _buildTextField("Phone Number", controller: _phoneController, keyboardType: TextInputType.phone, hintText: "Enter phone number"),

                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabelWithAsterisk("Phone Number"),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: _inputDecoration(
                                  hint: "Enter phone number",
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.contacts, color: Colors.blue),
                                    onPressed: () => _pickContact(context, _phoneController),
                                  ),
                                ),
                                validator: (value) =>
                                (value == null || value.isEmpty) ? 'Required' : null,
                              ),
                            ],
                          ),
                        ),


                        _buildTextField("Address", controller: _addressController, hintText: "Enter address"),
                        _buildTextField("Enquiry", controller: _enquiryController, hintText: "Enter enquiry details"),
                        const SizedBox(height: 10),
                        _buildLabelWithAsterisk("Type"),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          decoration: _inputDecoration(),
                          value: selectedType,
                          items: ["Website Development", "Mobile App Development", "SEO", "Odoo"]
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (val) => setState(() => selectedType = val),
                          validator: (val) => val == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 10),
                        _buildLabelWithAsterisk("Follow-up Date"),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _dateController,
                          readOnly: true,
                          decoration: _inputDecoration(hint: "Select a date"),
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                              initialDate: DateTime.now(),
                            );
                            if (picked != null) {
                              _dateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                            }
                          },
                          validator: (val) => val == null || val.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 10),
                        _buildLabelWithAsterisk("Status"),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          decoration: _inputDecoration(),
                          value: selectedStatus,
                          items: ["Pending", "In Progress", "Completed"]
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (val) => setState(() => selectedStatus = val),
                          validator: (val) => val == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  _formKey.currentState?.reset();
                                  _dateController.clear();
                                  _nameController.clear();
                                  _companyController.clear();
                                  _phoneController.clear();
                                  _addressController.clear();
                                  _enquiryController.clear();
                                  setState(() {
                                    selectedType = null;
                                    selectedStatus = null;
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                child: Text("Clear", style: GoogleFonts.notoSans(fontSize: 13)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                child: Text("Submit",
                                    style: GoogleFonts.notoSans(fontSize: 13, color: Colors.white)),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, {TextEditingController? controller, TextInputType? keyboardType, String? hintText}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabelWithAsterisk(label),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: _inputDecoration(hint: hintText ?? ''),
            validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildLabelWithAsterisk(String text) {
    return RichText(
      text: TextSpan(
        text: text,
        style: GoogleFonts.notoSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({String hint = ''}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.notoSans(color: Colors.grey, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.blue),
      ),
    );
  }
}
