import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/constants/app_colors.dart';
import '../../core/ui/app_toast.dart';
import '../../core/utils/uuid_generator.dart';
import '../../domain/entities/class_session_entity.dart';
import '../providers/app_state_provider.dart';

class QrScannerDialog extends ConsumerStatefulWidget {
  const QrScannerDialog({super.key});

  @override
  ConsumerState<QrScannerDialog> createState() => _QrScannerDialogState();
}

class _QrScannerDialogState extends ConsumerState<QrScannerDialog> {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasScanned = false;
  bool _hasCameraError = false;
  final _manualCodeController = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  void _importJsonPayload(String rawCode) {
    try {
      final Map<String, dynamic> data = jsonDecode(rawCode);
      if (data.containsKey('slots')) {
        _hasScanned = true;

        final List slots = data['slots'];
        for (final slot in slots) {
          final session = ClassSessionEntity(
            id: UuidGenerator.generate(),
            semesterId: 'sem_1',
            subjectComponentId: UuidGenerator.generate(),
            subjectName: slot['name'] ?? 'Classmate Subject',
            subjectCode: slot['code'],
            category: slot['cat'] ?? 'MAJOR',
            componentType: 'LECTURE',
            colorHex: '#4F46E5',
            sessionDate: '2026-08-19',
            startTime: slot['start'] ?? '09:00',
            endTime: slot['end'] ?? '10:00',
            sessionSource: 'TIMETABLE',
            status: 'HELD',
            room: slot['room'],
            teacherName: slot['teacher'],
            attendanceOutcome: 'PENDING',
          );

          ref.read(dailySessionsProvider.notifier).addExtraClass(session);
        }

        if (mounted) {
          Navigator.pop(context);
          AppToast.success(context, 'Imported ${slots.length} timetable slots from classmate!');
        }
      }
    } catch (_) {
      if (mounted) {
        AppToast.error(context, 'Invalid timetable QR code format');
      }
    }
  }

  void _handleQrDetection(BarcodeCapture capture) {
    if (_hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        _importJsonPayload(barcode.rawValue!);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      title: Text(
        'Scan Classmate QR Code',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      content: SizedBox(
        width: 260,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_hasCameraError)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 240,
                    height: 200,
                    child: MobileScanner(
                      controller: _controller,
                      onDetect: _handleQrDetection,
                      errorBuilder: (context, error) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && !_hasCameraError) {
                            setState(() => _hasCameraError = true);
                          }
                        });
                        return Container(
                          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                'Camera requires app restart to bind native permissions.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.camera_alt_outlined, size: 32, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                      const SizedBox(height: 8),
                      Text(
                        'Camera unavailable or pending restart',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Paste JSON timetable payload below:',
                        style: TextStyle(fontSize: 11, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _manualCodeController,
                        maxLines: 3,
                        style: TextStyle(fontSize: 11, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        decoration: const InputDecoration(hintText: 'Paste timetable JSON here...'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (_manualCodeController.text.trim().isNotEmpty) {
                            _importJsonPayload(_manualCodeController.text.trim());
                          }
                        },
                        child: const Text('Import JSON'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                'Point camera at classmate\'s ClassTrack QR code',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
        ),
      ],
    );
  }
}
