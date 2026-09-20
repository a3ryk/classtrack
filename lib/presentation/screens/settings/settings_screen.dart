import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme_tokens.dart';
import '../../../core/theme/app_theme_registry.dart';
import '../../../core/ui/app_toast.dart';
import '../../providers/app_theme_style_provider.dart';
import '../../../domain/entities/academic_template.dart';
import '../../../domain/entities/attendance_stats.dart';
import '../../../domain/entities/semester_entity.dart';
import '../../../domain/entities/subject_entity.dart';
import '../../../domain/entities/user_profile_entity.dart';
import '../../../domain/services/export_service.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/app_update_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/target_percentage_dialog.dart';
import '../profile/profile_screen.dart';
import 'about_screen.dart';
import 'appearance_screen.dart';
import 'backup_restore_screen.dart';
import 'developer_tools_screen.dart';
import 'notification_settings_screen.dart';
import '../main_shell.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final isCute = tokens?.isCute ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isCute && tokens != null) {
      return _buildSproutSettingsView(context, tokens, isDark);
    }
    return _buildClassicSettingsView(context, isDark);
  }

  Widget _buildClassicSettingsView(BuildContext context, bool isDark) {
    final userProfile = ref.watch(userProfileProvider);
    final userUni = ref.watch(selectedUniversityProvider);
    final activeSemester = ref.watch(activeSemesterProvider);
    final targetPct = ref.watch(targetPercentageProvider);
    final overallStats = ref.watch(overallStatsProvider);
    final activeTemplate = ref.watch(activeTemplateProvider);
    final betaMode = ref.watch(betaFeaturesEnabledProvider);
    final developerMode = ref.watch(developerModeEnabledProvider);
    final isDeveloperUnlocked = ref.watch(isDeveloperUnlockedProvider);
    final updateState = ref.watch(appUpdateProvider);
    final currentThemeMode = ref.watch(themeModeProvider);
    final themeStyle = ref.watch(appThemeStyleProvider);
    final themeDef = AppThemeRegistry.getTheme(themeStyle);
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final isCute = tokens?.isCute ?? false;
    final cardRadius = isCute ? 20.0 : 12.0;

    final String initials = userProfile.studentName.trim().isNotEmpty
        ? userProfile.studentName.trim().split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join()
        : 'ST';

    final Color groupBg = isDark ? AppColors.cardDark : Colors.white;
    final Color groupBorder = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final Color dividerColor = isDark ? AppColors.borderDark.withValues(alpha: 0.6) : const Color(0xFFF1F5F9);

    final bool showBackButton = Navigator.canPop(context);
    final Color scaffoldBg = isCute
        ? (tokens?.scaffoldBg ?? (isDark ? const Color(0xFF14291D) : const Color(0xFFFAF7F2)))
        : (isDark ? AppColors.bgDark : const Color(0xFFF8FAFC));

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: showBackButton ? 100 : 0,
        leading: showBackButton
            ? InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(8),
                child: const Row(
                  children: [
                    SizedBox(width: 16),
                    Icon(Icons.chevron_left_rounded, size: 22, color: AppColors.accentBlue),
                    Text(
                      'Back',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentBlue,
                      ),
                    ),
                  ],
                ),
              )
            : null,
        title: Text(
          'Settings',
          style: isCute
              ? GoogleFonts.quicksand(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: tokens?.textPrimary ?? (isDark ? const Color(0xFFF4F8F3) : const Color(0xFF1E3526)),
                )
              : TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. ACCOUNT / PROFILE
          _buildSectionHeader('Account', isDark),
          RepaintBoundary(
            child: Container(
              decoration: BoxDecoration(
                color: groupBg,
                borderRadius: BorderRadius.circular(cardRadius),
                border: Border.all(color: groupBorder, width: 0.8),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    );
                  },
                borderRadius: BorderRadius.circular(cardRadius),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isCute
                              ? (isDark ? const Color(0xFF1B382B) : const Color(0xFFE8F5E9))
                              : (isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A)),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isCute ? const Color(0xFF7CB342) : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userProfile.studentName.isNotEmpty ? userProfile.studentName : 'Student Profile',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userProfile.degreeProgramme.isNotEmpty
                                  ? userProfile.degreeProgramme + (userProfile.rollNumber.isNotEmpty ? ' • ${userProfile.rollNumber}' : '')
                                  : (userUni.universityName.isNotEmpty
                                      ? userUni.universityName
                                      : 'Tap to configure student identity'),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

          // 2. GENERAL PREFERENCES
          _buildSectionHeader('Preferences', isDark),
          RepaintBoundary(
            child: Container(
              decoration: BoxDecoration(
                color: groupBg,
                borderRadius: BorderRadius.circular(cardRadius),
                border: Border.all(color: groupBorder, width: 0.8),
              ),
              child: Column(
                children: [
                  _buildTile(
                    leading: _buildCuteLeading(Icons.palette_rounded, const Color(0xFF7CB342), isDark, isCute),
                    title: 'Appearance & Themes',
                    subtitle: isCute
                        ? '${currentThemeMode == ThemeMode.system ? "System" : (currentThemeMode == ThemeMode.dark ? "Dark" : "Light")} · ${themeDef.title}'
                        : null,
                    isDark: isDark,
                    trailing: _buildChevronValue(
                      currentThemeMode == ThemeMode.system
                          ? 'System'
                          : (currentThemeMode == ThemeMode.dark ? 'Dark' : 'Light'),
                      isDark,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AppearanceScreen()),
                      );
                    },
                  ),

                  Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                  _buildTile(
                    leading: _buildCuteLeading(Icons.notifications_active_rounded, const Color(0xFFF59E0B), isDark, isCute),
                    title: 'Notifications',
                    isDark: isDark,
                    trailing: _buildChevronIcon(isDark),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
                      );
                    },
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                  _buildTile(
                    leading: _buildCuteLeading(Icons.track_changes_rounded, const Color(0xFF8B5CF6), isDark, isCute),
                    title: 'Attendance Target',
                    isDark: isDark,
                    trailing: _buildChevronValue('${targetPct.toStringAsFixed(1)}%', isDark),
                    onTap: () => TargetPercentageSheet.show(context),
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                  _buildTile(
                    leading: _buildCuteLeading(Icons.file_upload_rounded, const Color(0xFF10B981), isDark, isCute),
                    title: 'Export Attendance Report',
                    isDark: isDark,
                    trailing: _buildChevronIcon(isDark),
                    onTap: () => _showExportSheet(context, overallStats, activeSemester, userProfile, userUni, activeTemplate, isDark),
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                  _buildTile(
                    leading: _buildCuteLeading(Icons.cloud_sync_rounded, const Color(0xFF3B82F6), isDark, isCute),
                    title: 'Backup & Restore',
                    isDark: isDark,
                    trailing: _buildChevronIcon(isDark),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BackupRestoreScreen()),
                      );
                    },
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                  _buildTile(
                    leading: _buildCuteLeading(Icons.translate_rounded, const Color(0xFF6366F1), isDark, isCute),
                    title: 'Language',
                    isDark: isDark,
                    trailing: _buildChevronValue('English', isDark),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 4. EXPERIMENTAL & DEVELOPER
          _buildSectionHeader('Developer & Experimental', isDark),
          RepaintBoundary(
            child: Container(
              decoration: BoxDecoration(
                color: groupBg,
                borderRadius: BorderRadius.circular(cardRadius),
                border: Border.all(color: groupBorder, width: 0.8),
              ),
              child: Column(
                children: [
                  _buildTile(
                    leading: _buildCuteLeading(Icons.science_rounded, const Color(0xFFEC4899), isDark, isCute),
                    title: 'Beta Features',
                    subtitle: 'Early access to experimental features',
                    isDark: isDark,
                    trailing: Switch(
                      value: betaMode,
                      activeThumbColor: AppColors.presentGreen,
                      onChanged: (val) {
                        ref.read(betaFeaturesEnabledProvider.notifier).toggle(val);
                        AppToast.info(context, 'Beta features ${val ? "enabled" : "disabled"}');
                      },
                    ),
                  ),
                  if (isDeveloperUnlocked) ...[
                    Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                    _buildTile(
                      leading: _buildCuteLeading(Icons.developer_mode_rounded, const Color(0xFF14B8A6), isDark, isCute),
                      title: 'Developer Options',
                      subtitle: 'Advanced database & testing tools',
                      isDark: isDark,
                      trailing: Switch(
                        value: developerMode,
                        activeThumbColor: AppColors.presentGreen,
                        onChanged: (val) {
                          ref.read(developerModeEnabledProvider.notifier).toggle(val);
                        },
                      ),
                    ),
                    if (developerMode) ...[
                      Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                      _buildTile(
                        leading: _buildCuteLeading(Icons.terminal_rounded, const Color(0xFFF97316), isDark, isCute),
                        title: 'Developer Tools',
                        subtitle: 'Testing utilities, scenario simulators & diagnostics',
                        isDark: isDark,
                        trailing: _buildChevronIcon(isDark),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const DeveloperToolsScreen()),
                          );
                        },
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 5. SUPPORT & ABOUT
          _buildSectionHeader('Support & About', isDark),
          RepaintBoundary(
            child: Container(
              decoration: BoxDecoration(
                color: groupBg,
                borderRadius: BorderRadius.circular(cardRadius),
                border: Border.all(color: groupBorder, width: 0.8),
              ),
              child: Column(
                children: [
                  _buildTile(
                    leading: _buildCuteLeading(Icons.explore_rounded, const Color(0xFF06B6D4), isDark, isCute),
                    title: 'Take Guided App Tour',
                    subtitle: 'Replay the interactive app walkthrough',
                    isDark: isDark,
                    trailing: _buildChevronIcon(isDark),
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.of(context).pop();
                      }
                      ref.read(activeTourProvider.notifier).state = true;
                    },
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                  _buildTile(
                    leading: _buildCuteLeading(Icons.spa_rounded, const Color(0xFF7CB342), isDark, isCute),
                    title: 'About',
                    subtitle: 'Version ${updateState.currentVersion}, updates, links & legal',
                    isDark: isDark,
                    trailing: _buildChevronIcon(isDark),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AboutScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSproutSettingsView(
    BuildContext context,
    AppThemeTokens tokens,
    bool isDark,
  ) {
    final userProfile = ref.watch(userProfileProvider);
    final userUni = ref.watch(selectedUniversityProvider);
    final activeSemester = ref.watch(activeSemesterProvider);
    final targetPct = ref.watch(targetPercentageProvider);
    final overallStats = ref.watch(overallStatsProvider);
    final activeTemplate = ref.watch(activeTemplateProvider);
    final betaMode = ref.watch(betaFeaturesEnabledProvider);
    final developerMode = ref.watch(developerModeEnabledProvider);
    final isDeveloperUnlocked = ref.watch(isDeveloperUnlockedProvider);
    final updateState = ref.watch(appUpdateProvider);
    final currentThemeMode = ref.watch(themeModeProvider);
    final themeStyle = ref.watch(appThemeStyleProvider);
    final themeDef = AppThemeRegistry.getTheme(themeStyle);

    final String initials = userProfile.studentName.trim().isNotEmpty
        ? userProfile.studentName.trim().split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join()
        : 'ST';

    final Color cardBg = isDark ? const Color(0xFF1B3626) : Colors.white;
    final Color cardBorder = isDark ? const Color(0xFF274C37) : const Color(0xFFE4ECE0);
    final Color dividerColor = isDark ? const Color(0xFF274C37) : const Color(0xFFF0ECE1);
    final Color scaffoldBg = tokens.scaffoldBg;

    final bool isInMainShell = context.findAncestorWidgetOfExactType<MainShell>() != null;
    final bool canPopRoute = !isInMainShell && Navigator.canPop(context);

    return PopScope(
      canPop: !canPopRoute,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ref.read(mainShellTabProvider.notifier).state = 4;
        Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: canPopRoute
            ? AppBar(
                backgroundColor: scaffoldBg,
                elevation: 0,
                scrolledUnderElevation: 0,
                automaticallyImplyLeading: false,
                leadingWidth: 100,
                leading: InkWell(
                  onTap: () {
                    ref.read(mainShellTabProvider.notifier).state = 4;
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 14),
                      Icon(Icons.chevron_left_rounded, size: 22, color: tokens.primaryAccent),
                      Text(
                        'Back',
                        style: GoogleFonts.quicksand(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: tokens.primaryAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
        body: SafeArea(
          top: !canPopRoute,
          bottom: false,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            children: [
              _buildSproutHeader(tokens, themeDef),
              const SizedBox(height: 14),
              // 1. STUDENT IDENTITY HERO CARD
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cardBorder, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF163424) : const Color(0xFFEAF8E7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF2E593E) : const Color(0xFFD7F0D6),
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials,
                          style: GoogleFonts.quicksand(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? const Color(0xFF8BC34A) : const Color(0xFF1E6B3F),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    userProfile.studentName.isNotEmpty ? userProfile.studentName : 'Student Profile',
                                    style: GoogleFonts.quicksand(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w800,
                                      color: tokens.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!activeSemester.isUnset) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF164130) : const Color(0xFFEAF8E7),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF2C5B45) : const Color(0xFFD7F0D6),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Text(
                                      activeSemester.name,
                                      style: GoogleFonts.quicksand(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? const Color(0xFFEAF8EA) : const Color(0xFF1E6B3F),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userProfile.degreeProgramme.isNotEmpty
                                  ? userProfile.degreeProgramme + (userProfile.rollNumber.isNotEmpty ? ' • ${userProfile.rollNumber}' : '')
                                  : (userUni.universityName.isNotEmpty
                                      ? userUni.universityName
                                      : 'Tap to configure student identity'),
                              style: GoogleFonts.quicksand(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: tokens.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  userUni.universityName.isNotEmpty ? userUni.universityName : 'My University',
                                  style: GoogleFonts.quicksand(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: tokens.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(width: 6),
                                Text('•', style: TextStyle(fontSize: 10, color: tokens.textMuted)),
                                const SizedBox(width: 6),
                                Text(
                                  'Edit Profile ›',
                                  style: GoogleFonts.quicksand(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: tokens.primaryAccent,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. PREFERENCES (No emoji in heading)
          _buildSproutSectionHeader('Preferences', tokens),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cardBorder, width: 1.0),
            ),
            child: Column(
              children: [
                _buildSproutTile(
                  icon: Icons.palette_rounded,
                  iconBg: isDark ? const Color(0xFF163424) : const Color(0xFFEAF8E7),
                  iconColor: isDark ? const Color(0xFF8BC34A) : const Color(0xFF2E7D32),
                  title: 'Appearance & Themes',
                  subtitle: '${currentThemeMode == ThemeMode.system ? "System" : (currentThemeMode == ThemeMode.dark ? "Dark" : "Light")} · ${themeDef.title}',
                  tokens: tokens,
                  isDark: isDark,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentThemeMode == ThemeMode.system
                            ? 'System'
                            : (currentThemeMode == ThemeMode.dark ? 'Dark' : 'Light'),
                        style: GoogleFonts.quicksand(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: tokens.primaryAccent,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, size: 18, color: tokens.textMuted),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AppearanceScreen()),
                    );
                  },
                ),
                Divider(height: 1, indent: 56, endIndent: 16, color: dividerColor),
                _buildSproutTile(
                  icon: Icons.track_changes_rounded,
                  iconBg: isDark ? const Color(0xFF3B2D12) : const Color(0xFFFEF3C7),
                  iconColor: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                  title: 'Attendance Target',
                  subtitle: 'Threshold for safe margin',
                  tokens: tokens,
                  isDark: isDark,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF163424) : const Color(0xFFFAF7F2),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isDark ? const Color(0xFF274C37) : const Color(0xFFE4ECE0),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            final newTarget = (targetPct - 5.0).clamp(50.0, 95.0);
                            ref.read(targetPercentageProvider.notifier).setTarget(newTarget);
                          },
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1B3626) : Colors.white,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '−',
                              style: GoogleFonts.quicksand(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: tokens.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => TargetPercentageSheet.show(context),
                          child: Text(
                            '${targetPct.toStringAsFixed(1)}%',
                            style: GoogleFonts.quicksand(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: tokens.primaryAccent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            final newTarget = (targetPct + 5.0).clamp(50.0, 95.0);
                            ref.read(targetPercentageProvider.notifier).setTarget(newTarget);
                          },
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1B3626) : Colors.white,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '+',
                              style: GoogleFonts.quicksand(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: tokens.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  onTap: () => TargetPercentageSheet.show(context),
                ),
                Divider(height: 1, indent: 56, endIndent: 16, color: dividerColor),
                _buildSproutTile(
                  icon: Icons.translate_rounded,
                  iconBg: isDark ? const Color(0xFF2E1065).withValues(alpha: 0.5) : const Color(0xFFF3E8FF),
                  iconColor: isDark ? const Color(0xFFC084FC) : const Color(0xFF7E22CE),
                  title: 'Language',
                  tokens: tokens,
                  isDark: isDark,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'English',
                        style: GoogleFonts.quicksand(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: tokens.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, size: 18, color: tokens.textMuted),
                    ],
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),

          // 3. NOTIFICATIONS (No emoji in heading)
          _buildSproutSectionHeader('Notifications', tokens),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cardBorder, width: 1.0),
            ),
            child: _buildSproutTile(
              icon: Icons.notifications_active_rounded,
              iconBg: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
              iconColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
              title: 'Notification Preferences',
              subtitle: 'Class alerts & schedule reminders',
              tokens: tokens,
              isDark: isDark,
              trailing: Icon(Icons.chevron_right_rounded, size: 18, color: tokens.textMuted),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
                );
              },
            ),
          ),

          // 4. DATA & STORAGE (No emoji in heading)
          _buildSproutSectionHeader('Data & Storage', tokens),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cardBorder, width: 1.0),
            ),
            child: Column(
              children: [
                _buildSproutTile(
                  icon: Icons.file_upload_rounded,
                  iconBg: isDark ? const Color(0xFF143D24) : const Color(0xFFECFDF5),
                  iconColor: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                  title: 'Export Attendance Report',
                  subtitle: 'PDF summary with semester seal',
                  tokens: tokens,
                  isDark: isDark,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF163424) : const Color(0xFFEAF8E7),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isDark ? const Color(0xFF2C5B45) : const Color(0xFFD7F0D6),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      'PDF ›',
                      style: GoogleFonts.quicksand(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFEAF8EA) : const Color(0xFF1E6B3F),
                      ),
                    ),
                  ),
                  onTap: () => _showExportSheet(context, overallStats, activeSemester, userProfile, userUni, activeTemplate, isDark),
                ),
                Divider(height: 1, indent: 56, endIndent: 16, color: dividerColor),
                _buildSproutTile(
                  icon: Icons.cloud_sync_rounded,
                  iconBg: isDark ? const Color(0xFF163424) : const Color(0xFFF0FDF4),
                  iconColor: isDark ? const Color(0xFF66BB6A) : const Color(0xFF16A34A),
                  title: 'Backup & Restore',
                  subtitle: 'Safeguard database & schedule vault',
                  tokens: tokens,
                  isDark: isDark,
                  trailing: Icon(Icons.chevron_right_rounded, size: 18, color: tokens.textMuted),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BackupRestoreScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          // 5. ABOUT (No emoji in heading)
          _buildSproutSectionHeader('About', tokens),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cardBorder, width: 1.0),
            ),
            child: Column(
              children: [
                _buildSproutTile(
                  icon: Icons.explore_rounded,
                  iconBg: isDark ? const Color(0xFF164E63) : const Color(0xFFECFEFF),
                  iconColor: isDark ? const Color(0xFF22D3EE) : const Color(0xFF0891B2),
                  title: 'Take Guided App Tour',
                  subtitle: 'Replay the interactive app walkthrough',
                  tokens: tokens,
                  isDark: isDark,
                  trailing: Icon(Icons.chevron_right_rounded, size: 18, color: tokens.textMuted),
                  onTap: () {
                    if (canPopRoute) {
                      Navigator.of(context).pop();
                    }
                    ref.read(activeTourProvider.notifier).state = true;
                  },
                ),
                Divider(height: 1, indent: 56, endIndent: 16, color: dividerColor),
                _buildSproutTile(
                  icon: Icons.spa_rounded,
                  iconBg: isDark ? const Color(0xFF163424) : const Color(0xFFEAF8E7),
                  iconColor: isDark ? const Color(0xFF8BC34A) : const Color(0xFF2E7D32),
                  title: 'About Classtrack',
                  subtitle: 'Version ${updateState.currentVersion}',
                  tokens: tokens,
                  isDark: isDark,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF163424) : const Color(0xFFEAF8E7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'v${updateState.currentVersion}',
                      style: GoogleFonts.quicksand(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFEAF8EA) : const Color(0xFF1E6B3F),
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AboutScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          // 6. EXPERIMENTAL & DEVELOPER (No emoji in heading)
          _buildSproutSectionHeader('Developer & Experimental', tokens),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cardBorder, width: 1.0),
            ),
            child: Column(
              children: [
                _buildSproutTile(
                  icon: Icons.science_rounded,
                  iconBg: isDark ? const Color(0xFF4C0519).withValues(alpha: 0.4) : const Color(0xFFFDF2F8),
                  iconColor: isDark ? const Color(0xFFF472B6) : const Color(0xFFDB2777),
                  title: 'Beta Features',
                  subtitle: 'Early access to experimental tools',
                  tokens: tokens,
                  isDark: isDark,
                  trailing: Switch(
                    value: betaMode,
                    activeThumbColor: tokens.primaryAccent,
                    onChanged: (val) {
                      ref.read(betaFeaturesEnabledProvider.notifier).toggle(val);
                      AppToast.info(context, 'Beta features ${val ? "enabled" : "disabled"}');
                    },
                  ),
                ),
                if (isDeveloperUnlocked) ...[
                  Divider(height: 1, indent: 56, endIndent: 16, color: dividerColor),
                  _buildSproutTile(
                    icon: Icons.developer_mode_rounded,
                    iconBg: isDark ? const Color(0xFF134E4A) : const Color(0xFFF0FDFA),
                    iconColor: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488),
                    title: 'Developer Options',
                    subtitle: 'Database & simulation testing mode',
                    tokens: tokens,
                    isDark: isDark,
                    trailing: Switch(
                      value: developerMode,
                      activeThumbColor: tokens.primaryAccent,
                      onChanged: (val) {
                        ref.read(developerModeEnabledProvider.notifier).toggle(val);
                      },
                    ),
                  ),
                  if (developerMode) ...[
                    Divider(height: 1, indent: 56, endIndent: 16, color: dividerColor),
                    _buildSproutTile(
                      icon: Icons.terminal_rounded,
                      iconBg: isDark ? const Color(0xFF431407) : const Color(0xFFFFF7ED),
                      iconColor: isDark ? const Color(0xFFFB923C) : const Color(0xFFEA580C),
                      title: 'Developer Tools',
                      subtitle: 'Testing utilities & diagnostic simulators',
                      tokens: tokens,
                      isDark: isDark,
                      trailing: Icon(Icons.chevron_right_rounded, size: 18, color: tokens.textMuted),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const DeveloperToolsScreen()),
                        );
                      },
                    ),
                  ],
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

  Widget _buildSproutHeader(AppThemeTokens tokens, ThemeDefinition themeDef) {
    final mascotPath = themeDef.assets.settingsMascot ?? 'assets/themes/sprout/mascots/sprout_settings_reading.png';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Settings',
                style: GoogleFonts.quicksand(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: tokens.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
                const SizedBox(height: 2),
                Text(
                  'Your academic companion',
                  style: GoogleFonts.quicksand(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Image.asset(
            mascotPath,
            width: 104,
            height: 96,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox(width: 104, height: 96),
          ),
        ],
      );
  }

  Widget _buildSproutSectionHeader(String title, AppThemeTokens tokens) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 20, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.quicksand(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: tokens.textMuted,
        ),
      ),
    );
  }

  Widget _buildSproutTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    required AppThemeTokens tokens,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.quicksand(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 1.5),
                      Text(
                        subtitle,
                        style: GoogleFonts.quicksand(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildTile({
    Widget? leading,
    required String title,
    String? subtitle,
    required bool isDark,
    Widget? trailing,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (leading != null) ...[
                leading,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: titleColor ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildCuteLeading(IconData icon, Color color, bool isDark, bool isCute) {
    if (!isCute) return null;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 17, color: color),
    );
  }

  Widget _buildChevronValue(String value, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
        const SizedBox(width: 4),
        _buildChevronIcon(isDark),
      ],
    );
  }

  Widget _buildChevronIcon(bool isDark) {
    return Icon(
      Icons.chevron_right_rounded,
      size: 18,
      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
    );
  }

  void _showExportSheet(
    BuildContext context,
    OverallAttendanceStats overallStats,
    SemesterEntity activeSemester,
    UserProfileEntity userProfile,
    UserUniversityInfo userUni,
    ProgrammeTemplate activeTemplate,
    bool isDark,
  ) {
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    if (tokens?.isCute == true) {
      _showSproutExportSheet(
        context,
        tokens!,
        overallStats,
        activeSemester,
        userProfile,
        userUni,
        activeTemplate,
        isDark,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final subjects = ref.read(subjectsProvider);
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 16),
              Text(
                'Export Attendance Report',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Exports all date-wise sessions across ${activeSemester.name}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 18),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.presentGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.table_chart_rounded, color: AppColors.presentGreen, size: 22),
                ),
                title: const Text('Excel Spreadsheet (.xlsx)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Full multi-sheet workbook with summary & daily register', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(context);
                  _runExportWithProgress(
                    format: 'EXCEL',
                    overallStats: overallStats,
                    activeSemester: activeSemester,
                    userProfile: userProfile,
                    userUni: userUni,
                    activeTemplate: activeTemplate,
                    subjects: subjects,
                  );
                },
              ),
              Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.absentRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.absentRed, size: 22),
                ),
                title: const Text('PDF Document (.pdf)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Printable official report with wrap protection & date tables', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(context);
                  _runExportWithProgress(
                    format: 'PDF',
                    overallStats: overallStats,
                    activeSemester: activeSemester,
                    userProfile: userProfile,
                    userUni: userUni,
                    activeTemplate: activeTemplate,
                    subjects: subjects,
                  );
                },
              ),
              Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.code_rounded, color: AppColors.accentBlue, size: 22),
                ),
                title: const Text('Raw JSON (.json)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Machine-readable backup of your entire attendance data', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(context);
                  _runExportWithProgress(
                    format: 'JSON',
                    overallStats: overallStats,
                    activeSemester: activeSemester,
                    userProfile: userProfile,
                    userUni: userUni,
                    activeTemplate: activeTemplate,
                    subjects: subjects,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSproutExportSheet(
    BuildContext context,
    AppThemeTokens tokens,
    OverallAttendanceStats overallStats,
    SemesterEntity activeSemester,
    UserProfileEntity userProfile,
    UserUniversityInfo userUni,
    ProgrammeTemplate activeTemplate,
    bool isDark,
  ) {
    final sheetBg = isDark ? const Color(0xFF1B3626) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF274C37) : const Color(0xFFE4ECE0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final subjects = ref.read(subjectsProvider);
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: cardBorder, width: 1.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF274C37) : const Color(0xFFD4DEC7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Export Attendance Report',
                style: GoogleFonts.quicksand(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: tokens.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Exports all date-wise sessions across ${activeSemester.name}',
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: tokens.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              _buildSproutExportTile(
                title: 'Excel Spreadsheet (.xlsx)',
                subtitle: 'Full multi-sheet workbook with summary & daily register',
                icon: Icons.table_chart_rounded,
                iconBg: isDark ? const Color(0xFF163424) : const Color(0xFFEAF8E7),
                iconColor: isDark ? const Color(0xFF8BC34A) : const Color(0xFF1E6B3F),
                tokens: tokens,
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  _runExportWithProgress(
                    format: 'EXCEL',
                    overallStats: overallStats,
                    activeSemester: activeSemester,
                    userProfile: userProfile,
                    userUni: userUni,
                    activeTemplate: activeTemplate,
                    subjects: subjects,
                  );
                },
              ),
              Divider(height: 1, indent: 56, endIndent: 8, color: cardBorder),
              _buildSproutExportTile(
                title: 'PDF Document (.pdf)',
                subtitle: 'Printable official report with wrap protection & date tables',
                icon: Icons.picture_as_pdf_rounded,
                iconBg: isDark ? const Color(0xFF381C1C) : const Color(0xFFFEF2F2),
                iconColor: const Color(0xFFEF4444),
                tokens: tokens,
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  _runExportWithProgress(
                    format: 'PDF',
                    overallStats: overallStats,
                    activeSemester: activeSemester,
                    userProfile: userProfile,
                    userUni: userUni,
                    activeTemplate: activeTemplate,
                    subjects: subjects,
                  );
                },
              ),
              Divider(height: 1, indent: 56, endIndent: 8, color: cardBorder),
              _buildSproutExportTile(
                title: 'Raw JSON (.json)',
                subtitle: 'Machine-readable backup of your entire attendance data',
                icon: Icons.code_rounded,
                iconBg: isDark ? const Color(0xFF132B45) : const Color(0xFFE6F0FA),
                iconColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D6FB8),
                tokens: tokens,
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  _runExportWithProgress(
                    format: 'JSON',
                    overallStats: overallStats,
                    activeSemester: activeSemester,
                    userProfile: userProfile,
                    userUni: userUni,
                    activeTemplate: activeTemplate,
                    subjects: subjects,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSproutExportTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required AppThemeTokens tokens,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: iconColor, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.quicksand(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.quicksand(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: tokens.textMuted),
          ],
        ),
      ),
    );
  }

  Future<void> _runExportWithProgress({
    required String format,
    required OverallAttendanceStats overallStats,
    required SemesterEntity activeSemester,
    required UserProfileEntity userProfile,
    required UserUniversityInfo userUni,
    required ProgrammeTemplate activeTemplate,
    required List<SubjectEntity> subjects,
  }) async {
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final isCute = tokens?.isCute == true;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double currentProgress = 0.05;
    String currentStatus = 'Initializing export...';
    StateSetter? dialogStateSetter;

    // Show Progress Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            dialogStateSetter = setDialogState;
            if (isCute && tokens != null) {
              final dialogBg = isDark ? const Color(0xFF1B3626) : Colors.white;
              final dialogBorder = isDark ? const Color(0xFF274C37) : const Color(0xFFE4ECE0);
              return AlertDialog(
                backgroundColor: dialogBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(color: dialogBorder, width: 1.0),
                ),
                content: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 64,
                            height: 64,
                            child: CircularProgressIndicator(
                              value: currentProgress,
                              strokeWidth: 5,
                              backgroundColor: isDark ? const Color(0xFF274C37) : const Color(0xFFE2EAE0),
                              valueColor: AlwaysStoppedAnimation<Color>(tokens.primaryAccent),
                            ),
                          ),
                          Text(
                            '${(currentProgress * 100).toInt()}%',
                            style: GoogleFonts.quicksand(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: tokens.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Exporting $format Report',
                        style: GoogleFonts.quicksand(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: tokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currentStatus,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.quicksand(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: tokens.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF163424) : const Color(0xFFF0F6EE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: dialogBorder, width: 0.8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 16, color: tokens.primaryAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Please do not clear the app from background. We will notify you once done.',
                                style: GoogleFonts.quicksand(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: tokens.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return AlertDialog(
              backgroundColor: isDark ? AppColors.cardDark : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: CircularProgressIndicator(
                            value: currentProgress,
                            strokeWidth: 5,
                            backgroundColor: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              format == 'PDF'
                                  ? AppColors.absentRed
                                  : (format == 'EXCEL' ? AppColors.presentGreen : AppColors.accentIndigoLight),
                            ),
                          ),
                        ),
                        Text(
                          '${(currentProgress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Exporting $format Report',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currentStatus,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 16, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Please do not clear the app from background. We will notify you once done.',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    try {
      final db = ref.read(databaseProvider);
      final startDate = activeSemester.startDate;
      final endDate = activeSemester.endDate ?? DateTime.now();

      final sessions = await ExportService.collectDateRangeSessions(
        db: db,
        semester: activeSemester,
        startDate: startDate,
        endDate: endDate,
        onProgress: (p, msg) {
          currentProgress = p;
          currentStatus = msg;
          dialogStateSetter?.call(() {});
        },
      );

      String filePath;
      String mimeType;

      if (format == 'EXCEL') {
        mimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
        filePath = await ExportService.generateExcelReport(
          overallStats: overallStats,
          semester: activeSemester,
          profile: userProfile,
          university: userUni,
          courseStructure: activeTemplate,
          sessions: sessions,
          onProgress: (p, msg) {
            currentProgress = p;
            currentStatus = msg;
            dialogStateSetter?.call(() {});
          },
        );
      } else if (format == 'PDF') {
        mimeType = 'application/pdf';
        filePath = await ExportService.generatePdfReport(
          overallStats: overallStats,
          semester: activeSemester,
          profile: userProfile,
          university: userUni,
          courseStructure: activeTemplate,
          sessions: sessions,
          onProgress: (p, msg) {
            currentProgress = p;
            currentStatus = msg;
            dialogStateSetter?.call(() {});
          },
        );
      } else {
        mimeType = 'application/json';
        filePath = await ExportService.exportJsonBackup(
          profile: userProfile,
          university: userUni,
          semester: activeSemester,
          courseStructure: activeTemplate,
          subjects: subjects,
          sessions: sessions,
          onProgress: (p, msg) {
            currentProgress = p;
            currentStatus = msg;
            dialogStateSetter?.call(() {});
          },
        );
      }

      if (mounted) {
        Navigator.pop(context); // Close progress modal
        await ExportService.shareFile(filePath, mimeType);
        if (mounted) {
          AppToast.success(context, '$format report exported successfully!');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close progress modal
        AppToast.error(context, 'Export failed: $e');
      }
    }
  }
}

