import 'package:flutter/material.dart';
import 'package:fitpulse/core/theme/app_theme.dart';
import 'widgets/circular_stopwatch.dart';
import '../widgets/exercise_selector_sheet.dart';

class ActiveWorkoutPage extends StatefulWidget {
  const ActiveWorkoutPage({super.key});

  @override
  State<ActiveWorkoutPage> createState() => _ActiveWorkoutPageState();
}

class _ActiveWorkoutPageState extends State<ActiveWorkoutPage> {
  // Canlı hareket listemiz (Başlangıçta boş veya şablon dolu olabilir)
  final List<String> _currentExercises = [
    'Bench Press (Barbell)',
    'Overhead Press (Barbell)'
  ];

  // Yeni hareket ekleme metodu
  Future<void> _addNewExercise() async {
    final selectedExercise = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ExerciseSelectorSheet(),
    );

    // Eğer kullanıcı bir hareket seçtiyse listeye ekle ve UI'ı güncelle
    if (selectedExercise != null) {
      setState(() {
        _currentExercises.add(selectedExercise);
      });
    }
  }

  // Var olan hareketi değiştirme metodu
  Future<void> _replaceExercise(int index) async {
    final selectedExercise = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ExerciseSelectorSheet(),
    );

    // Eğer kullanıcı bir hareket seçtiyse o sıradaki hareketi güncelle
    if (selectedExercise != null) {
      setState(() {
        _currentExercises[index] = selectedExercise;
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
        title: const Text(
          'Boş Antrenman',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8, bottom: 8),
            child: ElevatedButton(
              onPressed: () {
                // TODO: Veritabanına kaydet ve sayfayı kapat
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.volt,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: const Text(
                'Bitir',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 1. ÜST PANEL: Kronometre
          const WorkoutStopwatch(),
          const SizedBox(height: 32),

          // 2. HAREKET KARTLARI (Dinamik Liste)
          ...List.generate(_currentExercises.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _ExerciseCard(
                exerciseName: _currentExercises[index],
                onReplace: () => _replaceExercise(
                    index), // Değiştir butonuna metodu bağlıyoruz
              ),
            );
          }),

          const SizedBox(height: 8),

          // 3. YENİ HAREKET EKLE BUTONU
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

// Alt Bileşenler (Küçük bir onReplace parametresi ekledik)
class _ExerciseCard extends StatelessWidget {
  final String exerciseName;
  final VoidCallback onReplace;

  const _ExerciseCard({
    required this.exerciseName,
    required this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stroke, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  exerciseName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onReplace, // Tıklandığında üstteki metodu tetikler
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
                      borderRadius: BorderRadius.circular(10)),
                ),
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
                      child: Text('Kg / Süre',
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
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
              flex: 1,
              child: Text('$setIndex',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700))),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: _CompactInput(initialValue: weight)),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: _CompactInput(initialValue: reps)),
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
                    Text(difficulty,
                        style: const TextStyle(
                            color: AppColors.volt,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down,
                        color: AppColors.volt, size: 16),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _CompactInput extends StatelessWidget {
  final String initialValue;
  const _CompactInput({required this.initialValue});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: TextEditingController(text: initialValue),
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.background,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
