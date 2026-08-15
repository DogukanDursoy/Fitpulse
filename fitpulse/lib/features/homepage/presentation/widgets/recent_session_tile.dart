import 'package:flutter/material.dart';
import 'package:fitpulse/core/theme/app_theme.dart';
import 'package:fitpulse/core/utils/turkish_date.dart';
import 'package:fitpulse/data/models/workout_model.dart';

/// Son antrenmanlar listesinin tek satırı.
class RecentSessionTile extends StatelessWidget {
  final WorkoutSession session;
  final VoidCallback onTap;

  const RecentSessionTile({
    super.key,
    required this.session,
    required this.onTap,
  });

  // Kardiyo seansları tonaj üretmiyor; "0 kg" yazmak yerine süreyi öne
  // çıkarıyoruz, yoksa koşu boş bir antrenman gibi görünürdü.
  String get _summary {
    final parts = <String>['${session.duration} dk'];
    if (session.totalVolume > 0) {
      parts.add('${_formatVolume(session.totalVolume)} kg');
    }
    if (session.rpeScore > 0) parts.add('RPE ${session.rpeScore}');
    return parts.join(' · ');
  }

  static String _formatVolume(double value) {
    final digits = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.stroke, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.fitness_center,
                  color: AppColors.volt, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatShortDate(DateTime.parse(session.date)),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _summary,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textSecondary, size: 22),
          ],
        ),
      ),
    );
  }
}
