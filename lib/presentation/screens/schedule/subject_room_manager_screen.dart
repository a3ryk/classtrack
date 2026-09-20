import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_theme_tokens.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/ui/app_toast.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/subject_entity.dart';
import '../../../domain/services/schedule_engine.dart';
import '../../providers/app_state_provider.dart';

class SubjectRoomManagerScreen extends ConsumerStatefulWidget {
  final SubjectEntity subject;
  final String? initialRoom;

  const SubjectRoomManagerScreen({
    super.key,
    required this.subject,
    this.initialRoom,
  });

  @override
  ConsumerState<SubjectRoomManagerScreen> createState() => _SubjectRoomManagerScreenState();
}

class _SubjectRoomManagerScreenState extends ConsumerState<SubjectRoomManagerScreen> {
  final _bulkRoomController = TextEditingController();
  final Map<String, TextEditingController> _slotControllers = {};
  bool _isSaving = false;

  static const List<String> _dayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _bulkRoomController.text = widget.initialRoom ?? '';
    _bulkRoomController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _bulkRoomController.dispose();
    for (final c in _slotControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool _hasChanges(List<TimetableSlotItem> subjectSlots) {
    final bulkText = _bulkRoomController.text.trim();
    final initialBulk = (widget.initialRoom ?? '').trim();
    if (bulkText.isNotEmpty && bulkText != initialBulk) return true;

    for (final slot in subjectSlots) {
      final initial = (slot.room ?? '').trim();
      final current = _slotControllers[slot.id]?.text.trim() ?? '';
      if (initial != current) return true;
    }
    return false;
  }

  void _applyBulkRoomToAll(List<TimetableSlotItem> slots) {
    final text = _bulkRoomController.text.trim();
    setState(() {
      for (final slot in slots) {
        if (!_slotControllers.containsKey(slot.id)) {
          final c = TextEditingController(text: text);
          c.addListener(() {
            if (mounted) setState(() {});
          });
          _slotControllers[slot.id] = c;
        } else {
          _slotControllers[slot.id]!.text = text;
        }
      }
      _bulkRoomController.clear();
    });
    FocusScope.of(context).unfocus();
    AppToast.info(context, 'Applied to all ${slots.length} slots below. Tap Save to commit.');
  }

  Future<void> _saveAllRooms(List<TimetableSlotItem> slots) async {
    setState(() => _isSaving = true);

    try {
      final bulkText = _bulkRoomController.text.trim();
      final Map<String, String?> updates = {};

      for (final slot in slots) {
        final c = _slotControllers[slot.id];
        String roomValue;
        if (c != null && c.text.trim().isNotEmpty) {
          roomValue = c.text.trim();
        } else if (bulkText.isNotEmpty) {
          roomValue = bulkText;
        } else {
          roomValue = (c != null) ? c.text.trim() : (slot.room ?? '').trim();
        }
        updates[slot.id] = roomValue.isNotEmpty ? roomValue : null;
      }

      await ref.read(timetableSlotsProvider.notifier).updateSlotRooms(updates);
      ref.invalidate(resolvedDayScheduleProvider);

      if (mounted) {
        Navigator.pop(context);
        AppToast.success(context, 'Updated rooms for ${widget.subject.name}');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to save rooms: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allSlots = ref.watch(timetableSlotsProvider);
    final subjectSlots = allSlots.where((s) => s.subjectComponentId == widget.subject.id).toList()
      ..sort((a, b) {
        final dayComp = a.dayOfWeek.compareTo(b.dayOfWeek);
        if (dayComp != 0) return dayComp;
        return a.startTime.compareTo(b.startTime);
      });

    // Ensure controllers exist for all slots
    for (final slot in subjectSlots) {
      if (!_slotControllers.containsKey(slot.id)) {
        final c = TextEditingController(text: slot.room ?? '');
        c.addListener(() {
          if (mounted) setState(() {});
        });
        _slotControllers[slot.id] = c;
      }
    }

    Color subjectColor;
    try {
      final hex = widget.subject.colorHex.replaceAll('#', '');
      subjectColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      subjectColor = isDark ? AppColors.accentIndigoDark : AppColors.accentIndigoLight;
    }
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final isCute = tokens?.isCute ?? false;

    if (isCute) {
      return _buildSproutRoomManagerScreen(context, isDark, subjectSlots, subjectColor);
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: subjectColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    widget.subject.name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              'Room & Location Manager',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
      body: RepaintBoundary(
        child: SafeArea(
          child: subjectSlots.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.meeting_room_outlined, size: 48, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                      const SizedBox(height: 12),
                      Text(
                        'No Weekly Slots Found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Add timetable slots for "${widget.subject.name}" to manage classroom rooms.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Bulk Update Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                          width: 0.9,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.auto_fix_high_rounded, size: 18, color: isDark ? AppColors.accentIndigoDark : AppColors.accentIndigoLight),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'QUICK APPLY TO ALL ${subjectSlots.length} DAYS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: isDark ? AppColors.accentIndigoDark : AppColors.accentIndigoLight,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'If this entire subject is held in the same classroom, enter it here and tap Apply.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _bulkRoomController,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'e.g. Room 405 or Lecture Hall A',
                                    hintStyle: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.normal,
                                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                    ),
                                    isDense: true,
                                    filled: true,
                                    fillColor: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? AppColors.accentIndigoDark : AppColors.accentIndigoLight,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: isDark ? const Color(0xFF1E2028) : const Color(0xFFE2E8F0),
                                  disabledForegroundColor: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                                onPressed: _bulkRoomController.text.trim().isNotEmpty
                                    ? () => _applyBulkRoomToAll(subjectSlots)
                                    : null,
                                child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Day-by-Day Slot List
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'DAILY CLASSROOM ROOMS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${subjectSlots.length} slots',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    ...List.generate(subjectSlots.length, (index) {
                      final slot = subjectSlots[index];
                      final dayName = (slot.dayOfWeek >= 1 && slot.dayOfWeek <= 7)
                          ? _dayNames[slot.dayOfWeek - 1]
                          : 'Day ${slot.dayOfWeek}';
                      final controller = _slotControllers[slot.id]!;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                            width: 0.8,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Day Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    dayName.substring(0, 3).toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(
                                      '${DateFormatter.formatTime12h(slot.startTime)} – ${DateFormatter.formatTime12h(slot.endTime)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.pillDark : const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    slot.componentType,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.accentIndigoDark : AppColors.accentIndigoLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: controller,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Classroom / Lab (e.g. Room 101, Lab B)',
                                hintStyle: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.normal,
                                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                ),
                                isDense: true,
                                prefixIcon: const Icon(Icons.meeting_room_outlined, size: 16),
                                suffixIcon: controller.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded, size: 14),
                                        onPressed: () => setState(() => controller.clear()),
                                      )
                                    : null,
                                filled: true,
                                fillColor: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          foregroundColor: isDark ? AppColors.bgDark : Colors.white,
                          disabledBackgroundColor: isDark ? const Color(0xFF1E2028) : const Color(0xFFE2E8F0),
                          disabledForegroundColor: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: (_hasChanges(subjectSlots) && !_isSaving)
                            ? () => _saveAllRooms(subjectSlots)
                            : null,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'Save Room Changes',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildSproutRoomManagerScreen(
    BuildContext context,
    bool isDark,
    List<TimetableSlotItem> subjectSlots,
    Color subjectColor,
  ) {
    final bg = isDark ? const Color(0xFF112318) : const Color(0xFFFAF7F2);
    final cardBg = isDark ? const Color(0xFF183122) : Colors.white;
    final borderColor = isDark ? const Color(0xFF264A34) : const Color(0xFFDFE8DC);
    final textPrimary = isDark ? const Color(0xFFE8F4EB) : const Color(0xFF192E21);
    final textSecondary = isDark ? const Color(0xFF98B5A3) : const Color(0xFF526B5C);
    final textMuted = isDark ? const Color(0xFF648671) : const Color(0xFF849E8E);
    final primaryAccent = isDark ? const Color(0xFF6FA769) : const Color(0xFF558A50);
    final pillBg = isDark ? const Color(0xFF1E3D2A) : const Color(0xFFEFF5EC);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 54,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A3725) : const Color(0xFFF1F6EF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 1.2),
                ),
                child: Icon(Icons.arrow_back_rounded, size: 18, color: primaryAccent),
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: subjectColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    widget.subject.name,
                    style: GoogleFonts.quicksand(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              'Manage Rooms · ${subjectSlots.length} Weekly Slots',
              style: GoogleFonts.quicksand(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: RepaintBoundary(
        child: SafeArea(
          child: subjectSlots.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: pillBg,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(Icons.meeting_room_outlined, size: 28, color: primaryAccent),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'No Weekly Slots Found',
                          style: GoogleFonts.quicksand(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add schedule slots in Timetable first before assigning rooms.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.quicksand(
                            fontSize: 12.5,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bulk Room Assignment Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: borderColor, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BULK ROOM ASSIGNMENT',
                              style: GoogleFonts.quicksand(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Quickly apply one room to all ${subjectSlots.length} weekly slots.',
                              style: GoogleFonts.quicksand(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _bulkRoomController,
                                    style: GoogleFonts.quicksand(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'e.g. Lab 102, Hall B',
                                      hintStyle: GoogleFonts.quicksand(fontSize: 12.5, color: textMuted),
                                      filled: true,
                                      fillColor: bg,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primaryAccent, width: 1.5)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _bulkRoomController.text.trim().isNotEmpty
                                      ? () => _applyBulkRoomToAll(subjectSlots)
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryAccent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'Apply All',
                                    style: GoogleFonts.quicksand(fontSize: 12.5, fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Individual Slots Header
                      Text(
                        'INDIVIDUAL SLOT ROOMS',
                        style: GoogleFonts.quicksand(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Slot Room Cards
                      ...subjectSlots.map((slot) {
                        final dayName = _dayNames[(slot.dayOfWeek - 1).clamp(0, 6)];
                        final controller = _slotControllers[slot.id];
                        final timeRange = '${DateFormatter.formatTime12h(slot.startTime)} – ${DateFormatter.formatTime12h(slot.endTime)}';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: pillBg,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      dayName,
                                      style: GoogleFonts.quicksand(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: primaryAccent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      timeRange,
                                      style: GoogleFonts.quicksand(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (slot.componentType.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1D3D29) : const Color(0xFFEFF5EC),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        slot.componentType,
                                        style: GoogleFonts.quicksand(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: primaryAccent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: controller,
                                style: GoogleFonts.quicksand(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Enter room for $dayName slot',
                                  hintStyle: GoogleFonts.quicksand(fontSize: 12.5, color: textMuted),
                                  filled: true,
                                  fillColor: bg,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryAccent, width: 1.4)),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),

                      // Primary CTA: Save Room Changes
                      ElevatedButton(
                        onPressed: (_hasChanges(subjectSlots) && !_isSaving)
                            ? () => _saveAllRooms(subjectSlots)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryAccent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: isDark ? const Color(0xFF1E3D2A).withValues(alpha: 0.5) : const Color(0xFFDFE8DC),
                          disabledForegroundColor: textMuted,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_rounded, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Save Room Changes',
                                    style: GoogleFonts.quicksand(fontSize: 14.5, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
