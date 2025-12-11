import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class DomainPage extends StatefulWidget {
  const DomainPage({super.key});

  @override
  State<DomainPage> createState() => _DomainPageState();
}

class _DomainPageState extends State<DomainPage> {
  List<Map<String, dynamic>> _allDomains = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHostingData();
  }

  Future<void> _fetchHostingData() async {
    final url =
    Uri.parse("https://servernewapp.rentalsprime.in/api/hosting");

    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        final List rawList = data['data'];

        setState(() {
          _allDomains = rawList.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch hosting data');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error will be: $e")),
      );
    }
  }
  Map<String, List<Map<String, dynamic>>> _groupByMonth() {
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var domain in _allDomains) {
      final dateStr = domain['hosting_date'];
      final date = DateTime.tryParse(dateStr ?? '');

      if (date != null) {
        final key = DateFormat("MMMM yyyy").format(date);
        grouped.putIfAbsent(key, () => []);
        grouped[key]!.add(domain);
      }
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedDomains = _groupByMonth();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Domain",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allDomains.isEmpty
          ? const Center(child: Text("No hosting data available."))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: groupedDomains.entries.map((entry) {
          final month = entry.key;
          final domains = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("📅 $month"),
              ...domains.map(_buildCard).toList(),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.indigo,
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> domain) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 5,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        domain['company_name'] ?? 'N/A',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "Exp: ${domain['expiring_date'] ?? '--'}",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.red.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                _buildDetail("📡 Hosting", domain['hosting_name']),
                _buildDetail("✉️ Email", domain['email']),
                _buildDetail("📞 Phone", domain['phone_no']),
                _buildDetail("🗓️ Hosting Date", domain['hosting_date']),
                _buildDetail("🔁 Last Renewal", domain['last_renewal_date']),
                _buildDetail("👤 Hosted By", domain['hosted_by']),
                _buildDetail("💰 Amount", "₹${domain['amount']}"),
                _buildDetail("📝 Remarks", domain['remarks']),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetail(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              "$label:",
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value?.toString() ?? "--",
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
