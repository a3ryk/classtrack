import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme_tokens.dart';
import '../../../core/services/backup_service.dart';
import '../../providers/backup_provider.dart';

class BackupRestoreScreen extends ConsumerWidget {
  const BackupRestoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backupState = ref.watch(backupProvider);
    final backupNotifier = ref.read(backupProvider.notifier);

    if (tokens?.isCute == true) {
      return _buildSproutBackupView(context, tokens!, backupState, backupNotifier, isDark);
    }
    return _buildClassicBackupView(context, backupState, backupNotifier, isDark);
  }

  Widget _buildClassicBackupView(
    BuildContext context,
    BackupState backupState,
    BackupNotifier backupNotifier,
    bool isDark,
  ) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        elevation: 0,
        leadingWidth: 100,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(8),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 14),
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
        ),
        title: Text(
          'Backup & Restore',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // 1. LAST BACKUP STATUS HERO CARD
          _buildLastBackupHeroCard(context, backupState, isDark),

          const SizedBox(height: 20),

          // 2. PRIMARY ACTION BUTTONS
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: backupState.isBackingUp || backupState.isRestoring
                      ? null
                      : () => backupNotifier.createInstantBackup(context),
                  icon: backupState.isBackingUp
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.backup_rounded, size: 18),
                  label: Text(
                    backupState.isBackingUp ? 'Backing up...' : 'Backup Now',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    foregroundColor: isDark ? AppColors.bgDark : AppColors.surfaceLight,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: backupState.isBackingUp || backupState.isRestoring
                      ? null
                      : () => backupNotifier.restoreBackupFromFile(context),
                  icon: const Icon(Icons.folder_open_rounded, size: 18),
                  label: const Text(
                    'Restore',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                    foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 3. AUTOMATIC BACKUP CONFIGURATION CARD
          Text(
            'AUTOMATION & SCHEDULES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text(
                    'Automatic Backup',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Silently saves full snapshots into storage',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                  value: backupState.isAutoBackupEnabled,
                  activeThumbColor: AppColors.presentGreen,
                  onChanged: (val) async {
                    await backupNotifier.setAutoBackupEnabled(val, context: context);
                  },
                ),
                if (backupState.isAutoBackupEnabled && !backupState.hasStoragePermission) ...[
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.absentContainerDark : AppColors.absentContainerLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (isDark ? AppColors.absentRedDark : AppColors.absentRed).withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: isDark ? AppColors.absentRedDark : AppColors.absentRedText,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Storage permission revoked. Backups cannot be saved to phone storage.',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.absentRedDark : AppColors.absentRedText,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await backupNotifier.requestStoragePermission(context);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Grant',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.absentRedDark : AppColors.absentRedText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (backupState.isAutoBackupEnabled) ...[
                  Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BACKUP FREQUENCY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: AutoBackupFrequency.values.map((freq) {
                            final isSelected = backupState.frequency == freq;
                            return GestureDetector(
                              onTap: () => backupNotifier.setFrequency(freq),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                      : (isDark ? AppColors.pillDark : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  freq.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected
                                        ? (isDark ? AppColors.bgDark : AppColors.surfaceLight)
                                        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Max Snapshots to Retain',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            DropdownButton<int>(
                              value: backupState.maxBackupsToRetain,
                              dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                              underline: const SizedBox(),
                              items: [3, 5, 10, 20].map((count) {
                                return DropdownMenuItem<int>(
                                  value: count,
                                  child: Text('Keep $count', style: const TextStyle(fontSize: 12)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) backupNotifier.setMaxBackupsToRetain(val);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.folder_outlined,
                            size: 16,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              backupState.customBackupDirectory != null
                                  ? 'Custom Folder: ${backupState.resolvedBackupDirectoryPath ?? backupState.customBackupDirectory}'
                                  : 'Folder: ${backupState.resolvedBackupDirectoryPath ?? "Internal Storage/Attendly/backups"}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: backupState.customBackupDirectory != null ? FontWeight.w600 : FontWeight.w500,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          InkWell(
                            onTap: () => backupNotifier.changeBackupDirectory(context),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.pillDark : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.drive_file_move_outlined, size: 13, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Change Folder',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (backupState.customBackupDirectory != null) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => backupNotifier.resetBackupDirectory(context),
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                child: Text(
                                  'Reset to Default',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.absentRed,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 4. STORED LOCAL BACKUPS LIST
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LOCAL SNAPSHOTS (${backupState.availableBackups.length})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                tooltip: 'Refresh list',
                onPressed: () => backupNotifier.refreshLocalBackupsList(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (backupState.availableBackups.isEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.history_toggle_off_rounded,
                    size: 32,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No local snapshots found.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap "Backup Now" to create your first snapshot.',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: backupState.availableBackups.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
                itemBuilder: (context, index) {
                  final file = backupState.availableBackups[index];
                  return _buildBackupFileTile(context, file, backupNotifier, isDark);
                },
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSproutBackupView(
    BuildContext context,
    AppThemeTokens tokens,
    BackupState backupState,
    BackupNotifier backupNotifier,
    bool isDark,
  ) {
    final Color cardBg = isDark ? const Color(0xFF1B3626) : Colors.white;
    final Color cardBorder = isDark ? const Color(0xFF274C37) : const Color(0xFFE4ECE0);
    final Color dividerColor = isDark ? const Color(0xFF274C37) : const Color(0xFFF0ECE1);
    final Color scaffoldBg = tokens.scaffoldBg;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 100,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
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
        title: Text(
          'Backup & Restore',
          style: GoogleFonts.quicksand(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: tokens.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          // 1. LAST BACKUP STATUS HERO CARD
          _buildSproutLastBackupHeroCard(context, backupState, tokens, cardBg, cardBorder, isDark),

          const SizedBox(height: 16),

          // 2. PRIMARY ACTION BUTTONS
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: backupState.isBackingUp || backupState.isRestoring
                        ? null
                        : () => backupNotifier.createInstantBackup(context),
                    icon: backupState.isBackingUp
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isDark ? const Color(0xFF0F2618) : Colors.white,
                            ),
                          )
                        : const Icon(Icons.backup_rounded, size: 18),
                    label: Text(
                      backupState.isBackingUp ? 'Backing up...' : 'Backup Now',
                      style: GoogleFonts.quicksand(fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tokens.primaryAccent,
                      foregroundColor: isDark ? const Color(0xFF0F2618) : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: backupState.isBackingUp || backupState.isRestoring
                        ? null
                        : () => backupNotifier.restoreBackupFromFile(context),
                    icon: Icon(Icons.folder_open_rounded, size: 18, color: tokens.textPrimary),
                    label: Text(
                      'Restore',
                      style: GoogleFonts.quicksand(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: cardBorder, width: 1.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 3. AUTOMATION & SCHEDULES (Zero emojis in heading)
          _buildSproutBackupSectionHeader('Automation & Schedules', tokens, topPadding: 16),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cardBorder, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF163424) : const Color(0xFFEAF8E7),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          Icons.schedule_rounded,
                          size: 18,
                          color: isDark ? const Color(0xFF8BC34A) : const Color(0xFF1E6B3F),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Automatic Backup',
                              style: GoogleFonts.quicksand(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: tokens.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Silently saves full snapshots into storage',
                              style: GoogleFonts.quicksand(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: tokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: backupState.isAutoBackupEnabled,
                        activeThumbColor: Colors.white,
                        activeTrackColor: tokens.primaryAccent,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: isDark ? const Color(0xFF274C37) : const Color(0xFFE2EAE0),
                        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                        onChanged: (val) async {
                          await backupNotifier.setAutoBackupEnabled(val, context: context);
                        },
                      ),
                    ],
                  ),
                ),
                if (backupState.isAutoBackupEnabled && !backupState.hasStoragePermission) ...[
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF381C1C) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Storage permission revoked. Backups cannot be saved to phone storage.',
                            style: GoogleFonts.quicksand(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await backupNotifier.requestStoragePermission(context);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Grant',
                            style: GoogleFonts.quicksand(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (backupState.isAutoBackupEnabled) ...[
                  Divider(height: 1, indent: 56, endIndent: 16, color: dividerColor),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BACKUP FREQUENCY',
                          style: GoogleFonts.quicksand(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: tokens.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: AutoBackupFrequency.values.map((freq) {
                            final isSelected = backupState.frequency == freq;
                            return GestureDetector(
                              onTap: () => backupNotifier.setFrequency(freq),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? tokens.primaryAccent
                                      : (isDark ? const Color(0xFF163424) : const Color(0xFFF0F6EE)),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: isSelected
                                        ? tokens.primaryAccent
                                        : (isDark ? const Color(0xFF274C37) : const Color(0xFFE4ECE0)),
                                    width: 1.0,
                                  ),
                                ),
                                child: Text(
                                  freq.label,
                                  style: GoogleFonts.quicksand(
                                    fontSize: 11.5,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected
                                        ? (isDark ? const Color(0xFF0F2618) : Colors.white)
                                        : tokens.textPrimary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Max Snapshots to Retain',
                              style: GoogleFonts.quicksand(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: tokens.textPrimary,
                              ),
                            ),
                            DropdownButton<int>(
                              value: backupState.maxBackupsToRetain,
                              dropdownColor: cardBg,
                              underline: const SizedBox(),
                              items: [3, 5, 10, 20].map((count) {
                                return DropdownMenuItem<int>(
                                  value: count,
                                  child: Text(
                                    'Keep $count',
                                    style: GoogleFonts.quicksand(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: tokens.primaryAccent,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) backupNotifier.setMaxBackupsToRetain(val);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                Divider(height: 1, indent: 56, endIndent: 16, color: dividerColor),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.folder_outlined,
                            size: 16,
                            color: tokens.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              backupState.customBackupDirectory != null
                                  ? 'Custom Folder: ${backupState.resolvedBackupDirectoryPath ?? backupState.customBackupDirectory}'
                                  : 'Folder: ${backupState.resolvedBackupDirectoryPath ?? "Internal Storage/Attendly/backups"}',
                              style: GoogleFonts.quicksand(
                                fontSize: 11,
                                fontWeight: backupState.customBackupDirectory != null ? FontWeight.w700 : FontWeight.w500,
                                color: tokens.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          InkWell(
                            onTap: () => backupNotifier.changeBackupDirectory(context),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF163424) : const Color(0xFFF0F6EE),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: cardBorder, width: 0.8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.drive_file_move_outlined, size: 13, color: tokens.primaryAccent),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Change Folder',
                                    style: GoogleFonts.quicksand(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: tokens.primaryAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (backupState.customBackupDirectory != null) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => backupNotifier.resetBackupDirectory(context),
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                child: Text(
                                  'Reset to Default',
                                  style: GoogleFonts.quicksand(
                                    fontSize: 11,
                                    color: const Color(0xFFEF4444),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 4. STORED LOCAL BACKUPS LIST (Zero emojis in heading)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 20, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'LOCAL SNAPSHOTS (${backupState.availableBackups.length})',
                  style: GoogleFonts.quicksand(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: tokens.textMuted,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.refresh_rounded, size: 18, color: tokens.textSecondary),
                  tooltip: 'Refresh list',
                  onPressed: () => backupNotifier.refreshLocalBackupsList(),
                ),
              ],
            ),
          ),

          if (backupState.availableBackups.isEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cardBorder, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.history_toggle_off_rounded,
                    size: 32,
                    color: tokens.textMuted,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No local snapshots found.',
                    style: GoogleFonts.quicksand(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap "Backup Now" to create your first snapshot.',
                    style: GoogleFonts.quicksand(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cardBorder, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: backupState.availableBackups.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  indent: 56,
                  endIndent: 16,
                  color: dividerColor,
                ),
                itemBuilder: (context, index) {
                  final file = backupState.availableBackups[index];
                  return _buildSproutBackupFileTile(context, file, backupNotifier, tokens, cardBorder, isDark);
                },
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSproutLastBackupHeroCard(
    BuildContext context,
    BackupState state,
    AppThemeTokens tokens,
    Color cardBg,
    Color cardBorder,
    bool isDark,
  ) {
    final hasBackup = state.lastBackupTimestamp != null;
    final formattedTime = hasBackup
        ? BackupService.formatDeviceTimestamp(state.lastBackupTimestamp!)
        : 'Never Backed Up';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: hasBackup
                  ? (isDark ? const Color(0xFF163424) : const Color(0xFFEAF8E7))
                  : (isDark ? const Color(0xFF262E28) : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              hasBackup ? Icons.cloud_done_rounded : Icons.cloud_queue_rounded,
              size: 22,
              color: hasBackup
                  ? (isDark ? const Color(0xFF8BC34A) : const Color(0xFF1E6B3F))
                  : tokens.textMuted,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Last Backup',
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: tokens.textSecondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: hasBackup
                            ? (isDark ? const Color(0xFF163424) : const Color(0xFFEAF8E7))
                            : (isDark ? const Color(0xFF381C1C) : const Color(0xFFFEF2F2)),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: hasBackup
                              ? (isDark ? const Color(0xFF2C5B45) : const Color(0xFFD7F0D6))
                              : const Color(0xFFEF4444).withValues(alpha: 0.3),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        hasBackup ? 'ACTIVE' : 'RECOMMENDED',
                        style: GoogleFonts.quicksand(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: hasBackup
                              ? (isDark ? const Color(0xFF8BC34A) : const Color(0xFF1E6B3F))
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  formattedTime,
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: tokens.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                if (state.lastBackupSummary != null && state.lastBackupSummary!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    state.lastBackupSummary!,
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
        ],
      ),
    );
  }

  Widget _buildSproutBackupFileTile(
    BuildContext context,
    File file,
    BackupNotifier notifier,
    AppThemeTokens tokens,
    Color cardBorder,
    bool isDark,
  ) {
    final name = file.path.split(Platform.pathSeparator).last;
    final stat = file.statSync();
    final modified = BackupService.formatDeviceTimestamp(stat.modified);
    final size = BackupService.formatFileSize(stat.size);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF163424) : const Color(0xFFF0F6EE),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.description_outlined,
          size: 20,
          color: tokens.primaryAccent,
        ),
      ),
      title: Text(
        modified,
        style: GoogleFonts.quicksand(fontSize: 13, fontWeight: FontWeight.w700, color: tokens.textPrimary),
      ),
      subtitle: Text(
        '$size • $name',
        style: GoogleFonts.quicksand(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: tokens.textSecondary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.share_outlined, size: 18, color: tokens.textSecondary),
            tooltip: 'Share',
            onPressed: () => notifier.shareBackupFile(file),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.restore_rounded, size: 18, color: tokens.primaryAccent),
            tooltip: 'Restore',
            onPressed: () => notifier.restoreSpecificBackupFile(file, context),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
            tooltip: 'Delete',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: isDark ? const Color(0xFF1B3626) : Colors.white,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: cardBorder),
                  ),
                  title: Text(
                    'Delete Backup?',
                    style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.w800, color: tokens.textPrimary),
                  ),
                  content: Text(
                    'Are you sure you want to delete this backup snapshot?',
                    style: GoogleFonts.quicksand(fontSize: 13, color: tokens.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.quicksand(fontWeight: FontWeight.w700, color: tokens.textSecondary),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Delete',
                        style: GoogleFonts.quicksand(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await notifier.deleteBackupFile(file);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSproutBackupSectionHeader(
    String title,
    AppThemeTokens tokens, {
    double topPadding = 20,
    double bottomPadding = 8,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: 4, top: topPadding, bottom: bottomPadding),
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

  Widget _buildLastBackupHeroCard(BuildContext context, BackupState state, bool isDark) {
    final hasBackup = state.lastBackupTimestamp != null;
    final formattedTime = hasBackup
        ? BackupService.formatDeviceTimestamp(state.lastBackupTimestamp!)
        : 'Never Backed Up';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: hasBackup
                  ? (isDark ? AppColors.presentContainerDark : AppColors.presentContainerLight)
                  : (isDark ? AppColors.pillDark : const Color(0xFFF1F5F9)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasBackup ? Icons.cloud_done_rounded : Icons.cloud_queue_rounded,
              size: 22,
              color: hasBackup
                  ? (isDark ? AppColors.presentGreenDark : AppColors.presentGreenText)
                  : (isDark ? AppColors.textSecondaryDark : const Color(0xFF94A3B8)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Last Backup',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: hasBackup
                            ? (isDark ? AppColors.presentContainerDark : AppColors.presentContainerLight)
                            : (isDark ? AppColors.absentContainerDark : AppColors.absentContainerLight),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        hasBackup ? 'ACTIVE' : 'RECOMMENDED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: hasBackup
                              ? (isDark ? AppColors.presentGreenDark : AppColors.presentGreenText)
                              : (isDark ? AppColors.absentRedDark : AppColors.absentRedText),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  formattedTime,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    letterSpacing: -0.3,
                  ),
                ),
                if (state.lastBackupSummary != null && state.lastBackupSummary!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    state.lastBackupSummary!,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupFileTile(
    BuildContext context,
    File file,
    BackupNotifier notifier,
    bool isDark,
  ) {
    final name = file.path.split(Platform.pathSeparator).last;
    final stat = file.statSync();
    final modified = BackupService.formatDeviceTimestamp(stat.modified);
    final size = BackupService.formatFileSize(stat.size);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.pillDark : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.description_outlined,
          size: 20,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      title: Text(
        modified,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '$size • $name',
        style: TextStyle(
          fontSize: 11,
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.share_outlined, size: 18),
            tooltip: 'Share',
            onPressed: () => notifier.shareBackupFile(file),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.restore_rounded, size: 18),
            tooltip: 'Restore',
            onPressed: () => notifier.restoreSpecificBackupFile(file, context),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.absentRed),
            tooltip: 'Delete',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  title: const Text('Delete Backup?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  content: const Text('Are you sure you want to delete this backup snapshot?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.absentRedDark : AppColors.absentRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await notifier.deleteBackupFile(file);
              }
            },
          ),
        ],
      ),
    );
  }
}
