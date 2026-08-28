import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/backup_service.dart';
import '../../providers/backup_provider.dart';

class BackupRestoreScreen extends ConsumerWidget {
  const BackupRestoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backupState = ref.watch(backupProvider);
    final backupNotifier = ref.read(backupProvider.notifier);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Backup & Restore',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            letterSpacing: -0.4,
          ),
        ),
        centerTitle: false,
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
                  onChanged: (val) => backupNotifier.setAutoBackupEnabled(val),
                ),
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
                                  : 'Folder: ${backupState.resolvedBackupDirectoryPath ?? "Internal Storage/ClassTrack/backups"}',
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
