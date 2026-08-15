import 'package:flutter/material.dart';
import 'package:fitpulse/core/theme/app_theme.dart';
import 'package:fitpulse/data/models/workout_model.dart';

/// Antrenman kayıt ekranındaki tek hareketin kartı: set satırları,
/// kilo/tekrar alanları, RPE seçici ve set ekle/sil.
///
/// ActiveWorkoutPage'den ayrı tutuluyor; sayfa yalnızca listeyi ve kayıt
/// akışını yönetir, set girişinin tamamı bu dosyada yaşar.
class ExerciseCard extends StatelessWidget {
  final WorkoutExerciseState exercise;
  final VoidCallback onReplace;
  final VoidCallback onAddSet;
  final ValueChanged<int> onRemoveSet;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.onReplace,
    required this.onAddSet,
    required this.onRemoveSet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.stroke, width: 1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: Text(exercise.name,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                      overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onReplace,
                icon: const Icon(Icons.sync,
                    size: 16, color: AppColors.textSecondary),
                label: const Text('Değiştir',
                    style: TextStyle(color: AppColors.textSecondary)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.stroke),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                  flex: 1,
                  child: Text('Set',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13))),
              const Expanded(
                  flex: 2,
                  child: Center(
                      child: Text('Kg',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)))),
              Expanded(
                  flex: 2,
                  child: Center(
                      // Statik duruşlarda tekrar yerine süre giriliyor
                      child: Text(exercise.isStatic ? 'Saniye' : 'Tekrar',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)))),
              const Expanded(
                  flex: 2,
                  child: Center(
                      child: Text('Zorluk (RPE)',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)))),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(exercise.sets.length, (index) {
            final setState = exercise.sets[index];
            return _SetRow(
              key: ObjectKey(setState),
              setIndex: index + 1,
              setState: setState,
              isStatic: exercise.isStatic,
              // Tek set kaldıysa silme seçeneği sunmuyoruz
              onRemove:
                  exercise.sets.length > 1 ? () => onRemoveSet(index) : null,
            );
          }),
          const SizedBox(height: 16),
          GestureDetector(
              onTap: onAddSet,
              child: const Text('+ Set Ekle',
                  style: TextStyle(
                      color: AppColors.volt,
                      fontSize: 15,
                      fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _SetRow extends StatefulWidget {
  final int setIndex;
  final WorkoutSetState setState;
  final bool isStatic;
  final VoidCallback? onRemove;

  const _SetRow({
    super.key,
    required this.setIndex,
    required this.setState,
    required this.isStatic,
    this.onRemove,
  });

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late TextEditingController weightController;
  late TextEditingController repsController;

  @override
  void initState() {
    super.initState();
    weightController =
        TextEditingController(text: _formatWeight(widget.setState.weight));
    // Statik duruşta bu alan saniye tutuyor
    final value =
        widget.isStatic ? widget.setState.seconds : widget.setState.reps;
    repsController = TextEditingController(text: value > 0 ? '$value' : '');
  }

  // Hareket, dinamikten statiğe (ya da tersine) değiştirildiyse alanı tazele
  @override
  void didUpdateWidget(covariant _SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isStatic != widget.isStatic) {
      final value =
          widget.isStatic ? widget.setState.seconds : widget.setState.reps;
      repsController.text = value > 0 ? '$value' : '';
    }
  }

  @override
  void dispose() {
    weightController.dispose();
    repsController.dispose();
    super.dispose();
  }

  // 80.0 yerine 80, 82.5 ise 82.5 olarak göster
  String _formatWeight(double value) {
    if (value == 0) return '';
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  // RPE (Zorluk) seçim sayfası: 1-10 arası
  Future<void> _pickDifficulty() async {
    FocusScope.of(context).unfocus();

    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _DifficultyPickerSheet(
        currentValue: widget.setState.difficulty,
      ),
    );

    if (selected != null) {
      setState(() {
        widget.setState.difficulty = selected;
        widget.setState.difficultyTouched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTouched = widget.setState.difficultyTouched;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: widget.onRemove,
              child: Row(
                children: [
                  Text('${widget.setIndex}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  if (widget.onRemove != null) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.close,
                        size: 14, color: AppColors.textSecondary),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _CompactInput(
              controller: weightController,
              onChanged: (value) {
                widget.setState.weight =
                    double.tryParse(value.replaceAll(',', '.')) ?? 0;
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _CompactInput(
              controller: repsController,
              onChanged: (value) {
                final parsed = int.tryParse(value) ?? 0;
                if (widget.isStatic) {
                  widget.setState.seconds = parsed;
                } else {
                  widget.setState.reps = parsed;
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _pickDifficulty,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                    // Kullanıcı seçene kadar sönük duruyor ki varsayılan değerin
                    // gerçek bir seçim sanılmasın
                    color: isTouched
                        ? AppColors.volt.withValues(alpha: 0.12)
                        : Colors.transparent,
                    border: Border.all(
                        color: isTouched ? AppColors.volt : AppColors.stroke,
                        width: 1.5),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${widget.setState.difficulty}',
                        style: TextStyle(
                            color: isTouched
                                ? AppColors.volt
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down,
                        color:
                            isTouched ? AppColors.volt : AppColors.textSecondary,
                        size: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// RPE seçim paneli (1-10)
class _DifficultyPickerSheet extends StatelessWidget {
  final int currentValue;

  const _DifficultyPickerSheet({required this.currentValue});

  // RPE skalasının kısa karşılıkları
  static const Map<int, String> _labels = {
    1: 'Çok Kolay',
    2: 'Çok Kolay',
    3: 'Kolay',
    4: 'Kolay',
    5: 'Orta',
    6: 'Orta',
    7: '3 Tekrar Kaldı',
    8: '2 Tekrar Kaldı',
    9: '1 Tekrar Kaldı',
    10: 'Maksimum',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.stroke,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Zorluk (RPE)',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5),
              ),
            ),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sette tankta ne kadar yakıt kaldığını işaretle.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(10, (index) {
                final value = index + 1;
                final isActive = value == currentValue;
                return GestureDetector(
                  onTap: () => Navigator.pop(context, value),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.volt : AppColors.background,
                      border: Border.all(
                          color: isActive ? AppColors.volt : AppColors.stroke,
                          width: 1.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        '$value',
                        style: TextStyle(
                          color: isActive ? Colors.black : Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Şu an: $currentValue — ${_labels[currentValue] ?? ''}',
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _CompactInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const _CompactInput({required this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.background,
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none)),
      ),
    );
  }
}
