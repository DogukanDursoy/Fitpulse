import 'package:flutter/material.dart';
import 'package:fitpulse/core/theme/app_theme.dart';
import 'package:fitpulse/core/utils/turkish_date.dart';
import 'package:fitpulse/data/local/daos/workout_dao.dart';
import 'package:fitpulse/data/models/workout_model.dart';
import '../widgets/exercise_card.dart';
import '../widgets/exercise_selector_sheet.dart';

class ActiveWorkoutPage extends StatefulWidget {
  final String? workoutTitle;

  /// Şablondan başlatıldıysa programın id'si: hareketler buradan yüklenir ve
  /// kaydedilen oturum bu programa bağlanır.
  final int? programId;

  /// Doluysa ekran DÜZENLEME modunda açılır: kaydedilmiş antrenman geri
  /// yüklenir ve Kaydet yeni kayıt açmak yerine bu oturumu günceller.
  ///
  /// Aynı ekranı yeniden kullanıyoruz çünkü set girişi (hareket satırları,
  /// kilo/tekrar alanları, RPE seçici, set ekle/sil) ikinci kez yazılacak
  /// kadar küçük bir arayüz değil.
  final int? editSessionId;

  const ActiveWorkoutPage({
    super.key,
    this.workoutTitle,
    this.programId,
    this.editSessionId,
  });

  bool get isEditing => editSessionId != null;

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

  // Tarih ve süre değişkenleri.
  // Süre BOŞ başlar (ipucu olarak 60 görünür): ön dolu değer, süreyi hiç
  // girmeyenlerin her antrenmanına uydurma bir 60 dk yazıyordu ve hibrit
  // zorluk skoru (RPE x dakika) bu yüzden sistematik bozuluyordu. Kaydet
  // zaten süresiz kayda izin vermiyor.
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _durationController = TextEditingController();

  bool _isSaving = false;

  // Bu antrenman aynı zamanda kendi şablonum olarak kaydedilsin mi
  bool _saveAsTemplate = false;
  String _templateTitle = '';

  /// Düzenlenen antrenmanın kayıtlı program bağlantısı. Ekrana yüklerken
  /// alınıp kaydederken geri yazılır; yoksa kiloyu düzeltmek bile oturumun
  /// "hangi şablonla yapıldı" bilgisini sessizce siliyordu.
  int? _sessionProgramId;

  /// Ekranın "kaydedilmiş" bilinen hali. Çıkışta güncel parmak iziyle
  /// kıyaslanır; farklıysa kullanıcıya sorulur. Kilo/tekrar alanları setState
  /// çağırmadan doğrudan modeli değiştirdiği için bir dirty bayrağı yerine
  /// anlık kıyas kullanıyoruz — bayrak o girişleri kaçırırdı.
  String _savedFingerprint = '';

  @override
  void initState() {
    super.initState();
    _savedFingerprint = _fingerprint();
    if (widget.isEditing) {
      _loadSessionForEditing();
    } else if (widget.programId != null) {
      _loadTemplateExercises();
    }
  }

  // Kaydedilmemiş iş var mı sorusunun cevabı bu metnin değişip değişmediği
  String _fingerprint() {
    final buffer = StringBuffer()
      ..write(_selectedDate.toIso8601String())
      ..write('|')
      ..write(_durationController.text.trim())
      ..write('|')
      ..write(_saveAsTemplate);
    for (final exercise in _currentExercises) {
      buffer.write(';${exercise.name}');
      for (final set in exercise.sets) {
        buffer.write(
            ':${set.weight},${set.reps},${set.seconds},${set.difficulty},${set.difficultyTouched}');
      }
    }
    return buffer.toString();
  }

  bool get _hasUnsavedChanges => _fingerprint() != _savedFingerprint;

  /// X butonu ve sistem geri hareketi buradan geçer: girilmiş ama
  /// kaydedilmemiş bir şey varsa sormadan atmıyoruz. Salonda yanlış bir geri
  /// kaydırma, 1 saatlik antrenmanın dökümünü sessizce silmemeli.
  Future<void> _handleClose() async {
    if (!_hasUnsavedChanges) {
      Navigator.pop(context);
      return;
    }

    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Kaydetmeden çık?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          widget.isEditing
              ? 'Bu antrenmanda yaptığın değişiklikler kaydedilmedi. '
                  'Çıkarsan kayıt eski haliyle kalır.'
              : 'Girdiğin hareketler ve setler kaydedilmedi. '
                  'Çıkarsan hepsi silinir.',
          style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Çık',
                style: TextStyle(
                    color: Color(0xFFE05B4B), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (leave == true && mounted) Navigator.pop(context);
  }

  // Kaydedilmiş antrenmanı ekrana geri yükler
  Future<void> _loadSessionForEditing() async {
    setState(() => _isLoadingTemplate = true);
    final detail = await _workoutDao.getSessionDetail(widget.editSessionId!);
    if (!mounted) return;

    if (detail == null) {
      // Kullanıcı başka bir yerden silmiş olabilir
      setState(() => _isLoadingTemplate = false);
      _showMessage('Bu antrenman artık kayıtlı değil.');
      Navigator.pop(context, true);
      return;
    }

    setState(() {
      _currentExercises
        ..clear()
        ..addAll(detail.exercises);
      _selectedDate = detail.date;
      _durationController.text = detail.duration.toString();
      _sessionProgramId = detail.programId;
      _isLoadingTemplate = false;
    });
    // Yüklenen hali "temiz" say; kullanıcı dokunmadan çıkarsa soru sorulmasın
    _savedFingerprint = _fingerprint();
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
    // Şablonun boş setleri henüz girilmiş veri değil; temiz kabul et
    _savedFingerprint = _fingerprint();
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
      if (widget.isEditing) {
        await _workoutDao.updateWorkoutSession(
          sessionId: widget.editSessionId!,
          date: _selectedDate,
          duration: duration,
          exercises: _currentExercises,
          // Düzenleme bu ekrana programId'siz açılır; oturumun kendi
          // bağlantısını koruyoruz
          programId: widget.programId ?? _sessionProgramId,
        );
        if (!mounted) return;
        _showMessage('Antrenman güncellendi.');
        Navigator.pop(context, true);
        return;
      }

      await _workoutDao.saveWorkoutSession(
        date: _selectedDate,
        duration: duration,
        exercises: _currentExercises,
        programId: widget.programId, // şablondan geldiyse oturum ona bağlanır
      );

      // Şablona ekleme antrenman kaydından SONRA ve ayrı bir adım:
      // burada bir hata çıksa bile antrenman kaydı çoktan diske yazılmış olur.
      var savedAsTemplate = false;
      if (_saveAsTemplate) {
        try {
          await _workoutDao.saveSessionAsTemplate(
            title: _templateTitle,
            exercises: _currentExercises,
            durationMinutes: duration,
          );
          savedAsTemplate = true;
        } catch (e) {
          if (!mounted) return;
          _showMessage('Antrenman kaydedildi ama şablon oluşturulamadı: $e');
        }
      }

      if (!mounted) return;
      _showMessage(savedAsTemplate
          ? 'Antrenman kaydedildi, şablonun Taslaklarım\'a eklendi.'
          : 'Antrenman kaydedildi.');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage('Kayıt sırasında bir hata oluştu: $e');
    }
  }

  // Kullanıcı bu antrenmanı tekrar tekrar yapmak isteyebilir; şablona
  // çevirince hareket listesi Taslaklarım'a düşer. Ağırlık taşınmaz —
  // plan "ne yapılacağını" söyler, kaç kilo kaldırılacağını değil.
  Future<void> _promptSaveAsTemplate() async {
    final controller = TextEditingController(
        text: _templateTitle.isNotEmpty
            ? _templateTitle
            : (widget.workoutTitle == null ||
                    widget.workoutTitle == 'Boş Antrenman'
                ? ''
                : widget.workoutTitle!));

    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Şablon olarak kaydet',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hareketler ve set sayıları Taslaklarım\'a kaydedilir. '
              'Ağırlıklar kaydedilmez; onları her antrenmanda yeniden girersin.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Şablon adı',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.volt),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Tamam',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (!mounted || title == null) return;

    if (title.isEmpty) {
      _showMessage('Şablona bir isim vermelisin.');
      return;
    }
    if (await _workoutDao.templateTitleExists(title)) {
      if (!mounted) return;
      _showMessage('"$title" adında bir şablonun zaten var.');
      return;
    }

    if (!mounted) return;
    setState(() {
      _templateTitle = title;
      _saveAsTemplate = true;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Silme geri alınamıyor, o yüzden onay soruyoruz — ve neyin silineceğini
  /// tarihiyle söylüyoruz ki kullanıcı yanlış antrenmanı açtığını fark etsin.
  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Antrenmanı sil',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          '${formatShortDate(_selectedDate)} tarihli antrenman ve bütün '
          'setleri silinecek. Bu işlem geri alınamaz.',
          style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil',
                style: TextStyle(
                    color: Color(0xFFE05B4B), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);
    await _workoutDao.deleteSession(widget.editSessionId!);
    if (!mounted) return;
    _showMessage('Antrenman silindi.');
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    // canPop hep false: sistem geri hareketi de X ile aynı korumadan geçsin.
    // Kayıt/silme sonrası programatik Navigator.pop'lar maybePop kullanmadığı
    // için bu kalkana takılmaz.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleClose();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon:
                const Icon(Icons.close, color: AppColors.textPrimary, size: 28),
            onPressed: _handleClose,
          ),
          title: Text(
            widget.isEditing
                ? 'Antrenmanı Düzenle'
                : (widget.workoutTitle ?? 'Antrenmanı Kaydet'),
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
          actions: [
            if (widget.isEditing)
              IconButton(
                tooltip: 'Antrenmanı sil',
                onPressed: _isSaving ? null : _confirmDelete,
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.textSecondary),
              ),
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
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
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
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
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
                                  hintText: '60',
                                  hintStyle: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
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
                child: ExerciseCard(
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

            // ŞABLON OLARAK KAYDET
            // Şablondan başlatılan antrenmanda gizli: plan zaten Taslaklarım'da.
            // Düzenlemede de gizli: burada iş kaydı düzeltmek, yeni plan çıkarmak
            // değil — ve şablon zaten ilk kayıtta oluşturulabiliyordu.
            if (!widget.isEditing &&
                widget.programId == null &&
                _currentExercises.isNotEmpty) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: _isSaving
                    ? null
                    : () {
                        if (_saveAsTemplate) {
                          setState(() => _saveAsTemplate = false);
                        } else {
                          _promptSaveAsTemplate();
                        }
                      },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color:
                            _saveAsTemplate ? AppColors.volt : AppColors.stroke,
                        width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                          _saveAsTemplate
                              ? Icons.check_circle
                              : Icons.bookmark_add_outlined,
                          color: _saveAsTemplate
                              ? AppColors.volt
                              : AppColors.textSecondary,
                          size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _saveAsTemplate
                                  ? _templateTitle
                                  : 'Şablon olarak kaydet',
                              style: TextStyle(
                                  color: _saveAsTemplate
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _saveAsTemplate
                                  ? 'Taslaklarım\'a eklenecek — kaldırmak için dokun'
                                  : 'Hareketleri Taslaklarım\'a kaydet, ağırlıklar hariç',
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
