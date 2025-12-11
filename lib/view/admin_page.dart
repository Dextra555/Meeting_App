import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../Models/Model.dart';

class AdminPage extends StatefulWidget {
  final List<Employee> employees;
  final List<Team> teams;
  final Function(Employee) onAddEmployee;
  final Function(Team) onAddTeam;
  final String currentUserId;
  final String currentUserName;

  const AdminPage({
    super.key,
    required this.employees,
    required this.teams,
    required this.onAddEmployee,
    required this.onAddTeam,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final TextEditingController addNameCtrl = TextEditingController();
  final TextEditingController addEmailCtrl = TextEditingController();
  final TextEditingController addRoleCtrl = TextEditingController();
  String? selectedTeam;

  final TextEditingController _teamNameCtrl = TextEditingController();
  final TextEditingController _teamDescCtrl = TextEditingController();
  bool isAddingMember = false;
  bool isAddingTeam = false;

  @override
  void dispose() {
    addNameCtrl.dispose();
    addEmailCtrl.dispose();
    addRoleCtrl.dispose();
    _teamNameCtrl.dispose();
    _teamDescCtrl.dispose();
    super.dispose();
  }

  Future<void> _addMember() async {
    final name = addNameCtrl.text.trim();
    final email = addEmailCtrl.text.trim();
    final role = addRoleCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || role.isEmpty || selectedTeam == null) {
      _showSnack('Enter all fields and select a team');
      return;
    }

    setState(() => isAddingMember = true);

    final url = Uri.parse(
        'https://servernewapp.rentalsprime.in/api/teams/$selectedTeam/members');
    final body = jsonEncode({"name": name, "email": email, "role": role});

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['status'] == 'success') {
        final memberData = data['member'];
        final newEmp = Employee(
          id: memberData['id'].toString(),
          name: memberData['name'],
          category: memberData['role'],
          teamId: memberData['team_id'].toString(),
        );
        widget.onAddEmployee(newEmp);

        addNameCtrl.clear();
        addEmailCtrl.clear();
        addRoleCtrl.clear();

        _showSnack('Member "${memberData['name']}" added successfully');
      } else {
        _showSnack('Failed to add member: ${data['message']}');
      }
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      setState(() => isAddingMember = false);
    }
  }

  Future<void> _addTeam() async {
    final name = _teamNameCtrl.text.trim();
    final desc = _teamDescCtrl.text.trim();
    if (name.isEmpty || desc.isEmpty) {
      _showSnack('Enter team name and description');
      return;
    }

    setState(() => isAddingTeam = true);

    final url = Uri.parse('https://servernewapp.rentalsprime.in/api/teams');
    final body = jsonEncode({"name": name, "description": desc});

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['status'] == 'success') {
        final teamData = data['team'];
        final newTeam = Team(
          id: teamData['id'].toString(),
          name: teamData['name'],
          description: teamData['description'] ?? '',
        );
        widget.onAddTeam(newTeam);

        _teamNameCtrl.clear();
        _teamDescCtrl.clear();

        _showSnack('Team "${teamData['name']}" added successfully');
      } else {
        _showSnack('Failed to add team: ${data['message']}');
      }
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      setState(() => isAddingTeam = false);
    }
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: GoogleFonts.poppins()),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.indigoAccent.withOpacity(0.3),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.indigo[800],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.indigo[600]),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _gradientButton({required String text, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Colors.indigo, Colors.indigoAccent],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Admin Panel', style: GoogleFonts.poppins()),
        backgroundColor: Colors.indigo,
        centerTitle: true,
        elevation: 3,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader('Add Member'),
            _buildCard(
              child: Column(
                children: [
                  TextField(controller: addNameCtrl, decoration: _inputDecoration('Name')),
                  const SizedBox(height: 12),
                  TextField(controller: addEmailCtrl, decoration: _inputDecoration('Email')),
                  const SizedBox(height: 12),
                  TextField(controller: addRoleCtrl, decoration: _inputDecoration('Role')),
                  const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedTeam,
                menuMaxHeight: 300,
                alignment: AlignmentDirectional.bottomStart,
                decoration: InputDecoration(
                  labelText: "Select Team",
                  labelStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.indigo, width: 1.5),
                  ),
                ),
                icon: const Icon(
                  Icons.arrow_drop_down_circle_rounded,
                  color: Colors.indigo,
                ),
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(14),
                items: widget.teams.map((team) {
                  return DropdownMenuItem(
                    value: team.id,
                    child: Text(
                      team.name,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => selectedTeam = value),
              ),
                  const SizedBox(height: 20),
                  isAddingMember
                      ? const Center(child: CircularProgressIndicator())
                      : _gradientButton(text: 'Add Member', onTap: _addMember),
                ],
              ),
            ),
            _buildHeader('Add Team'),
            _buildCard(
              child: Column(
                children: [
                  TextField(controller: _teamNameCtrl, decoration: _inputDecoration('Team Name')),
                  const SizedBox(height: 12),
                  TextField(controller: _teamDescCtrl, decoration: _inputDecoration('Team Description')),
                  const SizedBox(height: 20),
                  isAddingTeam
                      ? const Center(child: CircularProgressIndicator())
                      : _gradientButton(text: 'Add Team', onTap: _addTeam),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
