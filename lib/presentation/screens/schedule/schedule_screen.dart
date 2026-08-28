import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/ui/tactile_button.dart';
import '../../../domain/entities/class_session_entity.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/add_edit_slot_dialog.dart';
import '../../widgets/batch_add_slot_dialog.dart';
import '../ocr/ocr_scanner_screen.dart';
import '../share/qr_share_scanner_screen.dart';
import '../../widgets/edit_semester_dialog.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  int _selectedDayIndex = 0; // 0 = Sun, 1 = Mon, ..., 6 = Sat

  static const List<String> _days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const List<int> _dayValues = [7, 1, 2, 3, 4, 5, 6];

  @override
  void initState() {
    super.initState();
    // Default to today's weekday (Sunday is 7 -> index 0)
    final todayWeekday = DateTime.now().weekday;
    _selectedDayIndex = todayWeekday % 7;
  }

  void _promptSemesterRequired(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            'Semester Setup Required',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          content: Text(
            'Please create and activate a semester first before creating your timetable schedule.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => const EditSemesterDialog(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                foregroundColor: isDark ? AppColors.bgDark : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Set Up Semester', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeSem = ref.watch(activeSemesterProvider);
    final slots = ref.watch(timetableSlotsProvider);
    final selectedDayValue = _dayValues[_selectedDayIndex];
    final daySlots = slots.where((s) => s.dayOfWeek == selectedDayValue).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Timetable',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      letterSpacing: -0.8,
                    ),
                  ),
                  Row(
                    children: [
                      // OCR / Scanner icon button (BETA ONLY)
                      if (ref.watch(betaFeaturesEnabledProvider)) ...[
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const OcrScannerScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.pillDark : AppColors.pillLight,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.document_scanner_outlined,
                              size: 19,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Batch Add Slots button
                      TactileIconButton(
                        icon: Icons.event_repeat_rounded,
                        size: 40,
                        iconSize: 19,
                        backgroundColor: isDark ? AppColors.pillDark : AppColors.pillLight,
                        iconColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        tooltip: 'Batch Schedule Setup',
                        onTap: () {
                          if (activeSem.isUnset) {
                            _promptSemesterRequired(context);
                            return;
                          }
                          showDialog(
                            context: context,
                            builder: (context) => const BatchAddSlotDialog(),
                          );
                        },
                      ),
                      const SizedBox(width: 8),

                      // Share QR icon button
                      TactileIconButton(
                        icon: Icons.qr_code_2_rounded,
                        size: 40,
                        iconSize: 19,
                        backgroundColor: isDark ? AppColors.pillDark : AppColors.pillLight,
                        iconColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        tooltip: 'Share & Scan Timetable',
                        onTap: () {
                          if (activeSem.isUnset) {
                            _promptSemesterRequired(context);
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const QrShareScannerScreen()),
                          );
                        },
                      ),
                      const SizedBox(width: 8),

                      // Add Slot button
                      TactileIconButton(
                        icon: Icons.add_rounded,
                        size: 40,
                        iconSize: 22,
                        backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        iconColor: isDark ? AppColors.bgDark : AppColors.surfaceLight,
                        tooltip: 'Add Class Slot',
                        onTap: () {
                          if (activeSem.isUnset) {
                            _promptSemesterRequired(context);
                            return;
                          }
                          showDialog(
                            context: context,
                            builder: (context) => AddEditSlotDialog(initialDayOfWeek: _dayValues[_selectedDayIndex]),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Horizontal Day Pills Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final isSelected = index == _selectedDayIndex;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedDayIndex = index;
                      });
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? AppColors.pillDark : AppColors.pillLight)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        _days[index],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                              : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 12),

            // Timetable Cards List
            Expanded(
              child: activeSem.isUnset
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? AppColors.surfaceDark : const Color(0xFFEFF6FF),
                              ),
                              child: Icon(Icons.school_rounded, size: 28, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Active Semester',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Create your semester to start building and tracking your weekly timetable schedule.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 18),
                            ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => const EditSemesterDialog(),
                                );
                              },
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Create Semester', style: TextStyle(fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                foregroundColor: isDark ? AppColors.bgDark : Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : daySlots.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'No classes scheduled for ${_days[_selectedDayIndex]}.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => const BatchAddSlotDialog(),
                                  );
                                },
                                icon: const Icon(Icons.date_range_rounded, size: 16),
                                label: const Text('Batch Add Classes'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: daySlots.length,
                          itemBuilder: (context, index) {
                            final s = daySlots[index];

                            Color dotColor;
                            try {
                              final hex = s.colorHex.replaceAll('#', '');
                              dotColor = Color(int.parse('FF$hex', radix: 16));
                            } catch (_) {
                              dotColor = AppColors.cancelledViolet;
                            }

                        final sessionEntity = ClassSessionEntity(
                          id: s.id,
                          semesterId: s.semesterId,
                          subjectComponentId: s.subjectComponentId,
                          subjectName: s.subjectName,
                          subjectCode: s.subjectCode,
                          category: s.category,
                          componentType: s.componentType,
                          colorHex: s.colorHex,
                          sessionDate: '',
                          dayOfWeek: s.dayOfWeek,
                          startTime: s.startTime,
                          endTime: s.endTime,
                          sessionSource: 'TIMETABLE',
                          sourceRefId: s.id,
                          status: 'HELD',
                          room: s.room,
                          teacherName: s.teacherName,
                          attendanceOutcome: 'PENDING',
                          effectiveFrom: s.effectiveFrom,
                          effectiveUntil: s.effectiveUntil,
                        );

                        final String subtitle = [
                          if (s.room != null && s.room!.isNotEmpty)
                            (s.room!.toLowerCase().contains('room') || s.room!.toLowerCase().contains('lab')
                                ? s.room!
                                : 'Room ${s.room}')
                          else
                            s.componentType,
                          if (s.teacherName != null && s.teacherName!.isNotEmpty)
                            s.teacherName!,
                        ].join('  •  ');

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AddEditSlotDialog(
                                  existingSlot: sessionEntity,
                                  initialDayOfWeek: s.dayOfWeek,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                children: [
                                  // Left Time Column
                                  SizedBox(
                                    width: 56,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.startTime,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          s.endTime,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Vertical separator
                                  Container(
                                    width: 1,
                                    height: 38,
                                    margin: const EdgeInsets.symmetric(horizontal: 14),
                                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                  ),

                                  // Right Subject Info Column
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                s.subjectName,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                                  letterSpacing: -0.2,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Category Color Dot
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: dotColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          subtitle.isNotEmpty ? subtitle : s.componentType,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
