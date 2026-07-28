import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../services/plaque_prediction.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';


class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with TickerProviderStateMixin {
  static const _stages = [
    'Detecting fluorescence regions...',
    'Analyzing plaque distribution...',
    'Generating oral diagnostic report...',
  ];

  late final AnimationController _rotationController;
  late final AnimationController _pulseController;
  int _stageIndex = 0;
  bool _started = false;
  XFile? _selectedImage;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    _selectedImage = ModalRoute.of(context)?.settings.arguments as XFile?;
    _runAnalysisSequence();
  }

  Future<void> _runAnalysisSequence() async {
    final image = _selectedImage;
    if (image == null) {
      Navigator.pop(context);
      return;
    }

    final predictionFuture = _apiService.predictPlaque(image);

    for (var i = 0; i < _stages.length; i++) {
      if (!mounted) {
        return;
      }
      setState(() => _stageIndex = i);
      await Future.delayed(const Duration(milliseconds: 1050));
    }
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) {
      return;
    }

    try {
      final prediction = await predictionFuture;
      if (!mounted) {
        return;
      }
      try {
        final reportData = {
          'imagePath': image.path,
          'processedImage': prediction.processedImage,
          'date': prediction.timestamp.toIso8601String(),
          'plaque': prediction.plaquePercent,
          'severity': prediction.severity,
          'score': prediction.oralHealthScore,
          'confidence': prediction.confidence,
          'recommendation': prediction.recommendation,
          'isDemo': false,
        };
        final existing = await SessionManager.getReportsForCurrentUser();
        await SessionManager.saveReportsForCurrentUser([
          jsonEncode(reportData),
          ...existing,
        ]);
      } catch (_) {}

      Navigator.pushReplacementNamed(
        context,
        '/result',
        arguments: AnalysisResultArguments(
          image: image,
          prediction: prediction,
        ),
      );
    } catch (error) {

      if (!mounted) {
        return;
      }
      final message = error.toString().replaceAll('ApiException: ', '').trim();
      
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFE53E3E)),
              SizedBox(width: 10),
              Text('Image Validation'),
            ],
          ),
          content: Text(
            message.isEmpty ? 'Please upload a clear image showing human teeth.' : message,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Retake Image', style: TextStyle(color: Color(0xFF2B7A78), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_stageIndex + 1) / _stages.length;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppTheme.pageDecoration(context),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final pulse = 0.18 + (_pulseController.value * 0.16);
                  return GlassCard(
                    borderRadius: 36,
                    opacity: 0.16,
                    borderOpacity: 0.26,
                    glowColor: const Color(0xFF2B7A78).withValues(alpha: pulse),
                    child: child!,
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              width: 150 + (_pulseController.value * 20),
                              height: 150 + (_pulseController.value * 20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(
                                      0xFF0EA5E9,
                                    ).withValues(alpha: 0.24),
                                    const Color(
                                      0xFF3B82F6,
                                    ).withValues(alpha: 0.06),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        RotationTransition(
                          turns: _rotationController,
                          child: SizedBox(
                            width: 116,
                            height: 116,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 9,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.12,
                              ),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF69C7C3),
                              ),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.memory,
                              color: Color(0xFF69C7C3),
                              size: 26,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(progress * 100).round()}%',
                              style: const TextStyle(
                                color: Color(0xFFF8FAFC),
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _stages[_stageIndex],
                        key: ValueKey(_stageIndex),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'PlaqueCheck AI is performing dental diagnostic analysis.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 12,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 26),
                    _StageTimeline(activeIndex: _stageIndex),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StageTimeline extends StatelessWidget {
  const _StageTimeline({required this.activeIndex});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        final isActive = index <= activeIndex;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            height: 5,
            margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: isActive
                  ? const LinearGradient(
                      colors: [Color(0xFF2B7A78), Color(0xFF3BA7A4)],
                    )
                  : null,
              color: isActive ? null : Colors.white.withValues(alpha: 0.12),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFF2B7A78).withValues(alpha: 0.24),
                        blurRadius: 14,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}
