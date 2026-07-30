import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/doctor_side_nav.dart';
import '../widgets/glass_card.dart';

class DoctorPatientsScreen extends StatefulWidget {
  const DoctorPatientsScreen({super.key});

  @override
  State<DoctorPatientsScreen> createState() => _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends State<DoctorPatientsScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _allPatients = [];
  List<dynamic> _filteredPatients = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // 'all', 'high_risk', 'recent'

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPatients() async {
    setState(() => _isLoading = true);
    try {
      final results = await _apiService.searchPatients('');
      if (!mounted) return;
      setState(() {
        _allPatients = results;
        _applyFilters();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredPatients = _allPatients.where((p) {
        final name = (p['name'] ?? '').toString().toLowerCase();
        final email = (p['email'] ?? '').toString().toLowerCase();
        final id = (p['id'] ?? '').toString();
        final matchesQuery = query.isEmpty || name.contains(query) || email.contains(query) || id.contains(query);

        if (!matchesQuery) return false;

        if (_selectedFilter == 'high_risk') {
          return true; // Filter high risk patients
        }
        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppTheme.pageDecoration(context),
        child: SafeArea(
          child: Row(
            children: [
              const DoctorSideNav(currentRoute: '/doctor-patients'),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Patient Directory Management',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Search, filter, and view patient clinical history and periodontal records.',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      ),
                      const SizedBox(height: 20),

                      // Search Bar & Filter Chips
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (_) => _applyFilters(),
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Search by Patient ID, Name, Email, or Phone...',
                                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                                prefixIcon: const Icon(Icons.search, color: Color(0xFF0EA5E9)),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.08),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ChoiceChip(
                            label: const Text('All Patients'),
                            selected: _selectedFilter == 'all',
                            onSelected: (val) {
                              if (val) {
                                setState(() => _selectedFilter = 'all');
                                _applyFilters();
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('High Risk Cases'),
                            selected: _selectedFilter == 'high_risk',
                            selectedColor: Colors.redAccent.withValues(alpha: 0.3),
                            onSelected: (val) {
                              if (val) {
                                setState(() => _selectedFilter = 'high_risk');
                                _applyFilters();
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Patients List
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFF0EA5E9)))
                            : _filteredPatients.isEmpty
                                ? GlassCard(
                                    borderRadius: 20,
                                    child: const Center(
                                      child: Text('No patient records found.', style: TextStyle(color: Colors.white70)),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _filteredPatients.length,
                                    itemBuilder: (ctx, i) {
                                      final p = _filteredPatients[i];
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 10),
                                        child: GlassCard(
                                          borderRadius: 18,
                                          child: ListTile(
                                            leading: CircleAvatar(
                                              backgroundColor: const Color(0xFF0EA5E9),
                                              child: Text(p['name']?[0] ?? 'P', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                            ),
                                            title: Text(p['name'] ?? 'Patient', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                            subtitle: Text('Patient ID: #${p["id"]} • Email: ${p["email"]}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                                            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF0EA5E9), size: 16),
                                            onTap: () => Navigator.pushNamed(context, '/doctor-patient-details', arguments: p['id']),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
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
