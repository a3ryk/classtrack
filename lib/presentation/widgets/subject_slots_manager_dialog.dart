import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/ui/app_toast.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/subject_entity.dart';
import '../providers/app_state_provider.dart';

class SubjectSlotsManagerDialog extends ConsumerStatefulWidget {
  final SubjectEntity subject;

  const SubjectSlotsManagerDialog({
    super.key,
    required this.subject,
  });

  @override
  ConsumerState<SubjectSlotsManagerDialog> createState() => _SubjectSlotsManagerDialogState();
}

class _SubjectSlotsManagerDialogState extends ConsumerState<SubjectSlotsManagerDialog> {
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

  Future<void> _applyBulkEdit() async {
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
      AppToast.success(context, 'Updated all slots for ${widget.subject.name}');
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.absentRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(timetableSlotsProvider.notifier).deleteSlotsForSubject(widget.subject.id);
      if (mounted) {
        Navigator.pop(context);
        AppToast.info(context, 'Removed all schedule slots for ${widget.subject.name}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allSlots = ref.watch(timetableSlotsProvider);
    final subjectSlots = allSlots.where((s) => s.subjectComponentId == widget.subject.id).toList()
      ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));

    return Dialog(
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.subject.name,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manage Weekly Schedule (${subjectSlots.length} slot${subjectSlots.length == 1 ? "" : "s"})',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isBulkEditing) ...[
              // BULK EDIT FORM
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'APPLY TO ALL ${subjectSlots.length} SLOTS:',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                        color: isDark ? AppColors.accentIndigoDark : AppColors.accentIndigoLight,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickBulkStartTime,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.cardDark : Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                              ),
                              child: Text('Start: ${_formatTime(_bulkStartTime)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: _pickBulkEndTime,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.cardDark : Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                              ),
                              child: Text('End: ${_formatTime(_bulkEndTime)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _bulkRoomController,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Room / Lab (e.g. Lab 204)',
                        filled: true,
                        fillColor: isDark ? AppColors.cardDark : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0))),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: ['LECTURE', 'PRACTICAL', 'TUTORIAL', 'SEMINAR'].map((type) {
                        final isSel = _bulkComponentType == type;
                        return ChoiceChip(
                          label: Text(type, style: TextStyle(fontSize: 10, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                          selected: isSel,
                          onSelected: (val) {
                            if (val) setState(() => _bulkComponentType = type);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => setState(() => _isBulkEditing = false),
                          child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 6),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            foregroundColor: isDark ? AppColors.bgDark : AppColors.surfaceLight,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          onPressed: _applyBulkEdit,
                          child: const Text('Apply to All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Slots List
            if (subjectSlots.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No timetable slots configured for this subject.',
                    style: TextStyle(fontSize: 13, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: subjectSlots.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final slot = subjectSlots[index];
                    final dayName = slot.dayOfWeek >= 1 && slot.dayOfWeek <= 7
                        ? _dayNames[slot.dayOfWeek - 1]
                        : 'Day ${slot.dayOfWeek}';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.pillDark : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              dayName.substring(0, 3).toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${DateFormatter.formatTime12h(slot.startTime)} – ${DateFormatter.formatTime12h(slot.endTime)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                ),
                                Text(
                                  [
                                    slot.componentType,
                                    if (slot.room != null && slot.room!.isNotEmpty) 'Room ${slot.room}',
                                  ].join(' • '),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.absentRed),
                            onPressed: () async {
                              await ref.read(timetableSlotsProvider.notifier).deleteSlot(slot.id);
                              if (context.mounted) {
                                AppToast.info(context, 'Deleted $dayName slot');
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),

            // Actions Bottom Bar
            if (subjectSlots.isNotEmpty)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                      label: Text(_isBulkEditing ? 'Close Edit' : 'Bulk Edit All', style: const TextStyle(fontSize: 12)),
                      onPressed: () => setState(() => _isBulkEditing = !_isBulkEditing),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF4C0519) : const Color(0xFFFEE2E2),
                        foregroundColor: AppColors.absentRed,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                      label: const Text('Delete All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: _confirmDeleteAllSlots,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
