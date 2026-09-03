import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
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
    });
    AppToast.info(context, 'Applied to all ${slots.length} slots below. Tap Save to commit.');
  }

  Future<void> _saveAllRooms(List<TimetableSlotItem> slots) async {
    setState(() => _isSaving = true);
    final db = ref.read(databaseProvider);
    final activeSem = ref.read(activeSemesterProvider);

    try {
      final dbSlots = await db.getTimetableSlots(activeSem.id);
      final dbSlotMap = {for (final s in dbSlots) s.id: s};

      for (final slot in slots) {
        final dbSlot = dbSlotMap[slot.id];
        if (dbSlot == null) continue;
        final c = _slotControllers[slot.id];
        final newRoom = c != null ? c.text.trim() : (slot.room ?? '');
        final updated = dbSlot.copyWith(
          room: drift.Value(newRoom.isNotEmpty ? newRoom : null),
          updatedAt: DateTime.now().toIso8601String(),
        );
        await db.saveTimetableSlot(updated);
      }

      await ref.read(timetableSlotsProvider.notifier).loadFromDb();

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
                                    '$dayName • ${DateFormatter.formatTime12h(slot.startTime)} - ${DateFormatter.formatTime12h(slot.endTime)}',
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
}
