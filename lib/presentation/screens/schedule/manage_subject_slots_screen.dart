import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_theme_tokens.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/ui/app_toast.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/class_session_entity.dart';
import '../../../domain/entities/subject_entity.dart';
import '../../../domain/services/schedule_engine.dart';
import '../../providers/app_state_provider.dart';
import 'add_edit_slot_screen.dart';

class ManageSubjectSlotsScreen extends ConsumerStatefulWidget {
  final SubjectEntity subject;

  const ManageSubjectSlotsScreen({
    super.key,
    required this.subject,
  });

  @override
  ConsumerState<ManageSubjectSlotsScreen> createState() => _ManageSubjectSlotsScreenState();
}

class _ManageSubjectSlotsScreenState extends ConsumerState<ManageSubjectSlotsScreen> {
  bool _isBulkEditing = false;
  late TimeOfDay _bulkStartTime;
  late TimeOfDay _bulkEndTime;
  final _bulkRoomController = TextEditingController();
  final _bulkTeacherController = TextEditingController();
  String _bulkComponentType = 'LECTURE';

  static const List<String> _dayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _bulkStartTime = const TimeOfDay(hour: 9, minute: 0);
    _bulkEndTime = const TimeOfDay(hour: 10, minute: 0);
  }

  @override
  void dispose() {
    _bulkRoomController.dispose();
    _bulkTeacherController.dispose();
    super.dispose();
  }

  Future<void> _pickBulkStartTime() async {
    final picked = await showTimePicker(context: context, initialTime: _bulkStartTime);
    if (picked != null) setState(() => _bulkStartTime = picked);
  }

  Future<void> _pickBulkEndTime() async {
    final picked = await showTimePicker(context: context, initialTime: _bulkEndTime);
    if (picked != null) setState(() => _bulkEndTime = picked);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final min = time.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }

  Future<void> _applyBulkEdit(int slotsCount) async {
    if (slotsCount == 0) {
      AppToast.info(context, 'No slots available to update.');
      return;
    }

    final startStr = _formatTime(_bulkStartTime);
    final endStr = _formatTime(_bulkEndTime);

    await ref.read(timetableSlotsProvider.notifier).updateSlotsForSubject(
      subjectId: widget.subject.id,
      newStartTime: startStr,
      newEndTime: endStr,
      newRoom: _bulkRoomController.text.trim().isNotEmpty ? _bulkRoomController.text.trim() : null,
      newTeacher: _bulkTeacherController.text.trim().isNotEmpty ? _bulkTeacherController.text.trim() : null,
      newComponentType: _bulkComponentType,
    );

    if (mounted) {
      setState(() => _isBulkEditing = false);
      AppToast.success(context, 'Updated all $slotsCount slots for ${widget.subject.name}');
    }
  }

  Future<void> _confirmDeleteAllSlots() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete All Weekly Slots?'),
        content: Text(
          'This will remove all timetable schedule slots for "${widget.subject.name}". Existing marked attendance records will be preserved.',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.absentRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete All', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(timetableSlotsProvider.notifier).deleteSlotsForSubject(widget.subject.id);
      if (mounted) {
        AppToast.info(context, 'Removed all schedule slots for ${widget.subject.name}');
      }
    }
  }

  Future<void> _deleteSingleSlot(TimetableSlotItem slot) async {
    final dayName = (slot.dayOfWeek >= 1 && slot.dayOfWeek <= 7) ? _dayNames[slot.dayOfWeek - 1] : 'Day ${slot.dayOfWeek}';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete Slot?'),
        content: Text(
          'Remove $dayName slot (${DateFormatter.formatTime12h(slot.startTime)} - ${DateFormatter.formatTime12h(slot.endTime)}) for "${widget.subject.name}"?',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.absentRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(timetableSlotsProvider.notifier).deleteSlot(slot.id);
      if (mounted) {
        AppToast.info(context, 'Removed $dayName slot');
      }
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
      return _buildSproutManageSubjectSlotsScreen(context, isDark, subjectSlots, subjectColor);
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
            Text(
              widget.subject.name,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Weekly Schedule Manager',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        actions: [
          if (subjectSlots.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, size: 22, color: AppColors.absentRed),
              tooltip: 'Delete All Slots',
              onPressed: _confirmDeleteAllSlots,
            ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        foregroundColor: isDark ? AppColors.bgDark : Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Add Slot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (ctx) => const AddEditSlotScreen(initialDayOfWeek: 1)),
          );
        },
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          // 1. Subject Header Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: subjectColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.pillDark : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.subject.category.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Target: ${widget.subject.targetAttendancePct.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${subjectSlots.length} weekly class${subjectSlots.length == 1 ? "" : "es"} scheduled',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isBulkEditing ? Icons.close_rounded : Icons.auto_fix_high_rounded,
                    color: _isBulkEditing
                        ? AppColors.absentRed
                        : (isDark ? AppColors.accentIndigoDark : AppColors.accentIndigoLight),
                    size: 20,
                  ),
                  tooltip: _isBulkEditing ? 'Cancel Bulk Edit' : 'Bulk Edit All Slots',
                  onPressed: () => setState(() => _isBulkEditing = !_isBulkEditing),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Bulk Edit Section (Expandable)
          if (_isBulkEditing) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                  width: 0.9,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'BATCH UPDATE ALL ${subjectSlots.length} SLOTS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: isDark ? AppColors.accentIndigoDark : AppColors.accentIndigoLight,
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(() => _isBulkEditing = false),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _pickBulkStartTime,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.cardDark : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Start Time', style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                                Text(_formatTime(_bulkStartTime), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: _pickBulkEndTime,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.cardDark : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('End Time', style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                                Text(_formatTime(_bulkEndTime), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _bulkRoomController,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Room / Lab (e.g. Lab 204)',
                      hintStyle: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.normal,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.cardDark : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0))),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _bulkTeacherController,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Instructor / Faculty Name (Optional)',
                      hintStyle: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.normal,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.cardDark : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0))),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: ['LECTURE', 'PRACTICAL', 'TUTORIAL', 'SEMINAR'].map((type) {
                      final isSel = _bulkComponentType == type;
                      return ChoiceChip(
                        label: Text(type, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSel ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
                        selected: isSel,
                        selectedColor: isDark ? AppColors.accentIndigoDark : AppColors.accentIndigoLight,
                        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
                        onSelected: (_) => setState(() => _bulkComponentType = type),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        foregroundColor: isDark ? AppColors.bgDark : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _applyBulkEdit(subjectSlots.length),
                      child: Text('Apply to All ${subjectSlots.length} Slots', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 3. Section Title
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'WEEKLY SCHEDULE (${subjectSlots.length})',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                if (!_isBulkEditing && subjectSlots.isNotEmpty)
                  InkWell(
                    onTap: () => setState(() => _isBulkEditing = true),
                    child: Text(
                      'Bulk Edit',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.accentIndigoDark : AppColors.accentIndigoLight,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 4. Slots List / Empty State
          if (subjectSlots.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                  width: 0.8,
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_note_outlined,
                    size: 38,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No Weekly Slots Configured',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add slots to set the days and times "${widget.subject.name}" takes place.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (ctx) => const AddEditSlotScreen(initialDayOfWeek: 1)),
                      );
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add First Slot'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      foregroundColor: isDark ? AppColors.bgDark : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            )
          else
            ...List.generate(subjectSlots.length, (index) {
              final slot = subjectSlots[index];
              final dayName = (slot.dayOfWeek >= 1 && slot.dayOfWeek <= 7) ? _dayNames[slot.dayOfWeek - 1] : 'Day ${slot.dayOfWeek}';

              final sessionEntity = ClassSessionEntity(
                id: slot.id,
                semesterId: slot.semesterId,
                sourceRefId: slot.id,
                subjectComponentId: slot.subjectComponentId,
                subjectName: slot.subjectName,
                category: slot.category,
                startTime: slot.startTime,
                endTime: slot.endTime,
                room: slot.room,
                teacherName: slot.teacherName,
                componentType: slot.componentType,
                colorHex: slot.colorHex,
                dayOfWeek: slot.dayOfWeek,
                sessionDate: '',
                sessionSource: 'TIMETABLE_RECURRING',
                status: 'PLANNED',
                attendanceOutcome: 'PENDING',
              );

              final String roomLabel = (slot.room != null && slot.room!.isNotEmpty)
                  ? (slot.room!.toLowerCase().contains("room") || slot.room!.toLowerCase().contains("lab")
                      ? slot.room!
                      : 'Room ${slot.room}')
                  : '';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    // Day Badge
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                          width: 0.7,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        dayName.substring(0, 3).toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Time & Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$dayName - ${DateFormatter.formatTime12h(slot.startTime)} - ${DateFormatter.formatTime12h(slot.endTime)}',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
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
                              if (roomLabel.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '- $roomLabel',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                              if (slot.teacherName != null && slot.teacherName!.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '- ${slot.teacherName!}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Actions
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 19),
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      tooltip: 'Edit Slot',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => AddEditSlotScreen(
                              existingSlot: sessionEntity,
                              initialDayOfWeek: slot.dayOfWeek,
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 19, color: AppColors.absentRed),
                      tooltip: 'Delete Slot',
                      onPressed: () => _deleteSingleSlot(slot),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSproutManageSubjectSlotsScreen(
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
    final dangerColor = isDark ? const Color(0xFFFF8A80) : const Color(0xFFD32F2F);
    final dangerBg = isDark ? const Color(0xFF381A1A) : const Color(0xFFFFEBEE);
    final dangerBorder = isDark ? const Color(0xFF5C2626) : const Color(0xFFFFCDD2);

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
              '${subjectSlots.length} Weekly Slots · Schedule Manager',
              style: GoogleFonts.quicksand(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          if (subjectSlots.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: InkWell(
                  onTap: _confirmDeleteAllSlots,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: dangerBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: dangerBorder, width: 1.2),
                    ),
                    child: Icon(Icons.delete_sweep_rounded, size: 18, color: dangerColor),
                  ),
                ),
              ),
            ),
        ],
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
                          child: Icon(Icons.calendar_month_rounded, size: 28, color: primaryAccent),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'No Weekly Slots Yet',
                          style: GoogleFonts.quicksand(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add class slots to populate the weekly schedule for this subject.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.quicksand(
                            fontSize: 12.5,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddEditSlotScreen(initialDayOfWeek: 1),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: Text(
                            'Add Slot',
                            style: GoogleFonts.quicksand(fontSize: 13.5, fontWeight: FontWeight.w800),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
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
                      // Bulk Edit Toggle Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              '${subjectSlots.length} RECURRING SLOTS',
                              style: GoogleFonts.quicksand(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => setState(() => _isBulkEditing = !_isBulkEditing),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: pillBg,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: borderColor),
                              ),
                              child: Text(
                                _isBulkEditing ? '✕ Close Bulk' : '+ Bulk Edit All',
                                style: GoogleFonts.quicksand(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: primaryAccent,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Collapsible Bulk Edit Panel
                      if (_isBulkEditing) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
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
                                'BULK UPDATE ALL SLOTS',
                                style: GoogleFonts.quicksand(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: textMuted,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: _pickBulkStartTime,
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: bg,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: borderColor),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'START TIME',
                                              style: GoogleFonts.quicksand(fontSize: 9.5, fontWeight: FontWeight.w800, color: textMuted),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              DateFormatter.formatTime12h(_formatTime(_bulkStartTime)),
                                              style: GoogleFonts.quicksand(fontSize: 13, fontWeight: FontWeight.w800, color: textPrimary),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: InkWell(
                                      onTap: _pickBulkEndTime,
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: bg,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: borderColor),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'END TIME',
                                              style: GoogleFonts.quicksand(fontSize: 9.5, fontWeight: FontWeight.w800, color: textMuted),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              DateFormatter.formatTime12h(_formatTime(_bulkEndTime)),
                                              style: GoogleFonts.quicksand(fontSize: 13, fontWeight: FontWeight.w800, color: textPrimary),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _bulkRoomController,
                                style: GoogleFonts.quicksand(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
                                decoration: InputDecoration(
                                  hintText: 'Room (optional)',
                                  hintStyle: GoogleFonts.quicksand(fontSize: 12, color: textMuted),
                                  filled: true,
                                  fillColor: bg,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primaryAccent, width: 1.4)),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => _applyBulkEdit(subjectSlots.length),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryAccent,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 44),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Apply to All ${subjectSlots.length} Slots',
                                  style: GoogleFonts.quicksand(fontSize: 13, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Weekly Slots Cards
                      ...subjectSlots.map((slot) {
                        final dayName = (slot.dayOfWeek >= 1 && slot.dayOfWeek <= 7) ? _dayNames[slot.dayOfWeek - 1] : 'Day ${slot.dayOfWeek}';
                        final timeStr = '${DateFormatter.formatTime12h(slot.startTime)} – ${DateFormatter.formatTime12h(slot.endTime)}';

                        final sessionEntity = ClassSessionEntity(
                          id: slot.id,
                          sourceRefId: slot.id,
                          semesterId: slot.semesterId,
                          subjectComponentId: slot.subjectComponentId,
                          subjectName: slot.subjectName,
                          subjectCode: slot.subjectCode,
                          category: slot.category,
                          startTime: slot.startTime,
                          endTime: slot.endTime,
                          room: slot.room,
                          teacherName: slot.teacherName,
                          colorHex: slot.colorHex,
                          dayOfWeek: slot.dayOfWeek,
                          componentType: slot.componentType,
                          sessionDate: '',
                          sessionSource: 'TIMETABLE_RECURRING',
                          status: 'PLANNED',
                          attendanceOutcome: 'PENDING',
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderColor, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Day Capsule
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: pillBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: borderColor),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  dayName.substring(0, 3).toUpperCase(),
                                  style: GoogleFonts.quicksand(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: primaryAccent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Info Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      timeStr,
                                      style: GoogleFonts.quicksand(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: pillBg,
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
                                        if (slot.room != null && slot.room!.isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            '•  ${slot.room!}',
                                            style: GoogleFonts.quicksand(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: textSecondary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Action Squircles (Edit & Delete)
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (ctx) => AddEditSlotScreen(
                                        existingSlot: sessionEntity,
                                        initialDayOfWeek: slot.dayOfWeek,
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: bg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Icon(Icons.edit_rounded, size: 15, color: textSecondary),
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => _deleteSingleSlot(slot),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: dangerBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: dangerBorder),
                                  ),
                                  child: Icon(Icons.delete_outline_rounded, size: 15, color: dangerColor),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),

                      // Add Slot Button
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddEditSlotScreen(initialDayOfWeek: 1),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(
                          'Add Weekly Slot',
                          style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryAccent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
