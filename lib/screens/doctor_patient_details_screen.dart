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

    return DoctorNavScaffold(
      currentRoute: '/doctor-patients',
      title: 'Patient Medical Record',
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.accent(context)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back, color: AppTheme.accent(context)),
                        style: IconButton.styleFrom(backgroundColor: AppTheme.secondarySurface(context)),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Patient Medical File',
                        style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                          backgroundColor: AppTheme.accent(context),
                          child: Text(
                            patient['name']?[0] ?? 'P',
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                patient['name'] ?? 'Patient',
                                style: TextStyle(
                                  color: AppTheme.textPrimary(context),
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Patient ID: #${patient["id"]} • Email: ${patient["email"]}',
                                style: TextStyle(
                                  color: AppTheme.textSecondary(context),
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Role: ${patient["role"]} • Account Status: ${patient["status"]}',
                                style: TextStyle(
                                  color: AppTheme.textSecondary(context),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Medical History Card
                  Text(
                    'Medical History & Periodontal Notes',
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GlassCard(
                    borderRadius: 20,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _patientData?['medical_history'] ?? 'No prior dental surgeries. Routine plaque monitoring.',
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Scan History Timeline
                  Text(
                    'Previous Dental Scans & AI Diagnoses',
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (history.isEmpty) ...[
                    GlassCard(
                      borderRadius: 18,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'No patient reports available.',
                            style: TextStyle(
                              color: AppTheme.textPrimary(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    ...history.map((scan) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: GlassCard(
                            borderRadius: 16,
                            child: ListTile(
                              title: Text(
                                'Report #${scan["id"]} • Plaque: ${scan["plaque_percent"]}%',
                                style: TextStyle(
                                  color: AppTheme.textPrimary(context),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Severity: ${scan["severity"]} • Date: ${scan["timestamp"]}',
                                style: TextStyle(
                                  color: AppTheme.textSecondary(context),
                                  fontSize: 12,
                                ),
                              ),
                              trailing: ElevatedButton(
                                onPressed: () => Navigator.pushNamed(context, '/doctor-review', arguments: scan['id']),
                                child: const Text('Review', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        )),
                  ],
                ],
              ),
            ),
    );
  }
}
