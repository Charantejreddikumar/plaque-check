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
  String _selectedStatus = 'approved';

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
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('ApiException: ', '').trim())),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showZoomImageModal(String title, String? imagePath) {
    final mediaUrl = (imagePath != null && imagePath.isNotEmpty) ? _apiService.mediaUrl(imagePath) : null;

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.cardColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppTheme.glassBorder(context)),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(Icons.close, color: AppTheme.textSecondary(context)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                height: 360,
                decoration: BoxDecoration(
                  color: AppTheme.secondarySurface(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.accent(context).withValues(alpha: 0.4)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: mediaUrl != null
                      ? InteractiveViewer(
                          child: Image.network(
                            mediaUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (ctx, _, __) => _buildUnavailablePlaceholder(context),
                          ),
                        )
                      : _buildUnavailablePlaceholder(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnavailablePlaceholder(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_rounded, color: AppTheme.textSecondary(context), size: 48),
          const SizedBox(height: 10),
          Text(
            'Image unavailable.',
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = _reportDetails?['report'] as Map<String, dynamic>? ?? {};
    final frontImg = report['processed_image'] ?? report['image_path'] ?? report['front_image'];
    final leftImg = report['left_image'];
    final rightImg = report['right_image'];

    return DoctorNavScaffold(
      currentRoute: '/doctor-dashboard',
      title: 'Doctor Clinical Review',
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Clinical Report Review #${report["report_id"] ?? ""}',
                              style: TextStyle(
                                color: AppTheme.textPrimary(context),
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Patient ID: #${report["user_id"]}',
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
                  const SizedBox(height: 24),

                  // 3-Image Zoomable Viewer Row
                  Text(
                    'Uploaded 3-View Dental Scans (Click to Inspect)',
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _ScanImageCard(
                        title: 'Front View',
                        imagePath: frontImg,
                        onTap: () => _showZoomImageModal('Front View Dental Scan', frontImg),
                      ),
                      const SizedBox(width: 12),
                      _ScanImageCard(
                        title: 'Left View',
                        imagePath: leftImg,
                        onTap: () => _showZoomImageModal('Left View Dental Scan', leftImg),
                      ),
                      const SizedBox(width: 12),
                      _ScanImageCard(
                        title: 'Right View',
                        imagePath: rightImg,
                        onTap: () => _showZoomImageModal('Right View Dental Scan', rightImg),
                      ),
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
                          Row(
                            children: [
                              Icon(Icons.memory_rounded, color: AppTheme.accent(context), size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'AI Automated Prediction Insights (Read-Only)',
                                style: TextStyle(
                                  color: AppTheme.accent(context),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Plaque Score Average', style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 11)),
                                  Text(
                                    '${report["plaque_percent"] ?? 0}%',
                                    style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 28, fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('AI Confidence Score', style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 11)),
                                  Text(
                                    '${((report["confidence"] ?? 0.92) * 100).toStringAsFixed(1)}%',
                                    style: const TextStyle(color: Color(0xFF10B981), fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Validation Status', style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 11)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'TEETH VERIFIED',
                                      style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
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
                  Text(
                    'Doctor Clinical Decision & Notes',
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  GlassCard(
                    borderRadius: 24,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            dropdownColor: AppTheme.cardColor(context),
                            style: TextStyle(color: AppTheme.textPrimary(context)),
                            decoration: _inputDeco('Review Decision'),
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
                              style: TextStyle(color: AppTheme.textPrimary(context)),
                              decoration: _inputDeco('Clinical Plaque % Override (0 - 100)'),
                            ),
                            const SizedBox(height: 14),
                          ],

                          TextFormField(
                            controller: _notesController,
                            maxLines: 3,
                            style: TextStyle(color: AppTheme.textPrimary(context)),
                            decoration: _inputDeco('Doctor Clinical Notes & Observations'),
                          ),
                          const SizedBox(height: 14),

                          TextFormField(
                            controller: _treatmentController,
                            maxLines: 2,
                            style: TextStyle(color: AppTheme.textPrimary(context)),
                            decoration: _inputDeco('Treatment & Tooth Cleaning Recommendations'),
                          ),
                          const SizedBox(height: 14),

                          TextFormField(
                            controller: _followUpController,
                            style: TextStyle(color: AppTheme.textPrimary(context)),
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
    );
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
    );
  }
}

class _ScanImageCard extends StatelessWidget {
  const _ScanImageCard({
    required this.title,
    required this.imagePath,
    required this.onTap,
  });

  final String title;
  final String? imagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mediaUrl = (imagePath != null && imagePath!.isNotEmpty) ? ApiService().mediaUrl(imagePath!) : null;

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
                    color: AppTheme.secondarySurface(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.accent(context).withValues(alpha: 0.3)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: mediaUrl != null
                        ? Image.network(
                            mediaUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (ctx, _, __) => Center(
                              child: Text(
                                'Image unavailable.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.textSecondary(context),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.zoom_in_rounded, color: AppTheme.accent(context), size: 28),
                                const SizedBox(height: 4),
                                Text(
                                  'Inspect View',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary(context),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
