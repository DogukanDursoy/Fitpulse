import 'package:flutter/material.dart';
import 'package:fitpulse/core/theme/app_theme.dart';

// Hareket verilerini tutacak basit model
class _ExerciseItem {
  final String name;
  final String category;

  const _ExerciseItem(this.name, this.category);
}

class ExerciseSelectorSheet extends StatefulWidget {
  const ExerciseSelectorSheet({super.key});

  @override
  State<ExerciseSelectorSheet> createState() => _ExerciseSelectorSheetState();
}

class _ExerciseSelectorSheetState extends State<ExerciseSelectorSheet> {
  String _searchQuery = '';
  String _selectedCategory = 'Tümü';

  // Filtre kategorileri
  final List<String> _categories = [
    'Tümü',
    'Göğüs',
    'Sırt',
    'Bacak',
    'Omuz',
    'Core'
  ];

  // Powerlifting ve Calisthenics harmanı elit hareket listesi
  final List<_ExerciseItem> _allExercises = [
    const _ExerciseItem('Bench Press', 'Göğüs'),
    const _ExerciseItem('Incline Dumbbell Press', 'Göğüs'),
    const _ExerciseItem('Weighted Dips', 'Göğüs'),
    const _ExerciseItem('Deadlift', 'Sırt'),
    const _ExerciseItem('Barbell Row', 'Sırt'),
    const _ExerciseItem('Pull-Up (Ağırlıklı)', 'Sırt'),
    const _ExerciseItem('Front Lever', 'Sırt'),
    const _ExerciseItem('Muscle-Up', 'Sırt'),
    const _ExerciseItem('Squat', 'Bacak'),
    const _ExerciseItem('Bulgarian Split Squat', 'Bacak'),
    const _ExerciseItem('Leg Press', 'Bacak'),
    const _ExerciseItem('Overhead Press', 'Omuz'),
    const _ExerciseItem('Lateral Raise', 'Omuz'),
    const _ExerciseItem('Handstand Push-Up', 'Omuz'),
    const _ExerciseItem('L-Sit', 'Core'),
    const _ExerciseItem('Hanging Leg Raise', 'Core'),
    const _ExerciseItem('Dragon Flag', 'Core'),
  ];

  @override
  Widget build(BuildContext context) {
    // 1. Önce kategoriye göre süz
    var filteredList = _selectedCategory == 'Tümü'
        ? _allExercises
        : _allExercises.where((e) => e.category == _selectedCategory).toList();

    // 2. Sonra arama metnine göre süz
    if (_searchQuery.isNotEmpty) {
      filteredList = filteredList
          .where(
              (e) => e.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return Container(
      height:
          MediaQuery.of(context).size.height * 0.85, // Ekranın %85'ini kaplar
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Çentik (Tutma yeri) ve Başlık
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.stroke,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Hareket Seç',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),

          // Arama Çubuğu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Hareket ara...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Kategori Filtreleri (Yatay Kaydırılabilir)
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isActive = category == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.volt : Colors.transparent,
                      border: Border.all(
                          color: isActive ? AppColors.volt : AppColors.stroke),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: TextStyle(
                          color:
                              isActive ? Colors.black : AppColors.textPrimary,
                          fontWeight:
                              isActive ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.stroke, height: 1),

          // Hareket Listesi
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final exercise = filteredList[index];
                return InkWell(
                  onTap: () {
                    // Seçilen hareketi geri döndürerek sayfayı kapat
                    Navigator.pop(context, exercise.name);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 12),
                    decoration: const BoxDecoration(
                      border:
                          Border(bottom: BorderSide(color: AppColors.stroke)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          exercise.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            exercise.category,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
