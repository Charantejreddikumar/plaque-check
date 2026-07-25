import 'package:flutter/material.dart';

class GradientScoreCard extends StatelessWidget {
  const GradientScoreCard({
    super.key,
    required this.title,
    required this.score,
    required this.label,
    this.progress,
    this.icon = Icons.health_and_safety_outlined,
  });

  final String title;
  final String score;
  final String label;
  final double? progress;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF69C7C3).withValues(alpha: 0.96),
            const Color(0xFF3BA7A4).withValues(alpha: 0.96),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2B7A78).withValues(alpha: 0.26),
            blurRadius: 42,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: const Color(0xFF3BA7A4).withValues(alpha: 0.12),
            blurRadius: 34,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 86,
                    height: 86,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.16),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white, size: 22),
                      Text(
                        score,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
