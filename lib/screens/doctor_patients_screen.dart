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
  String _selectedFilter = 'all'; // 'all', 'high_risk'

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

        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DoctorNavScaffold(
      currentRoute: '/doctor-patients',
      title: 'Patient Directory Management',
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patient Directory Management',
              style: TextStyle(
                color: AppTheme.textPrimary(context),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Search, filter, and view patient clinical history and periodontal records.',
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),

            // Search Bar & Filter Chips
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _applyFilters(),
                    style: TextStyle(color: AppTheme.textPrimary(context)),
                    decoration: InputDecoration(
                      hintText: 'Search by Patient ID, Name, Email, or Phone...',
                      prefixIcon: Icon(Icons.search, color: AppTheme.accent(context)),
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
                  selectedColor: Colors.redAccent.withValues(alpha: 0.2),
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
                  ? Center(child: CircularProgressIndicator(color: AppTheme.accent(context)))
                  : _filteredPatients.isEmpty
                      ? GlassCard(
                          borderRadius: 20,
                          child: Center(
                            child: Text(
                              'No patient reports available.',
                              style: TextStyle(
                                color: AppTheme.textPrimary(context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                                    backgroundColor: AppTheme.accent(context),
                                    child: Text(
                                      p['name']?[0] ?? 'P',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(
                                    p['name'] ?? 'Patient',
                                    style: TextStyle(
                                      color: AppTheme.textPrimary(context),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Patient ID: #${p["id"]} • Email: ${p["email"]}',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary(context),
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.accent(context), size: 16),
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
    );
  }
}
