import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme_tokens.dart';
import '../../core/ui/app_toast.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/semester_entity.dart';
import '../providers/app_state_provider.dart';
import 'archived_semester_report_sheet.dart';
import 'edit_semester_dialog.dart';
import 'semester_transition_wizard.dart';

/// Modern Modal Bottom Sheet for Academic History & Semesters
class SemesterHistorySheet extends ConsumerWidget {
  const SemesterHistorySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SemesterHistorySheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeSemester = ref.watch(activeSemesterProvider);
    final allSemesters = ref.watch(semestersListProvider);

    if (tokens?.isCute == true) {
      return _buildSproutSemesterHistorySheet(
        context,
        ref,
        tokens!,
        isDark,
        activeSemester,
        allSemesters,
      );
    }
    return _buildClassicSemesterHistorySheet(
      context,
      ref,
      isDark,
      activeSemester,
      allSemesters,
    );
  }

  Widget _buildClassicSemesterHistorySheet(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    SemesterEntity activeSemester,
    List<SemesterEntity> allSemesters,
  ) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Academic History',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Select active term to view or edit details',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, size: 20, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Scrollable Semesters List
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: allSemesters.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final sem = allSemesters[index];
                final isActive = sem.id == activeSemester.id || sem.name == activeSemester.name;

                return Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.pillDark : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isActive
                          ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                          : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                      width: isActive ? 1.2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Left Content (Tap to view report card or edit)
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            if (isActive) {
                              showDialog(
                                context: context,
                                builder: (context) => EditSemesterDialog(semesterToEdit: sem),
                              );
                            } else {
                              ArchivedSemesterReportSheet.show(context, sem);
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    sem.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isActive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.presentContainerDark : AppColors.presentContainerLight,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'ACTIVE',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: isDark ? AppColors.presentGreenDark : AppColors.presentGreenText,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.pillDark : const Color(0xFFE2E8F0),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'ARCHIVED',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${sem.termType.displayName} · ${DateFormatter.formatDateIndian(sem.startDate)} to ${sem.endDate != null ? DateFormatter.formatDateIndian(sem.endDate!) : "Continuous"}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Right Actions (Edit / Report Card & Delete)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isActive)
                            IconButton(
                              icon: Icon(
                                Icons.edit_outlined,
                                size: 17,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                              tooltip: 'Edit Term',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => EditSemesterDialog(semesterToEdit: sem),
                                );
                              },
                            )
                          else
                            IconButton(
                              icon: Icon(
                                Icons.bar_chart_rounded,
                                size: 18,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                              tooltip: 'Final Report Card',
                              onPressed: () => ArchivedSemesterReportSheet.show(context, sem),
                            ),
                          if (allSemesters.length > 1)
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                size: 17,
                                color: isDark ? AppColors.absentRedDark : AppColors.absentRed,
                              ),
                              tooltip: 'Delete Term',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                                    surfaceTintColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    title: const Text('Delete Term?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    content: Text('Are you sure you want to remove "${sem.name}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isDark ? AppColors.absentRedDark : AppColors.absentRed,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          ref.read(semestersListProvider.notifier).deleteSemester(sem.id);
                                          if (isActive) {
                                            final remaining = ref.read(semestersListProvider);
                                            if (remaining.isNotEmpty) {
                                              ref.read(activeSemesterProvider.notifier).updateSemester(remaining.first);
                                            }
                                          }
                                          AppToast.info(context, 'Deleted "${sem.name}"');
                                        },
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Actions Row: Transition Wizard (Primary) & Manual Setup
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.auto_awesome_rounded, size: 15),
                    label: const Text('Start Next Term', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      foregroundColor: isDark ? AppColors.bgDark : AppColors.surfaceLight,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      SemesterTransitionWizard.show(context);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 15),
                    label: const Text('Blank Term', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      side: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const EditSemesterDialog(),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSproutSemesterHistorySheet(
    BuildContext context,
    WidgetRef ref,
    AppThemeTokens tokens,
    bool isDark,
    SemesterEntity activeSemester,
    List<SemesterEntity> allSemesters,
  ) {
    final sheetBg = isDark ? const Color(0xFF193223) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF284F37) : const Color(0xFFE4ECE0);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: cardBorder, width: 1.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF284F37) : const Color(0xFFD4DEC7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Academic History',
                      style: GoogleFonts.quicksand(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: tokens.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Select active term to view or edit details',
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, size: 20, color: tokens.textSecondary),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Scrollable Semesters List
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: allSemesters.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final sem = allSemesters[index];
                final isActive = sem.id == activeSemester.id || sem.name == activeSemester.name;

                return Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? (isDark ? const Color(0xFF234631) : const Color(0xFFEDF5E9))
                        : (isDark ? const Color(0xFF203F2C) : const Color(0xFFF8FAF5)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive ? tokens.primaryAccent : cardBorder,
                      width: isActive ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Left Content (Tap to view report card or edit)
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            if (isActive) {
                              showDialog(
                                context: context,
                                builder: (context) => EditSemesterDialog(semesterToEdit: sem),
                              );
                            } else {
                              ArchivedSemesterReportSheet.show(context, sem);
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      sem.name,
                                      style: GoogleFonts.quicksand(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: tokens.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isActive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: tokens.primaryAccent,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'ACTIVE',
                                        style: GoogleFonts.quicksand(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: isDark ? const Color(0xFF102016) : Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF203D2B) : const Color(0xFFF0F4EC),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'ARCHIVED',
                                        style: GoogleFonts.quicksand(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: tokens.textSecondary,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${sem.termType.displayName} · ${DateFormatter.formatDateIndian(sem.startDate)} to ${sem.endDate != null ? DateFormatter.formatDateIndian(sem.endDate!) : "Continuous"}',
                                style: GoogleFonts.quicksand(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: tokens.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Right Actions (Edit / Report Card & Delete)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isActive)
                            IconButton(
                              icon: Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: tokens.textSecondary,
                              ),
                              tooltip: 'Edit Term',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => EditSemesterDialog(semesterToEdit: sem),
                                );
                              },
                            )
                          else
                            IconButton(
                              icon: Icon(
                                Icons.bar_chart_rounded,
                                size: 19,
                                color: tokens.textSecondary,
                              ),
                              tooltip: 'Final Report Card',
                              onPressed: () => ArchivedSemesterReportSheet.show(context, sem),
                            ),
                          if (allSemesters.length > 1)
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: isDark ? const Color(0xFFEF6A66) : const Color(0xFFD9534F),
                              ),
                              tooltip: 'Delete Term',
                              onPressed: () => _showSproutDeleteDialog(context, ref, sem, isActive, tokens, isDark),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Actions Row: Transition Wizard (Primary) & Manual Setup
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: Text(
                      'Start Next Term',
                      style: GoogleFonts.quicksand(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tokens.primaryAccent,
                      foregroundColor: isDark ? const Color(0xFF102016) : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      SemesterTransitionWizard.show(context);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(
                      'Blank Term',
                      style: GoogleFonts.quicksand(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: tokens.textPrimary,
                      side: BorderSide(color: cardBorder, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const EditSemesterDialog(),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSproutDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    SemesterEntity sem,
    bool isActive,
    AppThemeTokens tokens,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF193223) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: isDark ? const Color(0xFF284F37) : const Color(0xFFE4ECE0)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF381E1E) : const Color(0xFFFDF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: isDark ? const Color(0xFFEF6A66) : const Color(0xFFD9534F),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Delete Term?',
                style: GoogleFonts.quicksand(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: tokens.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${sem.name}"? Timetable and logs for this term will be unlinked.',
          style: GoogleFonts.quicksand(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: tokens.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.quicksand(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: tokens.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFFEF6A66) : const Color(0xFFD9534F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(semestersListProvider.notifier).deleteSemester(sem.id);
              if (isActive) {
                final remaining = ref.read(semestersListProvider);
                if (remaining.isNotEmpty) {
                  ref.read(activeSemesterProvider.notifier).updateSemester(remaining.first);
                }
              }
              AppToast.info(context, 'Deleted "${sem.name}"');
            },
            child: Text(
              'Delete',
              style: GoogleFonts.quicksand(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Backward compatibility alias
typedef SemesterHistoryDialog = SemesterHistorySheet;
