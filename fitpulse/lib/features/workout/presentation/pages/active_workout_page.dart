import 'package:flutter/material.dart';
import 'package:fitpulse/core/theme/app_theme.dart';
import 'package:fitpulse/data/local/daos/workout_dao.dart';
import 'package:fitpulse/data/models/workout_model.dart';
import '../widgets/exercise_selector_sheet.dart';

class ActiveWorkoutPage extends StatefulWidget {
  final String? workoutTitle;

  /// Şablondan başlatıldıysa programın id'si: hareketler buradan yüklenir ve
  /// kaydedilen oturum bu programa bağlanır.
  final int? programId;

  const ActiveWorkoutPage({
    super.key,
    this.workoutTitle,
    this.programId,
  });

  @override
  State<ActiveWorkoutPage> createState() => _ActiveWorkoutPageState();
}

class _ActiveWorkoutPageState extends State<ActiveWorkoutPage> {
  final WorkoutDao _workoutDao = WorkoutDao();

  // Hareket listesi: şablondan geliyorsa doldurulur, boş antrenmanda boş başlar.
  // Kodda gömülü örnek veri YOK; aksi halde kullanıcı dokunmadan Kaydet'e bassa
  // uydurma setler veritabanına girer ve kas haritasını kirletir.
  final List<WorkoutExerciseState> _currentExercises = [];
  bool _isLoadingTemplate = false;

  // Tarih ve süre değişkenleri
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _durationController =
      TextEditingController(text: '60');

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.programId != null) _loadTemplateExercises();
  }

  // Şablondaki hareketleri boş setlerle hazırlar
  Future<void> _loadTemplateExercises() async {
    setState(() => _isLoadingTemplate = true);
    final programExercises =
        await _workoutDao.getExercisesForProgram(widget.programId!);
    if (!mounted) return;

    setState(() {
      _currentExercises.addAll(programExercises.map((exercise) {
        // Şablon "4 set" diyorsa 4 boş satır açıyoruz
        final setCount = (int.tryParse(exercise.sets.trim()) ?? 1).clamp(1, 10);
        return WorkoutExerciseState(
          name: exercise.exerciseName,
          sets: List.generate(setCount, (_) => WorkoutSetState()),
        );
      }));
      _isLoadingTemplate = false;
    });
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _addNewExercise() async {
    final selectedExercise = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ExerciseSelectorSheet(),
    );

    if (selectedExercise != null) {
      setState(() {
        _currentExercises.add(WorkoutExerciseState(name: selectedExercise));
      });
    }
  }

  Future<void> _replaceExercise(int index) async {
    final selectedExercise = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ExerciseSelectorSheet(),
    );

    if (selectedExercise != null) {
      setState(() {
        _currentExercises[index].name = selectedExercise;
      });
    }
  }

  // Akıllı set ekleme: yeni set, bir önceki setin kilo/tekrar/RPE değerleriyle gelir
  void _addSet(WorkoutExerciseState exercise) {
    setState(() {
      exercise.sets.add(exercise.sets.isEmpty
          ? WorkoutSetState()
          : exercise.sets.last.copy());
    });
  }

  void _removeSet(WorkoutExerciseState exercise, int setIndex) {
    setState(() {
      exercise.sets.removeAt(setIndex);
    });
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.volt,
              onPrimary: Colors.black,
              surface: AppColors.surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // VERİTABANINA KAYIT
  Future<void> _saveWorkout() async {
    if (_isSaving) return;

    final duration = int.tryParse(_durationController.text.trim()) ?? 0;

    if (_currentExercises.isEmpty) {
      _showMessage('Kaydetmek için en az bir hareket ekle.');
      return;
    }
    if (duration <= 0) {
      _showMessage('Geçerli bir antrenman süresi gir.');
      return;
    }
    final hasValidSet =
        _currentExercises.any((exercise) => exercise.filledSets.isNotEmpty);
    if (!hasValidSet) {
      _showMessage('En az bir sete tekrar ya da süre girmelisin.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _workoutDao.saveWorkoutSession(
        date: _selectedDate,
        duration: duration,
        exercises: _currentExercises,
        programId: widget.programId, // şablondan geldiyse oturum ona bağlanır
      );

      if (!mounted) return;
      _showMessage('Antrenman kaydedildi.');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage('Kayıt sırasında bir hata oluştu: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.workoutTitle ?? 'Antrenmanı Kaydet',
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8, bottom: 8),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveWorkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.volt,
                foregroundColor: Colors.black,
                disabledBackgroundColor: AppColors.voltDark,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.black),
                    )
                  : const Text('Kaydet',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // TARİH VE SÜRE BİLGİSİ
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.stroke),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tarih',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_month,
                                color: AppColors.volt, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Container(width: 1, height: 40, color: AppColors.stroke),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Süre (Dk)',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.timer,
                              color: AppColors.volt, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _durationController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ŞABLON YÜKLENİYOR / BOŞ DURUM
          if (_isLoadingTemplate)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.volt)),
            )
          else if (_currentExercises.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.stroke, width: 1),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.fitness_center,
                        color: AppColors.textSecondary, size: 32),
                    SizedBox(height: 12),
                    Text(
                      'Henüz hareket yok',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Aşağıdan hareket ekleyerek antrenmanını oluştur.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.4),
                    ),
                  ],
                ),
              ),
            ),

          // HAREKET KARTLARI LİSTESİ
          ...List.generate(_currentExercises.length, (index) {
            final exercise = _currentExercises[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _ExerciseCard(
                key: ObjectKey(exercise),
                exercise: exercise,
                onReplace: () => _replaceExercise(index),
                onAddSet: () => _addSet(exercise),
                onRemoveSet: (setIndex) => _removeSet(exercise, setIndex),
              ),
            );
          }),
          const SizedBox(height: 8),

          // YENİ HAREKET EKLE BUTONU
          OutlinedButton.icon(
            onPressed: _addNewExercise,
            icon: const Icon(Icons.add, color: AppColors.volt),
            label: const Text(
              'YENİ HAREKET EKLE',
              style: TextStyle(
                  color: AppColors.volt,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.volt, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// ALT BİLEŞENLER
// ---------------------------------------------------------
class _ExerciseCard extends StatelessWidget {
  final WorkoutExerciseState exercise;
  final VoidCallback onReplace;
  final VoidCallback onAddSet;
  final ValueChanged<int> onRemoveSet;

  const _ExerciseCard({
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
