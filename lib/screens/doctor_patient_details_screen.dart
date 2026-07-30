import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/doctor_side_nav.dart';
import '../widgets/glass_card.dart';

class DoctorPatientDetailsScreen extends StatefulWidget {
  const DoctorPatientDetailsScreen({super.key});

  @override
  State<DoctorPatientDetailsScreen> createState() => _DoctorPatientDetailsScreenState();
}

class _DoctorPatientDetailsScreenState extends State<DoctorPatientDetailsScreen> {
  final ApiService _apiService = ApiService();

  int? _patientId;
  Map<String, dynamic>? _patientData;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_patientId != null) return;
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is int) {
      _patientId = arg;
      _loadDetails();
    }
  }

  Future<void> _loadDetails() async {
    if (_patientId == null) return;
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.fetchPatientDetail(_patientId!);
      if (!mounted) return;
      setState(() {
        _patientData = res;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = _patientData?['patient'] as Map<String, dynamic>? ?? {};
    final history = (_patientData?['scan_history'] as List?) ?? [];

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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF0EA5E9)))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.arrow_back, color: Color(0xFF0EA5E9)),
                                  style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.12)),
                                ),
                                const SizedBox(width: 12),
                                const Text('Patient Medical File', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Patient Header Card
                            GlassCard(
                              borderRadius: 24,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 36,
                                    backgroundColor: const Color(0xFF0EA5E9),
                                    child: Text(patient['name']?[0] ?? 'P', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(patient['name'] ?? 'Patient', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text('Patient ID: #${patient["id"]} • Email: ${patient["email"]}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                                        Text('Role: ${patient["role"]} • Account Status: ${patient["status"]}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Medical History Card
                            const Text('Medical History & Periodontal Notes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            GlassCard(
                              borderRadius: 20,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  _patientData?['medical_history'] ?? 'No prior dental surgeries. Routine plaque monitoring.',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Scan History Timeline
                            const Text('Previous Dental Scans & AI Diagnoses', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),

                            if (history.isEmpty) ...[
                              GlassCard(
                                borderRadius: 18,
                                child: const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No scan reports recorded yet.', style: TextStyle(color: Colors.white70)))),
                              ),
                            ] else ...[
                              ...history.map((scan) => Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: GlassCard(
                                      borderRadius: 16,
                                      child: ListTile(
                                        title: Text('Report #${scan["id"]} • Plaque: ${scan["plaque_percent"]}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        subtitle: Text('Severity: ${scan["severity"]} • Date: ${scan["timestamp"]}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                                        trailing: ElevatedButton(
                                          onPressed: () => Navigator.pushNamed(context, '/doctor-review', arguments: scan['id']),
                                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0EA5E9)),
                                          child: const Text('Review', style: TextStyle(color: Colors.white)),
                                        ),
                                      ),
                                    ),
                                  )),
                            ],
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
