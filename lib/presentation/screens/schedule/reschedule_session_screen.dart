import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/ui/app_toast.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/class_session_entity.dart';
import '../../providers/app_state_provider.dart';

class RescheduleSessionScreen extends ConsumerStatefulWidget {
  final ClassSessionEntity session;
  final String dateIso;

  const RescheduleSessionScreen({
    super.key,
    required this.session,
    required this.dateIso,
  });

  @override
  ConsumerState<RescheduleSessionScreen> createState() => _RescheduleSessionScreenState();
}

class _RescheduleSessionScreenState extends ConsumerState<RescheduleSessionScreen> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late TextEditingController _roomController;
  bool _isSaving = false;

  late String _initialStartTimeStr;
  late String _initialEndTimeStr;
  late String _initialRoom;

  @override
  void initState() {
    super.initState();
    _startTime = const TimeOfDay(hour: 9, minute: 0);
    _endTime = const TimeOfDay(hour: 10, minute: 0);

    try {
      final s = widget.session.startTime.split(':');
      _startTime = TimeOfDay(hour: int.parse(s[0]), minute: int.parse(s[1]));
      final e = widget.session.endTime.split(':');
      _endTime = TimeOfDay(hour: int.parse(e[0]), minute: int.parse(e[1]));
    } catch (_) {}

    _initialStartTimeStr = _formatTime(_startTime);
    _initialEndTimeStr = _formatTime(_endTime);
    _initialRoom = (widget.session.room ?? '').trim();

    _roomController = TextEditingController(text: widget.session.room ?? '');
    _roomController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  bool get _hasChanges {
    if (_formatTime(_startTime) != _initialStartTimeStr) return true;
    if (_formatTime(_endTime) != _initialEndTimeStr) return true;
    if (_roomController.text.trim() != _initialRoom) return true;
    return false;
  }

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _saveChanges() async {
    if (widget.session.sourceRefId == null) {
      AppToast.error(context, 'Missing underlying timetable slot ID.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final startStr = _formatTime(_startTime);
      final endStr = _formatTime(_endTime);

      final initialRoom = (widget.session.room ?? '').trim();
      final enteredRoom = _roomController.text.trim();
      final String? roomParam = enteredRoom.isNotEmpty
          ? enteredRoom
          : (initialRoom.isNotEmpty ? "" : null);

      await ref.read(scheduleExceptionsProvider.notifier).addOrUpdateException(
        timetableSlotId: widget.session.sourceRefId!,
        exceptionDate: widget.dateIso,
        actionType: 'MOVED',
        newStartTime: startStr,
        newEndTime: endStr,
        newRoom: roomParam,
      );

      if (mounted) {
        Navigator.pop(context);
        AppToast.success(context, 'Updated schedule for ${widget.dateIso}');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to save changes: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _resetToDefault() async {
    if (widget.session.sourceRefId == null) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(scheduleExceptionsProvider.notifier).removeException(
        widget.session.sourceRefId!,
        widget.dateIso,
      );
      if (mounted) {
        Navigator.pop(context);
        AppToast.info(context, 'Reset to weekly timetable schedule');
      }
    } catch (e) {
      if (mounted) AppToast.error(context, 'Error resetting: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color subjectColor;
    try {
      final hex = widget.session.colorHex.replaceAll('#', '');
      subjectColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      subjectColor = isDark ? AppColors.accentIndigoDark : AppColors.accentIndigoLight;
    }

    final formattedDate = DateFormatter.formatHeaderDate(DateTime.tryParse(widget.dateIso) ?? DateTime.now());

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
              'Reschedule Session',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            Text(
              formattedDate,
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Summary Card
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
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: subjectColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.edit_calendar_rounded,
                          color: subjectColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.session.subjectName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Original: ${DateFormatter.formatTime12h(widget.session.startTime)} - ${DateFormatter.formatTime12h(widget.session.endTime)}  •  ${widget.session.componentType}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Date Isolation Notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 16, color: isDark ? AppColors.accentIndigoDark : AppColors.accentIndigoLight),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Changes made here apply ONLY to this date (${widget.dateIso}). Your recurring weekly timetable remains unchanged.',
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.35,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Time Selection Section
                Text(
                  'SESSION TIME',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickStartTime,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start Time',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(_startTime),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _pickEndTime,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'End Time',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(_endTime),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Room Selection Section
                Text(
                  'ROOM / LAB LOCATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _roomController,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. Room 302, Physics Lab B, Audi-1',
                    hintStyle: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.normal,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                    prefixIcon: Icon(
                      Icons.meeting_room_outlined,
                      size: 18,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    suffixIcon: _roomController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            onPressed: () => setState(() => _roomController.clear()),
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? AppColors.cardDark : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Save Action Button
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
                    onPressed: (_hasChanges && !_isSaving) ? _saveChanges : null,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                // Reset to default button
                Center(
                  child: TextButton.icon(
                    onPressed: _isSaving ? null : _resetToDefault,
                    icon: const Icon(Icons.restore_rounded, size: 16),
                    label: const Text('Reset to Weekly Schedule Default'),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
