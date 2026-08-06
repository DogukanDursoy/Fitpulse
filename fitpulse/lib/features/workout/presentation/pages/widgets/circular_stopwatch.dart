import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fitpulse/core/theme/app_theme.dart'; // Yolu kendi projene göre ayarla

class WorkoutStopwatch extends StatefulWidget {
  const WorkoutStopwatch({super.key});

  @override
  State<WorkoutStopwatch> createState() => _WorkoutStopwatchState();
}

class _WorkoutStopwatchState extends State<WorkoutStopwatch> {
  bool _isRunning = false;
  Duration _elapsedTime = Duration.zero;
  Timer? _timer;

  void _startTimer() {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime += const Duration(seconds: 1);
      });
    });
  }

  void _pauseTimer() {
    if (!_isRunning) return;
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _elapsedTime = Duration.zero;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // Çalışmıyorsa ve süre sıfırdan büyükse "DURAKLATILDI" durumundadır
    final bool isPaused = !_isRunning && _elapsedTime > Duration.zero;

    return Container(
      height: 64,
      width: double.infinity,
      decoration: BoxDecoration(
        color:
            _isRunning ? AppColors.volt.withOpacity(0.08) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isRunning ? AppColors.volt : AppColors.stroke,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. SOL İKON: Duraklat (Tıklanabilir)
          Material(
            color: Colors.transparent,
            child: IconButton(
              onPressed: _isRunning
                  ? _pauseTimer
                  : null, // Sadece çalışırken tıklanabilir
              icon: Icon(
                Icons.pause,
                color: _isRunning
                    ? AppColors.textPrimary
                    : AppColors.textSecondary.withOpacity(0.3),
                size: 24,
              ),
            ),
          ),

          // 2. ORTA: Süre ve Başlatma Alanı (Genişletilmiş Tıklanabilir Alan)
          Expanded(
            child: GestureDetector(
              onTap:
                  _startTimer, // Ortaya basınca başlar (veya duraklatıldıysa devam eder)
              behavior:
                  HitTestBehavior.opaque, // Boşluklara tıklanmayı da algılar
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isRunning
                        ? 'ÇALIŞIYOR'
                        : (isPaused
                            ? 'DURAKLATILDI (DEVAM ET)'
                            : 'BAŞLAMAK İÇİN DOKUN'),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(_elapsedTime),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color:
                          _isRunning ? AppColors.volt : AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. SAĞ İKON: Bitir / Sıfırla (Tıklanabilir)
          Material(
            color: Colors.transparent,
            child: IconButton(
              onPressed: _elapsedTime > Duration.zero
                  ? _resetTimer
                  : null, // Sadece süre ilerlediyse tıklanabilir
              icon: Icon(
                Icons.square,
                color: _elapsedTime > Duration.zero
                    ? AppColors.textPrimary
                    : AppColors.textSecondary.withOpacity(0.3),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
