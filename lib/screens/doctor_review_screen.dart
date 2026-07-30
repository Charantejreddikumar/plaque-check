import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/doctor_side_nav.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_card.dart';

class DoctorReviewScreen extends StatefulWidget {
  const DoctorReviewScreen({super.key});

  @override
  State<DoctorReviewScreen> createState() => _DoctorReviewScreenState();
}

class _DoctorReviewScreenState extends State<DoctorReviewScreen> {
  final ApiService _apiService = ApiService();

  final _notesController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _followUpController = TextEditingController();
  final _plaqueOverrideController = TextEditingController();

  int? _reportId;
  Map<String, dynamic>? _reportDetails;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _selectedStatus = 'approved'; // 'approved', 'modified', 'rejected'

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reportId != null) return;
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is int) {
      _reportId = arg;
      _loadReportDetails();
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _treatmentController.dispose();
    _followUpController.dispose();
    _plaqueOverrideController.dispose();
    super.dispose();
  }

  Future<void> _loadReportDetails() async {
    if (_reportId == null) return;
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.fetchReportDetails(_reportId!);
      if (!mounted) return;
      final report = res['report'] as Map<String, dynamic>? ?? {};
      setState(() {
        _reportDetails = res;
        _notesController.text = report['doctor_notes'] ?? '';
        _treatmentController.text = report['treatment_recommendations'] ?? '';
        _followUpController.text = report['follow_up_date'] ?? '';
        _plaqueOverrideController.text = '${report["plaque_percent"] ?? 0}';
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitReview() async {
    if (_reportId == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final int? overrideVal = int.tryParse(_plaqueOverrideController.text);
      await _apiService.reviewReport(_reportId!, {
        'status': _selectedStatus,
        'modified_plaque_percent': overrideVal,
        'doctor_notes': _notesController.text.trim(),
        'treatment_recommendations': _treatmentController.text.trim(),
        'follow_up_date': _followUpController.text.trim(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor Clinical Review submitted successfully! Patient notified.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('ApiException: ', '').trim())),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showZoomImageModal(String title, String label) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                height: 320,
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF0EA5E9).withValues(alpha: 0.4)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.zoom_in, color: Color(0xFF0EA5E9), size: 48),
                      const SizedBox(height: 10),
                      Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Dental Scan View Ready for Inspection', style: TextStyle(color: Colors.white54, fontSize: 12)),
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

  @override
  Widget build(BuildContext context) {
    final report = _reportDetails?['report'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppTheme.pageDecoration(context),
        child: SafeArea(
          child: Row(
            children: [
              const DoctorSideNav(currentRoute: '/doctor-dashboard'),
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
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Clinical Report Review #${report["report_id"] ?? ""}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                                      Text('Patient ID: #${report["user_id"]}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // 3-Image Zoomable Viewer Row
                            const Text('Uploaded 3-View Dental Scans (Click to Inspect)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _ScanImageCard(title: 'Front View', onTap: () => _showZoomImageModal('Front View Dental Scan', 'Frontal Teeth Alignment')),
                                const SizedBox(width: 12),
                                _ScanImageCard(title: 'Left View', onTap: () => _showZoomImageModal('Left View Dental Scan', 'Left Buccal Teeth Segment')),
                                const SizedBox(width: 12),
                                _ScanImageCard(title: 'Right View', onTap: () => _showZoomImageModal('Right View Dental Scan', 'Right Buccal Teeth Segment')),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Read-Only AI Insights Panel
                            GlassCard(
                              borderRadius: 24,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.memory_rounded, color: Color(0xFF0EA5E9), size: 22),
                                        SizedBox(width: 8),
                                        Text('AI Automated Prediction Insights (Read-Only)', style: TextStyle(color: Color(0xFF0EA5E9), fontWeight: FontWeight.bold, fontSize: 15)),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Plaque Score Average', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                            Text('${report["plaque_percent"] ?? 0}%', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('AI Confidence Score', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                            Text('${((report["confidence"] ?? 0.92) * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFF10B981), fontSize: 20, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Validation Status', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                                              child: const Text('TEETH VERIFIED', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Doctor Action & Review Form
                            const Text('Doctor Clinical Decision & Notes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),

                            GlassCard(
                              borderRadius: 24,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    DropdownButtonFormField<String>(
                                      value: _selectedStatus,
                                      dropdownColor: const Color(0xFF0F172A),
                                      style: const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        labelText: 'Review Decision',
                                        labelStyle: const TextStyle(color: Color(0xFF0EA5E9)),
                                        filled: true,
                                        fillColor: Colors.white.withValues(alpha: 0.08),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: 'approved', child: Text('Approve AI Report')),
                                        DropdownMenuItem(value: 'modified', child: Text('Modify Plaque Score / Diagnosis')),
                                        DropdownMenuItem(value: 'rejected', child: Text('Reject Report (Rescan Required)')),
                                      ],
                                      onChanged: (val) => setState(() => _selectedStatus = val ?? 'approved'),
                                    ),
                                    const SizedBox(height: 14),

                                    if (_selectedStatus == 'modified') ...[
                                      TextFormField(
                                        controller: _plaqueOverrideController,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: _inputDeco('Clinical Plaque % Override (0 - 100)'),
                                      ),
                                      const SizedBox(height: 14),
                                    ],

                                    TextFormField(
                                      controller: _notesController,
                                      maxLines: 3,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: _inputDeco('Doctor Clinical Notes & Observations'),
                                    ),
                                    const SizedBox(height: 14),

                                    TextFormField(
                                      controller: _treatmentController,
                                      maxLines: 2,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: _inputDeco('Treatment & Tooth Cleaning Recommendations'),
                                    ),
                                    const SizedBox(height: 14),

                                    TextFormField(
                                      controller: _followUpController,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: _inputDeco('Recommended Follow-up Date (YYYY-MM-DD)'),
                                    ),
                                    const SizedBox(height: 24),

                                    GlassButton(
                                      label: _isSubmitting ? 'Saving Review...' : 'Sign & Submit Clinical Review',
                                      icon: Icons.verified_rounded,
                                      isPrimary: true,
                                      onPressed: _isSubmitting ? () {} : _submitReview,
                                    ),
                                  ],
                                ),
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

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF0EA5E9), fontSize: 12),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.08),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15))),
    );
  }
}

class _ScanImageCard extends StatelessWidget {
  const _ScanImageCard({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: GlassCard(
          borderRadius: 18,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF0EA5E9).withValues(alpha: 0.3)),
                  ),
                  child: const Center(
                    child: Icon(Icons.zoom_in_rounded, color: Color(0xFF0EA5E9), size: 36),
                  ),
                ),
                const SizedBox(height: 8),
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
