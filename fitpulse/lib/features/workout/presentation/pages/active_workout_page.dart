import 'package:flutter/material.dart';
import 'package:fitpulse/core/theme/app_theme.dart';
import '../widgets/exercise_selector_sheet.dart';

class ActiveWorkoutPage extends StatefulWidget {
  final String? workoutTitle;

  const ActiveWorkoutPage({
    super.key,
    this.workoutTitle,
  });

  @override
  State<ActiveWorkoutPage> createState() => _ActiveWorkoutPageState();
}

class _ActiveWorkoutPageState extends State<ActiveWorkoutPage> {
  // Hareket listemiz (Boş antrenmansa başlagıçta boş olabilir)
  final List<String> _currentExercises = [
    'Bench Press (Barbell)',
    'Overhead Press (Barbell)'
  ];

  // Tarih ve süre değişkenleri
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _durationController =
      TextEditingController(text: '60');

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
        _currentExercises.add(selectedExercise);
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
        _currentExercises[index] = selectedExercise;
      });
    }
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
              onPressed: () {
                // TODO: Veritabanına kaydet
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.volt,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: const Text('Kaydet',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
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

          // HAREKET KARTLARI LİSTESİ
          ...List.generate(_currentExercises.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _ExerciseCard(
                exerciseName: _currentExercises[index],
                onReplace: () => _replaceExercise(index),
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
  final String exerciseName;
  final VoidCallback onReplace;

  const _ExerciseCard({required this.exerciseName, required this.onReplace});

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
                  child: Text(exerciseName,
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
          const Row(
            children: [
              Expanded(
                  flex: 1,
                  child: Text('Set',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13))),
              Expanded(
                  flex: 2,
                  child: Center(
                      child: Text('Kg',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)))),
              Expanded(
                  flex: 2,
                  child: Center(
                      child: Text('Tekrar',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)))),
              Expanded(
                  flex: 2,
                  child: Center(
                      child: Text('Zorluk',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)))),
            ],
          ),
          const SizedBox(height: 12),
          const _SetRow(setIndex: 1, weight: '80', reps: '10', difficulty: '9'),
          const SizedBox(height: 16),
          GestureDetector(
              onTap: () {},
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
  final String weight;
  final String reps;
  final String difficulty;

  const _SetRow(
      {required this.setIndex,
      required this.weight,
      required this.reps,
      required this.difficulty});

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late TextEditingController weightController;
  late TextEditingController repsController;

  @override
  void initState() {
    super.initState();
    weightController = TextEditingController(text: widget.weight);
    repsController = TextEditingController(text: widget.reps);
  }

  @override
  void dispose() {
    weightController.dispose();
    repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
              flex: 1,
              child: Text('${widget.setIndex}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700))),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: _CompactInput(controller: weightController)),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: _CompactInput(controller: repsController)),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                  border: Border.all(color: AppColors.volt, width: 1.5),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.difficulty,
                      style: const TextStyle(
                          color: AppColors.volt,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down,
                      color: AppColors.volt, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactInput extends StatelessWidget {
  final TextEditingController controller;
  const _CompactInput({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
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
