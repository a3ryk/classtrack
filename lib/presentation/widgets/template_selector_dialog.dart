import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme_tokens.dart';
import '../../core/ui/app_toast.dart';
import '../../data/templates/programme_templates.dart';
import '../../domain/entities/academic_template.dart';
import '../providers/app_state_provider.dart';

/// Modern Modal Bottom Sheet for Degree / Course Structure Templates
class TemplateSelectorSheet extends ConsumerWidget {
  const TemplateSelectorSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TemplateSelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentTemplate = ref.watch(activeTemplateProvider);
    final templates = ProgrammeTemplates.getAllTemplates();

    if (tokens?.isCute == true) {
      return _buildSproutTemplateSheet(
        context,
        ref,
        tokens!,
        isDark,
        currentTemplate,
        templates,
      );
    }
    return _buildClassicTemplateSheet(
      context,
      ref,
      isDark,
      currentTemplate,
      templates,
    );
  }

  Widget _buildClassicTemplateSheet(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    ProgrammeTemplate currentTemplate,
    List<ProgrammeTemplate> templates,
  ) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
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

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Degree Curriculum Structure',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
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
          const SizedBox(height: 4),
          Text(
            'Select academic template governing your semester courses',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 16),

          // Templates list + Not Selected option
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                // "None / Not Selected" Option
                InkWell(
                  onTap: () {
                    ref.read(activeTemplateProvider.notifier).clearTemplate();
                    Navigator.pop(context);
                    AppToast.info(context, 'Curriculum structure set to Not Selected');
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: currentTemplate.id == 'none'
                          ? (isDark ? AppColors.cardDark : Colors.white)
                          : (isDark ? AppColors.pillDark : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: currentTemplate.id == 'none'
                            ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                            : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                        width: currentTemplate.id == 'none' ? 1.4 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Not Selected',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'No specific academic structure preset (standard manual schedule management)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (currentTemplate.id == 'none')
                          const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.presentGreen),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                ...templates.map((t) {
                  final bool isSelected = t.id == currentTemplate.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
                        ref.read(activeTemplateProvider.notifier).selectTemplate(t);
                        Navigator.pop(context);
                        AppToast.success(context, 'Set curriculum structure: ${t.name}');
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? AppColors.cardDark : Colors.white)
                              : (isDark ? AppColors.pillDark : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                            width: isSelected ? 1.4 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    t.description,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.presentGreen),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSproutTemplateSheet(
    BuildContext context,
    WidgetRef ref,
    AppThemeTokens tokens,
    bool isDark,
    ProgrammeTemplate currentTemplate,
    List<ProgrammeTemplate> templates,
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

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Curriculum Structure',
                  style: GoogleFonts.quicksand(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: tokens.textPrimary,
                    letterSpacing: -0.3,
                  ),
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
          const SizedBox(height: 2),
          Text(
            'Select academic template governing your semester courses',
            style: GoogleFonts.quicksand(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Templates list + Not Selected option
          Flexible(
            child: ListView(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              children: [
                // "None / Not Selected" Option
                InkWell(
                  onTap: () {
                    ref.read(activeTemplateProvider.notifier).clearTemplate();
                    Navigator.pop(context);
                    AppToast.info(context, 'Curriculum structure set to Not Selected');
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: currentTemplate.id == 'none'
                          ? (isDark ? const Color(0xFF234631) : const Color(0xFFEDF5E9))
                          : (isDark ? const Color(0xFF203F2C) : const Color(0xFFF8FAF5)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: currentTemplate.id == 'none' ? tokens.primaryAccent : cardBorder,
                        width: currentTemplate.id == 'none' ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Not Selected',
                                style: GoogleFonts.quicksand(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: tokens.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'No specific academic structure preset (standard manual schedule management)',
                                style: GoogleFonts.quicksand(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: tokens.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (currentTemplate.id == 'none')
                          Icon(Icons.check_circle_rounded, size: 18, color: tokens.primaryAccent),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                ...templates.map((t) {
                  final bool isSelected = t.id == currentTemplate.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
                        ref.read(activeTemplateProvider.notifier).selectTemplate(t);
                        Navigator.pop(context);
                        AppToast.success(context, 'Set curriculum structure: ${t.name}');
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? const Color(0xFF234631) : const Color(0xFFEDF5E9))
                              : (isDark ? const Color(0xFF203F2C) : const Color(0xFFF8FAF5)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? tokens.primaryAccent : cardBorder,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.name,
                                    style: GoogleFonts.quicksand(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: tokens.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    t.description,
                                    style: GoogleFonts.quicksand(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: tokens.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle_rounded, size: 18, color: tokens.primaryAccent),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Backward compatibility alias
typedef TemplateSelectorDialog = TemplateSelectorSheet;
