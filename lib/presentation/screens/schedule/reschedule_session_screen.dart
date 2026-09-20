import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_theme_tokens.dart';
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

      if (widget.session.sessionSource == 'EXTRA') {
        await ref.read(extraClassesProvider.notifier).updateExtraClass(
          id: widget.session.sourceRefId!,
          subjectId: widget.session.subjectComponentId,
          classDate: widget.dateIso,
          startTime: startStr,
          endTime: endStr,
          room: enteredRoom.isNotEmpty ? enteredRoom : null,
          teacherName: widget.session.teacherName,
        );
      } else {
        await ref.read(scheduleExceptionsProvider.notifier).addOrUpdateException(
          timetableSlotId: widget.session.sourceRefId!,
          exceptionDate: widget.dateIso,
          actionType: 'MOVED',
          newStartTime: startStr,
          newEndTime: endStr,
          newRoom: roomParam,
        );
      }

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
      if (widget.session.sessionSource == 'EXTRA') {
        await ref.read(extraClassesProvider.notifier).deleteExtraClass(
          widget.session.sourceRefId!,
        );
        if (mounted) {
          Navigator.pop(context);
          AppToast.info(context, 'Extra class removed');
        }
      } else {
        await ref.read(scheduleExceptionsProvider.notifier).removeException(
          widget.session.sourceRefId!,
          widget.dateIso,
        );
        if (mounted) {
          Navigator.pop(context);
          AppToast.info(context, 'Reset to weekly timetable schedule');
        }
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
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final isCute = tokens?.isCute ?? false;

    if (isCute) {
      return _buildSproutRescheduleScreen(context, isDark, subjectColor, formattedDate);
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
                    icon: Icon(
                      widget.session.sessionSource == 'EXTRA'
                          ? Icons.delete_outline_rounded
                          : Icons.restore_rounded,
                      size: 16,
                      color: widget.session.sessionSource == 'EXTRA' ? AppColors.absentRed : null,
                    ),
                    label: Text(
                      widget.session.sessionSource == 'EXTRA'
                          ? 'Delete Extra Class'
                          : 'Reset to Weekly Schedule Default',
                      style: TextStyle(
                        color: widget.session.sessionSource == 'EXTRA' ? AppColors.absentRed : null,
                      ),
                    ),
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

  Widget _buildSproutRescheduleScreen(
    BuildContext context,
    bool isDark,
    Color subjectColor,
    String formattedDate,
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

    // Calculate duration
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    final durationMinutes = endMinutes > startMinutes ? endMinutes - startMinutes : (endMinutes + 24 * 60) - startMinutes;
    final durationHours = durationMinutes ~/ 60;
    final durationRemainingMins = durationMinutes % 60;
    final durationString = durationHours > 0
        ? (durationRemainingMins > 0 ? '${durationHours}h ${durationRemainingMins}m' : '${durationHours}h')
        : '${durationRemainingMins}m';

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
            Text(
              'Reschedule Session',
              style: GoogleFonts.quicksand(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              formattedDate,
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: borderColor, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: subjectColor.withValues(alpha: isDark ? 0.25 : 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: subjectColor.withValues(alpha: 0.3), width: 1.0),
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.school_rounded, color: subjectColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.session.subjectName,
                              style: GoogleFonts.quicksand(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Originally: ${DateFormatter.formatTime12h(widget.session.startTime)} – ${DateFormatter.formatTime12h(widget.session.endTime)}  •  ${widget.session.room?.isNotEmpty == true ? widget.session.room : "No room"}',
                              style: GoogleFonts.quicksand(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.session.subjectCode != null && widget.session.subjectCode!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: pillBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.session.subjectCode!,
                            style: GoogleFonts.quicksand(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: primaryAccent,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Scope Callout
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: pillBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 16, color: primaryAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Affects only today\'s session • Weekly timetable remains intact',
                          style: GoogleFonts.quicksand(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: primaryAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // New Time Cards
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: borderColor, width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'NEW CLASS TIME',
                            style: GoogleFonts.quicksand(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: textMuted,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: pillBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              durationString,
                              style: GoogleFonts.quicksand(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: primaryAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _pickStartTime,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'START TIME',
                                      style: GoogleFonts.quicksand(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: textMuted,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      DateFormatter.formatTime12h(_formatTime(_startTime)),
                                      style: GoogleFonts.quicksand(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: _pickEndTime,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'END TIME',
                                      style: GoogleFonts.quicksand(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: textMuted,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      DateFormatter.formatTime12h(_formatTime(_endTime)),
                                      style: GoogleFonts.quicksand(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Location / Room Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: borderColor, width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ROOM / LOCATION (OPTIONAL)',
                        style: GoogleFonts.quicksand(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _roomController,
                        style: GoogleFonts.quicksand(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. Seminar Hall B, Lab 2',
                          hintStyle: GoogleFonts.quicksand(fontSize: 13, color: textMuted),
                          filled: true,
                          fillColor: bg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: primaryAccent, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Primary CTA: Save Rescheduled Time
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
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
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Save Rescheduled Time',
                                  style: GoogleFonts.quicksand(fontSize: 14.5, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 12),

                // Reset Action Button
                Center(
                  child: TextButton.icon(
                    onPressed: _isSaving ? null : _resetToDefault,
                    icon: Icon(
                      widget.session.sessionSource == 'EXTRA' ? Icons.delete_outline_rounded : Icons.restore_rounded,
                      size: 16,
                      color: widget.session.sessionSource == 'EXTRA' ? dangerColor : textSecondary,
                    ),
                    label: Text(
                      widget.session.sessionSource == 'EXTRA'
                          ? 'Delete Extra Class'
                          : 'Reset to Weekly Timetable Schedule',
                      style: GoogleFonts.quicksand(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: widget.session.sessionSource == 'EXTRA' ? dangerColor : textSecondary,
                      ),
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
