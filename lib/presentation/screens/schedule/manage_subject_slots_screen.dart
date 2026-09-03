import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
}
