import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  static const _storeReportsKey = 'privacy_store_reports_locally';
  static const _analyticsKey = 'privacy_allow_analytics';

  PermissionStatus? _cameraStatus;
  PermissionStatus? _galleryStatus;
  PermissionStatus? _notificationStatus;
  bool _storeReportsLocally = true;
  bool _allowAnalytics = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final statuses = await Future.wait([
      Permission.camera.status,
      Permission.photos.status,
      Permission.notification.status,
    ]);
    if (!mounted) {
      return;
    }
    setState(() {
      _cameraStatus = statuses[0];
      _galleryStatus = statuses[1];
      _notificationStatus = statuses[2];
      _storeReportsLocally = prefs.getBool(_storeReportsKey) ?? true;
      _allowAnalytics = prefs.getBool(_analyticsKey) ?? false;
    });
  }

  Future<void> _requestPermission(_PermissionKind kind) async {
    final permission = switch (kind) {
      _PermissionKind.camera => Permission.camera,
      _PermissionKind.gallery => Permission.photos,
      _PermissionKind.notification => Permission.notification,
    };
    final status = await permission.request();
    if (!mounted) {
      return;
    }
    setState(() {
      switch (kind) {
        case _PermissionKind.camera:
          _cameraStatus = status;
        case _PermissionKind.gallery:
          _galleryStatus = status;
        case _PermissionKind.notification:
          _notificationStatus = status;
      }
    });
  }

  Future<void> _saveToggle(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsPage(
      title: 'Privacy Preferences',
      subtitle:
          'Control local privacy settings for the AI-powered plaque detection assistant.',
      children: [
        _PermissionCard(
          icon: Icons.photo_camera_outlined,
          title: 'Camera Permission',
          detail: 'Enable camera access for fresh plaque scans.',
          status: _cameraStatus,
          onRequest: () => _requestPermission(_PermissionKind.camera),
        ),
        const SizedBox(height: 14),
        _PermissionCard(
          icon: Icons.photo_library_outlined,
          title: 'Gallery Permission',
          detail: 'Enable photo upload access for scan images.',
          status: _galleryStatus,
          onRequest: () => _requestPermission(_PermissionKind.gallery),
        ),
        const SizedBox(height: 14),
        _PermissionCard(
          icon: Icons.notifications_outlined,
          title: 'Notification Permission',
          detail: 'Enable notifications for scan reminders.',
          status: _notificationStatus,
          onRequest: () => _requestPermission(_PermissionKind.notification),
        ),
        const SizedBox(height: 14),
        GlassCard(
          borderRadius: 26,
          child: Column(
            children: [
              _PrivacySwitch(
                icon: Icons.storage_outlined,
                title: 'Store reports locally',
                detail: 'Keep saved diagnostic reports on this device.',
                value: _storeReportsLocally,
                onChanged: (value) {
                  setState(() => _storeReportsLocally = value);
                  _saveToggle(_storeReportsKey, value);
                },
              ),
              const Divider(color: Colors.white24),
              _PrivacySwitch(
                icon: Icons.analytics_outlined,
                title: 'Allow analytics placeholder',
                detail:
                    'Prepare anonymous product analytics for backend setup.',
                value: _allowAnalytics,
                onChanged: (value) {
                  setState(() => _allowAnalytics = value);
                  _saveToggle(_analyticsKey, value);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          onTap: () => Navigator.pushNamed(context, '/complaint'),
          borderRadius: 26,
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(
                Icons.report_problem_outlined,
                color: AppTheme.accent(context),
                size: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report Issue / Complaint',
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Submit concerns about reports, privacy, or scan behavior.',
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppTheme.textSecondary(context)),
            ],
          ),
        ),
      ],
    );
  }
}

enum _PermissionKind { camera, gallery, notification }

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.detail,
    required this.status,
    required this.onRequest,
  });

  final IconData icon;
  final String title;
  final String detail;
  final PermissionStatus? status;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final granted = status?.isGranted ?? false;
    final denied = status?.isDenied ?? false;
    final label = granted
        ? 'Permission granted'
        : denied
        ? 'Permission denied'
        : 'Request permission';
    final color = granted
        ? const Color(0xFF10B981)
        : denied
        ? const Color(0xFFF59E0B)
        : AppTheme.accent(context);

    return GlassCard(
      borderRadius: 26,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.accent(context), size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  detail,
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: granted ? null : onRequest,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: color.withValues(alpha: 0.24)),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: granted,
            activeThumbColor: AppTheme.accent(context),
            onChanged: granted ? null : (_) => onRequest(),
          ),
        ],
      ),
    );
  }
}

class _PrivacySwitch extends StatelessWidget {
  const _PrivacySwitch({
    required this.icon,
    required this.title,
    required this.detail,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppTheme.accent(context),
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon, color: AppTheme.accent(context)),
      title: Text(
        title,
        style: TextStyle(
          color: AppTheme.textPrimary(context),
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        detail,
        style: TextStyle(
          color: AppTheme.textSecondary(context),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppTheme.pageDecoration(context),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF2B7A78)),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
