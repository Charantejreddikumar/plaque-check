import 'dart:async';
import 'dart:convert';
import 'dart:math';

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
    'Isolating dental structures from soft tissue...',
    'Analyzing multi-angle plaque distribution...',
    'Generating comprehensive oral report...',
  ];

  late final AnimationController _rotationController;
  late final AnimationController _pulseController;
  int _stageIndex = 0;
  bool _started = false;

  Map<String, XFile> _imagesMap = {};
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
    final rawArg = ModalRoute.of(context)?.settings.arguments;
    if (rawArg is Map<String, XFile>) {
      _imagesMap = rawArg;
    } else if (rawArg is XFile) {
      _imagesMap['Front View'] = rawArg;
    }
    _runAnalysisSequence();
  }

  Future<void> _runAnalysisSequence() async {
    if (_imagesMap.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final imageList = _imagesMap.values.toList();
    final Future<PlaquePrediction> batchFuture = _apiService.predictPlaqueBatch(imageList);

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
      final combinedPrediction = await batchFuture;
      final primaryImage = imageList.first;

      try {
        final reportData = {
          'imagePath': primaryImage.path,
          'processedImage': combinedPrediction.processedImage,
          'date': combinedPrediction.timestamp.toIso8601String(),
          'plaque': combinedPrediction.plaquePercent,
          'severity': combinedPrediction.severity,
          'score': combinedPrediction.oralHealthScore,
          'confidence': combinedPrediction.confidence,
          'recommendation': combinedPrediction.recommendation,
          'isDemo': false,
        };
        final existing = await SessionManager.getReportsForCurrentUser();
        await SessionManager.saveReportsForCurrentUser([
          jsonEncode(reportData),
          ...existing,
        ]);
      } catch (_) {}

      if (!mounted) {
        return;
      }

      Navigator.pushReplacementNamed(
        context,
        '/result',
        arguments: AnalysisResultArguments(
          image: primaryImage,
          prediction: combinedPrediction,
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
              Text('Dental Image Check'),
            ],
          ),
          content: Text(
            message.isEmpty ? 'Please upload a clear close-up image showing human teeth.' : message,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Retake Scan', style: TextStyle(color: Color(0xFF2B7A78), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
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
    final stageText = _stages[min(_stageIndex, _stages.length - 1)];

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppTheme.pageDecoration(context),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              children: [
                const Spacer(),
                ScaleTransition(
                  scale: Tween(begin: 0.95, end: 1.05).animate(_pulseController),
                  child: RotationTransition(
                    turns: _rotationController,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const SweepGradient(
                          colors: [
                            Color(0xFF2B7A78),
                            Color(0xFF3AAFA9),
                            Color(0xFFDEF2F1),
                            Color(0xFF2B7A78),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3AAFA9).withValues(alpha: 0.35),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.secondarySurface(context),
                          ),
                          child: const Icon(
                            Icons.biotech_outlined,
                            size: 56,
                            color: Color(0xFF3AAFA9),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                Text(
                  'Multi-Angle AI Scanning',
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  stageText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const Spacer(),
                GlassCard(
                  borderRadius: 18,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3AAFA9)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'Processing ${_imagesMap.length} Angle Slot${_imagesMap.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            color: AppTheme.textPrimary(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
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
      ),
    );
  }
}
