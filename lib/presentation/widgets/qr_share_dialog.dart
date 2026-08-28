import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../providers/app_state_provider.dart';
import 'qr_scanner_dialog.dart';

class QrShareDialog extends ConsumerWidget {
  const QrShareDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sessions = ref.watch(dailySessionsProvider);

    final payloadData = {
      'v': 1,
      'sem': 'Semester III',
      'slots': sessions.map((s) => {
        'name': s.subjectName,
        'code': s.subjectCode,
        'cat': s.category,
        'start': s.startTime,
        'end': s.endTime,
        'room': s.room,
        'teacher': s.teacherName,
      }).toList(),
    };

    final jsonString = jsonEncode(payloadData);

    return AlertDialog(
      backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      title: Text(
        'Share & Scan QR Code',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      content: SizedBox(
        width: 260,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SizedBox(
                width: 200,
                height: 200,
                child: QrImageView(
                  data: jsonString,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Show this QR code to a classmate, or tap below to scan their QR code!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            showDialog(
              context: context,
              builder: (context) => const QrScannerDialog(),
            );
          },
          child: const Text('Scan Classmate QR'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            foregroundColor: isDark ? AppColors.bgDark : AppColors.surfaceLight,
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
