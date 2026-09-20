import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/ui/tactile_button.dart';
import '../../../domain/entities/class_session_entity.dart';
import '../../../domain/entities/semester_entity.dart';
import '../../../domain/services/schedule_engine.dart';
import '../../providers/app_state_provider.dart';
import 'add_edit_slot_screen.dart';
import 'batch_add_slots_screen.dart';
import '../ocr/ocr_scanner_screen.dart';
import '../share/qr_share_scanner_screen.dart';
import '../../widgets/edit_semester_dialog.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_theme_tokens.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  int _selectedDayIndex = 0; // 0 = Sun, 1 = Mon, ..., 6 = Sat

  static const List<String> _days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const List<String> _fullDayNames = [
    'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
  ];
  static const List<int> _dayValues = [7, 1, 2, 3, 4, 5, 6];

  @override
  void initState() {
    super.initState();
    // Default to today's weekday (Sunday is 7 -> index 0)
    final todayWeekday = DateTime.now().weekday;
    _selectedDayIndex = todayWeekday % 7;
  }

  void _promptSemesterRequired(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final isCute = tokens?.isCute ?? false;

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isCute
              ? (isDark ? const Color(0xFF183122) : const Color(0xFFFAF7F2))
              : (isDark ? AppColors.cardDark : AppColors.cardLight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isCute ? 24 : 14)),
          title: Text(
            'Semester Setup Required',
            style: isCute
                ? GoogleFonts.quicksand(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: isDark ? const Color(0xFFE8F4EB) : const Color(0xFF192E21),
                  )
                : TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
          ),
          content: Text(
            'Please create and activate a semester first before creating your timetable schedule.',
            style: isCute
                ? GoogleFonts.quicksand(
                    fontSize: 13.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF98B5A3) : const Color(0xFF526B5C),
                  )
                : TextStyle(
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
                style: isCute
                    ? GoogleFonts.quicksand(
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF98B5A3) : const Color(0xFF526B5C),
                      )
                    : TextStyle(
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
                backgroundColor: isCute
                    ? (tokens?.primaryAccent ?? const Color(0xFF558A50))
                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                foregroundColor: isCute
                    ? Colors.white
                    : (isDark ? AppColors.bgDark : Colors.white),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isCute ? 14 : 10)),
              ),
              child: Text(
                'Set Up Semester',
                style: isCute
                    ? GoogleFonts.quicksand(fontWeight: FontWeight.w800)
                    : const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final isCute = tokens?.isCute ?? false;
    final activeSem = ref.watch(activeSemesterProvider);
    final slots = ref.watch(timetableSlotsProvider);
    final selectedDayValue = _dayValues[_selectedDayIndex];
    final daySlots = slots.where((s) => s.dayOfWeek == selectedDayValue).toList();

    if (isCute) {
      return _buildSproutScheduleScreen(
        context: context,
        isDark: isDark,
        tokens: tokens,
        activeSem: activeSem,
        daySlots: daySlots,
      );
    }

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
                children: [
                  Expanded(
                    child: Text(
                      'Timetable',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        letterSpacing: -0.8,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const BatchAddSlotsScreen()),
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddEditSlotScreen(initialDayOfWeek: _dayValues[_selectedDayIndex]),
                            ),
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
                children: List.generate(7, (index) {
                  final isSelected = index == _selectedDayIndex;
                  return Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedDayIndex = index;
                        });
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
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
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                          ),
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const BatchAddSlotsScreen()),
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddEditSlotScreen(
                                    existingSlot: sessionEntity,
                                    initialDayOfWeek: s.dayOfWeek,
                                  ),
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

  // ==========================================
  // SPROUTS THEME IMPLEMENTATION
  // ==========================================

  Widget _buildSproutScheduleScreen({
    required BuildContext context,
    required bool isDark,
    required AppThemeTokens? tokens,
    required SemesterEntity activeSem,
    required List<TimetableSlotItem> daySlots,
  }) {
    final screenBg = isDark ? const Color(0xFF112318) : const Color(0xFFFAF7F2);
    final textPrimary = isDark ? const Color(0xFFE8F4EB) : const Color(0xFF192E21);
    final textMuted = isDark ? const Color(0xFF648671) : const Color(0xFF849E8E);
    final isNoSemester = activeSem.isUnset == true;

    final semTitle = isNoSemester
        ? 'NO ACTIVE SEMESTER'
        : (activeSem.name.isEmpty ? 'SEMESTER' : activeSem.name.toString().toUpperCase());
    final semYear = isNoSemester
        ? 'SETUP REQUIRED'
        : activeSem.academicYear;

    return Scaffold(
      backgroundColor: screenBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Screen Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Timetable',
                          style: GoogleFonts.quicksand(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.9,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$semTitle · $semYear',
                          style: GoogleFonts.quicksand(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: textMuted,
                            letterSpacing: 0.6,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // OCR / Scanner squircle (BETA ONLY)
                      if (ref.watch(betaFeaturesEnabledProvider)) ...[
                        _buildSproutActionButton(
                          icon: Icons.document_scanner_outlined,
                          tooltip: 'Scan Document',
                          isDark: isDark,
                          tokens: tokens,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const OcrScannerScreen()),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Batch Add Slots squircle button
                      _buildSproutActionButton(
                        icon: Icons.calendar_view_week_rounded,
                        tooltip: 'Batch Schedule Setup',
                        isDark: isDark,
                        tokens: tokens,
                        iconSize: 22,
                        onTap: () {
                          if (isNoSemester) {
                            _promptSemesterRequired(context);
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const BatchAddSlotsScreen()),
                          );
                        },
                      ),
                      const SizedBox(width: 8),

                      // QR Share & Scan squircle button
                      _buildSproutActionButton(
                        icon: Icons.qr_code_scanner_rounded,
                        tooltip: 'Share & Scan Timetable',
                        isDark: isDark,
                        tokens: tokens,
                        iconSize: 22,
                        onTap: () {
                          if (isNoSemester) {
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

                      // Primary Add Slot squircle button
                      _buildSproutActionButton(
                        icon: Icons.add_rounded,
                        tooltip: 'Add Class Slot',
                        isDark: isDark,
                        tokens: tokens,
                        isPrimary: true,
                        iconSize: 26,
                        onTap: () {
                          if (isNoSemester) {
                            _promptSemesterRequired(context);
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddEditSlotScreen(
                                initialDayOfWeek: _dayValues[_selectedDayIndex],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Horizontal Weekday Capsule Bar
            _buildSproutDaySelector(isDark, tokens),

            // Weekday Summary Strip
            if (!isNoSemester && daySlots.isNotEmpty)
              _buildSproutDaySummary(isDark, tokens, daySlots.length),

            const SizedBox(height: 6),

            // Slots List or Empty State with floating nav bar clearance (105px)
            Expanded(
              child: isNoSemester
                  ? _buildSproutEmptyState(
                      context: context,
                      isDark: isDark,
                      tokens: tokens,
                      isNoSemester: true,
                    )
                  : daySlots.isEmpty
                      ? _buildSproutEmptyState(
                          context: context,
                          isDark: isDark,
                          tokens: tokens,
                          isNoSemester: false,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                          itemCount: daySlots.length + 1,
                          itemBuilder: (context, index) {
                            if (index == daySlots.length) {
                              return _buildSproutBottomSpeechFooter(
                                context: context,
                                isDark: isDark,
                                tokens: tokens,
                                daySlots: daySlots,
                              );
                            }
                            final s = daySlots[index];
                            return _buildSproutSlotCard(
                              context: context,
                              s: s,
                              isDark: isDark,
                              tokens: tokens,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSproutActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    required bool isDark,
    required AppThemeTokens? tokens,
    bool isPrimary = false,
    double iconSize = 20,
  }) {
    final primaryGradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF74AD6E), Color(0xFF598F53)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFF609758), Color(0xFF487A42)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final bgColor = isPrimary
        ? null
        : (isDark ? const Color(0xFF1A3725) : const Color(0xFFF1F6EF));
    final borderColor = isPrimary
        ? Colors.transparent
        : (isDark ? const Color(0xFF2A5339) : const Color(0xFFDFE9DA));
    final iconColor = isPrimary
        ? Colors.white
        : (isDark ? const Color(0xFFA6D4A4) : const Color(0xFF3C6737));

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: bgColor,
            gradient: isPrimary ? primaryGradient : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              if (isPrimary)
                BoxShadow(
                  color: (tokens?.primaryAccent ?? const Color(0xFF558A50)).withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                )
              else
                BoxShadow(
                  color: isDark ? Colors.black26 : const Color(0x12558A50),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: iconColor,
          ),
        ),
      ),
    );
  }

  Widget _buildSproutDaySelector(bool isDark, AppThemeTokens? tokens) {
    final pillBg = isDark ? const Color(0xFF183122) : const Color(0xFFEEF4EB);
    final borderColor = isDark ? const Color(0xFF264A34) : const Color(0xFFDFE8DC);
    final activeBg = tokens?.primaryAccent ?? const Color(0xFF558A50);
    final activeTextColor = isDark ? const Color(0xFF0C1D12) : Colors.white;
    final inactiveTextColor = isDark ? const Color(0xFF98B5A3) : const Color(0xFF526B5C);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: pillBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: List.generate(7, (index) {
            final isSelected = index == _selectedDayIndex;

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _selectedDayIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOutCubic,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? activeBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: activeBg.withValues(alpha: 0.32),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    _days[index],
                    style: GoogleFonts.quicksand(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                      color: isSelected ? activeTextColor : inactiveTextColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSproutDaySummary(bool isDark, AppThemeTokens? tokens, int count) {
    final textMuted = isDark ? const Color(0xFF648671) : const Color(0xFF849E8E);
    final primaryAccent = tokens?.primaryAccent ?? const Color(0xFF558A50);
    final primaryLight = isDark ? const Color(0xFF1D3D29) : const Color(0xFFEBF4E8);
    final borderColor = isDark ? const Color(0xFF264A34) : const Color(0xFFDFE8DC);
    final isToday = _selectedDayIndex == (DateTime.now().weekday % 7);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_fullDayNames[_selectedDayIndex].toUpperCase()} SCHEDULE',
                style: GoogleFonts.quicksand(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              if (isToday) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: primaryLight,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Text(
                    'TODAY',
                    style: GoogleFonts.quicksand(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: primaryAccent,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: primaryLight,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Text(
              '$count ${count == 1 ? 'Class' : 'Classes'}',
              style: GoogleFonts.quicksand(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: primaryAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSproutSlotCard({
    required BuildContext context,
    required TimetableSlotItem s,
    required bool isDark,
    required AppThemeTokens? tokens,
  }) {
    final cardBg = isDark ? const Color(0xFF183122) : Colors.white;
    final borderColor = isDark ? const Color(0xFF264A34) : const Color(0xFFDFE8DC);
    final textPrimary = isDark ? const Color(0xFFE8F4EB) : const Color(0xFF192E21);
    final textSecondary = isDark ? const Color(0xFF98B5A3) : const Color(0xFF526B5C);
    final textMuted = isDark ? const Color(0xFF648671) : const Color(0xFF849E8E);
    final chipBg = isDark ? const Color(0xFF1E3D2A) : const Color(0xFFF1F6EE);
    final timeBadgeBg = isDark ? const Color(0xFF1D3A28) : const Color(0xFFEFF5EC);
    final primaryAccent = tokens?.primaryAccent ?? const Color(0xFF558A50);
    final primaryLight = isDark ? const Color(0xFF1D3D29) : const Color(0xFFEBF4E8);

    Color dotColor;
    try {
      final hex = s.colorHex.replaceAll('#', '');
      dotColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      dotColor = primaryAccent;
    }

    final durationStr = _formatDuration(s.startTime, s.endTime);

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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditSlotScreen(
                existingSlot: sessionEntity,
                initialDayOfWeek: s.dayOfWeek,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black26 : const Color(0x12558A50),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left Time Column
              SizedBox(
                width: 64,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      s.startTime,
                      style: GoogleFonts.quicksand(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      s.endTime,
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textMuted,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: timeBadgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        durationStr,
                        style: GoogleFonts.quicksand(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: primaryAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Container(
                width: 1.5,
                height: 48,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                color: borderColor,
              ),

              // Right Subject Info Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + Dot Indicator
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.subjectName,
                            style: GoogleFonts.quicksand(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: cardBg, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: borderColor,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),

                    // Tag Chips Row
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (s.componentType.isNotEmpty)
                          _buildSproutTag(
                            label: s.componentType,
                            bgColor: chipBg,
                            textColor: textSecondary,
                            borderColor: borderColor,
                          ),
                        if (s.category.isNotEmpty)
                          _buildSproutTag(
                            label: s.category,
                            bgColor: chipBg,
                            textColor: textSecondary,
                            borderColor: borderColor,
                          ),
                        if (s.room != null && s.room!.isNotEmpty)
                          _buildSproutTag(
                            label: s.room!.toLowerCase().contains('room') ||
                                    s.room!.toLowerCase().contains('lab')
                                ? s.room!
                                : 'Room ${s.room}',
                            icon: Icons.location_on_rounded,
                            bgColor: primaryLight,
                            textColor: primaryAccent,
                            borderColor: borderColor,
                            isHighlight: true,
                          ),
                      ],
                    ),

                    // Teacher Row
                    if (s.teacherName != null && s.teacherName!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.person_rounded,
                            size: 13,
                            color: textMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              s.teacherName!,
                              style: GoogleFonts.quicksand(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSproutTag({
    required String label,
    required Color bgColor,
    required Color textColor,
    required Color borderColor,
    IconData? icon,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.quicksand(
              fontSize: 11,
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSproutEmptyState({
    required BuildContext context,
    required bool isDark,
    required AppThemeTokens? tokens,
    required bool isNoSemester,
  }) {
    final cardBg = isDark ? const Color(0xFF183122) : Colors.white;
    final borderColor = isDark ? const Color(0xFF264A34) : const Color(0xFFDFE8DC);
    final textPrimary = isDark ? const Color(0xFFE8F4EB) : const Color(0xFF192E21);
    final textSecondary = isDark ? const Color(0xFF98B5A3) : const Color(0xFF526B5C);
    final primaryAccent = tokens?.primaryAccent ?? const Color(0xFF558A50);
    final primaryLight = isDark ? const Color(0xFF1D3D29) : const Color(0xFFEBF4E8);

    final title = isNoSemester ? 'No Active Semester' : 'Rest & Recharge Day';
    final desc = isNoSemester
        ? 'Create your semester to start building and tracking your weekly timetable schedule.'
        : 'No classes scheduled for ${_fullDayNames[_selectedDayIndex]}. A peaceful day to water your habits, review notes, or plan ahead!';
    final btnLabel = isNoSemester ? 'Create Semester' : 'Add Class Slot';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : const Color(0x12558A50),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isNoSemester)
              Image.asset(
                'assets/themes/sprout/mascots/sprout_timetable_clock.png',
                width: 88,
                height: 88,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.spa_rounded,
                  size: 34,
                  color: primaryAccent,
                ),
              )
            else
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryLight,
                  boxShadow: [
                    BoxShadow(
                      color: primaryAccent.withValues(alpha: 0.15),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.school_rounded,
                  size: 34,
                  color: primaryAccent,
                ),
              ),
            const SizedBox(height: 18),
            Text(
              title,
              style: GoogleFonts.quicksand(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: GoogleFonts.quicksand(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                if (isNoSemester) {
                  showDialog(
                    context: context,
                    builder: (context) => const EditSemesterDialog(),
                  );
                } else {
                  final activeSem = ref.read(activeSemesterProvider);
                  if (activeSem.isUnset) {
                    _promptSemesterRequired(context);
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditSlotScreen(
                        initialDayOfWeek: _dayValues[_selectedDayIndex],
                      ),
                    ),
                  );
                }
              },
              icon: Icon(isNoSemester ? Icons.add_rounded : Icons.add_rounded, size: 18),
              label: Text(
                btnLabel,
                style: GoogleFonts.quicksand(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: primaryAccent.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSproutBottomSpeechFooter({
    required BuildContext context,
    required bool isDark,
    required AppThemeTokens? tokens,
    required List<TimetableSlotItem> daySlots,
  }) {
    const mascotPath = 'assets/themes/sprout/mascots/sprout_timetable_clock.png';

    final speechBg = isDark ? const Color(0xFF1B3626) : const Color(0xFFFAF7F0);
    final speechBorder = isDark ? const Color(0xFF285038) : const Color(0xFFEBE4D7);
    final textPrimary = isDark ? const Color(0xFFE8F4EB) : const Color(0xFF192E21);
    final textSecondary = isDark ? const Color(0xFF98B5A3) : const Color(0xFF526B5C);

    final count = daySlots.length;
    final lastSlot = daySlots.isNotEmpty ? daySlots.last : null;
    final String lastEndTime;
    if (lastSlot != null && lastSlot.endTime.isNotEmpty) {
      lastEndTime = 'Ends at ${lastSlot.endTime}';
    } else {
      lastEndTime = 'Plan ahead for tomorrow';
    }

    final dayName = _fullDayNames[_selectedDayIndex];

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Timekeeper Sprout holding clock
          Image.asset(
            mascotPath,
            width: 106,
            height: 96,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox(width: 106, height: 96),
          ),
          const SizedBox(width: 8),
          // Conversational Speech Bubble
          Expanded(
            child: CustomPaint(
              painter: _SproutSpeechBubblePainter(
                color: speechBg,
                borderColor: speechBorder,
                borderWidth: 1.0,
                radius: 18.0,
                tailWidth: 8.0,
                tailHeight: 14.0,
                tailY: 42.0,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'A consistent you builds a brighter future!',
                      style: GoogleFonts.quicksand(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.2,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count ${count == 1 ? 'class' : 'classes'} for $dayName · $lastEndTime',
                      style: GoogleFonts.quicksand(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(String start, String end) {
    try {
      final sParts = start.split(':');
      final eParts = end.split(':');
      if (sParts.length == 2 && eParts.length == 2) {
        final sMin = int.parse(sParts[0]) * 60 + int.parse(sParts[1]);
        final eMin = int.parse(eParts[0]) * 60 + int.parse(eParts[1]);
        final diff = eMin - sMin;
        if (diff > 0) {
          final hours = diff ~/ 60;
          final mins = diff % 60;
          if (hours > 0 && mins > 0) return '${hours}h ${mins}m';
          if (hours > 0) return '${hours}h';
          return '${mins}m';
        }
      }
    } catch (_) {}
    return 'Slot';
  }
}

class _SproutSpeechBubblePainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final double radius;
  final double tailWidth;
  final double tailHeight;
  final double tailY;

  _SproutSpeechBubblePainter({
    required this.color,
    required this.borderColor,
    this.borderWidth = 1.0,
    this.radius = 18.0,
    this.tailWidth = 8.0,
    this.tailHeight = 14.0,
    this.tailY = 34.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rectLeft = tailWidth;
    final rectRight = size.width;
    final rectTop = 0.0;
    final rectBottom = size.height;

    final path = Path();
    path.moveTo(rectLeft + radius, rectTop);
    path.lineTo(rectRight - radius, rectTop);
    path.arcToPoint(Offset(rectRight, rectTop + radius), radius: Radius.circular(radius));
    path.lineTo(rectRight, rectBottom - radius);
    path.arcToPoint(Offset(rectRight - radius, rectBottom), radius: Radius.circular(radius));
    path.lineTo(rectLeft + radius, rectBottom);
    path.arcToPoint(Offset(rectLeft, rectBottom - radius), radius: Radius.circular(radius));

    // Left tail pointing towards Sprout
    path.lineTo(rectLeft, tailY + tailHeight / 2);
    path.lineTo(0, tailY);
    path.lineTo(rectLeft, tailY - tailHeight / 2);
    path.lineTo(rectLeft, rectTop + radius);
    path.arcToPoint(Offset(rectLeft + radius, rectTop), radius: Radius.circular(radius));
    path.close();

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    if (borderWidth > 0) {
      final strokePaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth;
      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SproutSpeechBubblePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.borderWidth != borderWidth;
}
