import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class CountdownGate extends StatefulWidget {
  const CountdownGate({super.key, required this.child});

  final Widget child;

  @override
  State<CountdownGate> createState() => _CountdownGateState();
}

class _CountdownGateState extends State<CountdownGate> {
  static final DateTime allowedAt = DateTime(2026, 7, 1, 5, 0);  // yyyy,m,d,hh,mm

  bool isReady = false;
  bool isChecking = true;
  Timer? countdownTimer;

  @override
  void initState() {
    super.initState();
    checkAccess();
  }

  bool isUsageAllowed() {
    return !DateTime.now().isBefore(allowedAt);
  }

  String formatAllowedAt() {
    final day = allowedAt.day.toString().padLeft(2, '0');
    final month = allowedAt.month.toString().padLeft(2, '0');
    final year = allowedAt.year.toString();
    final hour = allowedAt.hour.toString().padLeft(2, '0');
    final minute = allowedAt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String formatRemainingTime() {
    final remaining = allowedAt.difference(DateTime.now());

    if (remaining.isNegative || remaining.inSeconds <= 0) {
      return '0 วัน 0 ชม 0 นาที 0 วินาที';
    }

    final days = remaining.inDays;
    final hours = remaining.inHours.remainder(24);
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);

    return '$days วัน $hours ชม $minutes นาที $seconds วินาที';
  }

  Future<void> checkAccess() async {
    if (!mounted) return;

    if (isUsageAllowed()) {
      countdownTimer?.cancel();
      FlutterNativeSplash.remove();
      setState(() {
        isChecking = false;
        isReady = true;
      });
      return;
    }

    startCountdown();
    FlutterNativeSplash.remove();
    setState(() {
      isChecking = false;
      isReady = false;
    });
  }

  void startCountdown() {
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (isUsageAllowed()) {
        timer.cancel();
        checkAccess();
        return;
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isChecking) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('กำลังตรวจสอบเวลาเข้าใช้งาน...'),
            ],
          ),
        ),
      );
    }

    if (isReady) {
      return widget.child;
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/icon.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'ระบบยังไม่เปิดให้ใช้งาน',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'แอปจะเปิดให้ใช้งานวันที่ ${formatAllowedAt()}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'พร้อมใช้งานในอีก',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            formatRemainingTime(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'ระบบจะเปิดให้ใช้งานโดยอัตโนมัติเมื่อถึงเวลาที่กำหนด.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
