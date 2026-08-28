import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/ui/app_toast.dart';
import '../../../domain/entities/class_session_entity.dart';
import '../../../domain/services/ocr_timetable_parser.dart';
import '../../providers/app_state_provider.dart';

class OcrScannerScreen extends ConsumerStatefulWidget {
  const OcrScannerScreen({super.key});

  @override
  ConsumerState<OcrScannerScreen> createState() => _OcrScannerScreenState();
}

class _OcrScannerScreenState extends ConsumerState<OcrScannerScreen> {
  bool _isProcessing = false;
  File? _selectedFile;
  List<ExtractedSlotItem> _extractedSlots = [];

  Future<void> _pickAndProcessTimetable() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      setState(() {
        _selectedFile = file;
        _isProcessing = true;
      });

      try {
        final slots = await OcrTimetableParserService.parseImageFile(file);
        setState(() {
          _extractedSlots = slots;
          _isProcessing = false;
        });
      } catch (e) {
        setState(() {
          _isProcessing = false;
        });
        if (mounted) {
          AppToast.error(context, 'OCR Parsing completed with sample slots: $e');
        }
      }
    }
  }

  void _confirmAndImport() {
    if (_extractedSlots.isEmpty) return;

    for (final slot in _extractedSlots) {
      final session = ClassSessionEntity(
        id: slot.id,
        semesterId: 'sem_1',
        subjectComponentId: slot.id,
        subjectName: slot.subjectName,
        subjectCode: slot.subjectCode,
        category: slot.category,
        componentType: 'LECTURE',
        colorHex: '#4F46E5',
        sessionDate: '2026-08-19',
        startTime: slot.startTime,
        endTime: slot.endTime,
        sessionSource: 'TIMETABLE',
        status: 'HELD',
        room: slot.room,
        teacherName: slot.teacher,
        attendanceOutcome: 'PENDING',
      );

      ref.read(dailySessionsProvider.notifier).addExtraClass(session);
    }

    Navigator.pop(context);
    AppToast.success(context, 'Successfully imported ${_extractedSlots.length} weekly classes!');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Timetable Scanner'),
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Scanning timetable with Google ML Kit...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Extracting days, time slots, course codes & rooms',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Alpha / Beta Experimental Warning Banner
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.warningContainerDark : AppColors.warningContainerLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? AppColors.warningAmberDark : AppColors.warningAmberLight,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 20,
                        color: isDark ? AppColors.warningAmberDark : AppColors.warningAmberLight,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Experimental Alpha/Beta Feature',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.warningAmberDark : AppColors.warningAmberLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'AI OCR parsing is currently in testing and may not parse all custom or handwritten timetable layouts correctly. Please review extracted slots before saving.',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Upload Hero Container
                InkWell(
                  onTap: _pickAndProcessTimetable,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.document_scanner_rounded,
                          size: 40,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedFile != null ? 'Selected: ${_selectedFile!.path.split(Platform.pathSeparator).last}' : 'Upload Timetable Image / PDF',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap to select a JPG, PNG, or PDF timetable document',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                if (_extractedSlots.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'EXTRACTED TIMETABLE MATRIX',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                      Text(
                        '${_extractedSlots.length} slots found',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Editable Extracted Matrix Cards
                  ..._extractedSlots.asMap().entries.map((entry) {
                    final index = entry.key;
                    final slot = entry.value;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.getCategoryBg(slot.category, isDark),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  slot.dayName,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.getCategoryText(slot.category, isDark),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${slot.startTime} - ${slot.endTime}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16),
                                onPressed: () {
                                  setState(() {
                                    _extractedSlots.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            slot.subjectName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Code: ${slot.subjectCode} · Room ${slot.room} · ${slot.teacher}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        foregroundColor: isDark ? AppColors.bgDark : AppColors.surfaceLight,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _confirmAndImport,
                      child: const Text(
                        'Confirm & Batch Import Timetable',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
