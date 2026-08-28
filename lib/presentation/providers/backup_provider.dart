import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/backup_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/ui/app_toast.dart';
import '../../data/database/app_database.dart';
import '../widgets/restore_preview_dialog.dart';
import 'app_state_provider.dart';
import 'theme_provider.dart';

enum AutoBackupFrequency {
  every6Hours,
  every12Hours,
  daily,
  every3Days,
  weekly,
  monthly,
}

extension AutoBackupFrequencyExt on AutoBackupFrequency {
  Duration get duration {
    switch (this) {
      case AutoBackupFrequency.every6Hours:
        return const Duration(hours: 6);
      case AutoBackupFrequency.every12Hours:
        return const Duration(hours: 12);
      case AutoBackupFrequency.daily:
        return const Duration(days: 1);
      case AutoBackupFrequency.every3Days:
        return const Duration(days: 3);
      case AutoBackupFrequency.weekly:
        return const Duration(days: 7);
      case AutoBackupFrequency.monthly:
        return const Duration(days: 30);
    }
  }

  String get label {
    switch (this) {
      case AutoBackupFrequency.every6Hours:
        return 'Every 6 Hours';
      case AutoBackupFrequency.every12Hours:
        return 'Every 12 Hours';
      case AutoBackupFrequency.daily:
        return 'Daily (24 Hours)';
      case AutoBackupFrequency.every3Days:
        return 'Every 3 Days';
      case AutoBackupFrequency.weekly:
        return 'Weekly (7 Days)';
      case AutoBackupFrequency.monthly:
        return 'Monthly (30 Days)';
    }
  }
}

class BackupState {
  final bool isAutoBackupEnabled;
  final AutoBackupFrequency frequency;
  final int maxBackupsToRetain;
  final String? customBackupDirectory;
  final String? resolvedBackupDirectoryPath;
  final DateTime? lastBackupTimestamp;
  final String? lastBackupFilePath;
  final int? lastBackupSize;
  final String? lastBackupSummary;
  final List<File> availableBackups;
  final bool isBackingUp;
  final bool isRestoring;

  const BackupState({
    this.isAutoBackupEnabled = false,
    this.frequency = AutoBackupFrequency.daily,
    this.maxBackupsToRetain = 5,
    this.customBackupDirectory,
    this.resolvedBackupDirectoryPath,
    this.lastBackupTimestamp,
    this.lastBackupFilePath,
    this.lastBackupSize,
    this.lastBackupSummary,
    this.availableBackups = const [],
    this.isBackingUp = false,
    this.isRestoring = false,
  });

  BackupState copyWith({
    bool? isAutoBackupEnabled,
    AutoBackupFrequency? frequency,
    int? maxBackupsToRetain,
    String? customBackupDirectory,
    String? resolvedBackupDirectoryPath,
    bool resetCustomDirectory = false,
    DateTime? lastBackupTimestamp,
    String? lastBackupFilePath,
    int? lastBackupSize,
    String? lastBackupSummary,
    List<File>? availableBackups,
    bool? isBackingUp,
    bool? isRestoring,
  }) {
    return BackupState(
      isAutoBackupEnabled: isAutoBackupEnabled ?? this.isAutoBackupEnabled,
      frequency: frequency ?? this.frequency,
      maxBackupsToRetain: maxBackupsToRetain ?? this.maxBackupsToRetain,
      customBackupDirectory: resetCustomDirectory ? null : (customBackupDirectory ?? this.customBackupDirectory),
      resolvedBackupDirectoryPath: resolvedBackupDirectoryPath ?? this.resolvedBackupDirectoryPath,
      lastBackupTimestamp: lastBackupTimestamp ?? this.lastBackupTimestamp,
      lastBackupFilePath: lastBackupFilePath ?? this.lastBackupFilePath,
      lastBackupSize: lastBackupSize ?? this.lastBackupSize,
      lastBackupSummary: lastBackupSummary ?? this.lastBackupSummary,
      availableBackups: availableBackups ?? this.availableBackups,
      isBackingUp: isBackingUp ?? this.isBackingUp,
      isRestoring: isRestoring ?? this.isRestoring,
    );
  }
}

class BackupNotifier extends StateNotifier<BackupState> {
  final Ref ref;
  AppDatabase get db => ref.read(databaseProvider);

  BackupNotifier(this.ref) : super(const BackupState()) {
    loadSettingsAndBackups();
  }

  Future<void> loadSettingsAndBackups() async {
    try {
      final jsonStr = await db.getSetting('backup_settings');
      if (!mounted) return;
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        state = state.copyWith(
          isAutoBackupEnabled: map['is_auto_backup_enabled'] == true,
          frequency: AutoBackupFrequency.values.firstWhere(
            (e) => e.name == map['frequency'],
            orElse: () => AutoBackupFrequency.daily,
          ),
          maxBackupsToRetain: map['max_backups_to_retain'] as int? ?? 5,
          customBackupDirectory: map['custom_backup_directory'] as String?,
          lastBackupTimestamp: map['last_backup_timestamp'] != null
              ? DateTime.tryParse(map['last_backup_timestamp'].toString())
              : null,
          lastBackupFilePath: map['last_backup_file_path'] as String?,
          lastBackupSize: map['last_backup_size'] as int?,
          lastBackupSummary: map['last_backup_summary'] as String?,
        );
      }
      await refreshLocalBackupsList();
    } catch (_) {}
  }

  Future<void> _persistSettings() async {
    final map = {
      'is_auto_backup_enabled': state.isAutoBackupEnabled,
      'frequency': state.frequency.name,
      'max_backups_to_retain': state.maxBackupsToRetain,
      'custom_backup_directory': state.customBackupDirectory,
      'last_backup_timestamp': state.lastBackupTimestamp?.toIso8601String(),
      'last_backup_file_path': state.lastBackupFilePath,
      'last_backup_size': state.lastBackupSize,
      'last_backup_summary': state.lastBackupSummary,
    };
    await db.setSetting('backup_settings', jsonEncode(map));
  }

  Future<void> setAutoBackupEnabled(bool enabled) async {
    state = state.copyWith(isAutoBackupEnabled: enabled);
    await _persistSettings();
  }

  Future<void> setFrequency(AutoBackupFrequency freq) async {
    state = state.copyWith(frequency: freq);
    await _persistSettings();
  }

  Future<void> setMaxBackupsToRetain(int count) async {
    state = state.copyWith(maxBackupsToRetain: count);
    await _persistSettings();
  }

  Future<void> changeBackupDirectory(BuildContext context) async {
    try {
      final selectedDirectory = await FilePicker.getDirectoryPath();
      if (selectedDirectory != null && selectedDirectory.trim().isNotEmpty) {
        state = state.copyWith(customBackupDirectory: selectedDirectory.trim());
        await _persistSettings();
        await refreshLocalBackupsList();
        if (context.mounted) {
          AppToast.success(context, 'Backup folder updated: $selectedDirectory');
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, 'Could not set custom folder: $e');
      }
    }
  }

  Future<void> resetBackupDirectory(BuildContext context) async {
    state = state.copyWith(resetCustomDirectory: true);
    await _persistSettings();
    await refreshLocalBackupsList();
    if (context.mounted) {
      AppToast.info(context, 'Backup folder reset to default.');
    }
  }

  Future<void> refreshLocalBackupsList() async {
    try {
      final dir = await BackupService.getBackupDirectory(customPath: state.customBackupDirectory);
      if (!mounted) return;
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.ctbackup') || f.path.endsWith('.json'))
          .toList();
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      if (!mounted) return;
      state = state.copyWith(
        resolvedBackupDirectoryPath: dir.path,
        availableBackups: files,
      );
    } catch (_) {}
  }

  /// Create an instant full snapshot backup with storage permission checks
  Future<File?> createInstantBackup(
    BuildContext? context, {
    bool shareImmediately = false,
  }) async {
    // Check & request storage permission
    final hasPermission = await BackupService.checkAndRequestStoragePermission();
    if (!hasPermission) {
      if (context != null && context.mounted) {
        AppToast.error(context, 'Storage permission is required to save backup snapshots.');
      }
      return null;
    }

    state = state.copyWith(isBackingUp: true);

    try {
      final jsonString = await BackupService.generateFullBackupJson(db);
      final file = await BackupService.saveBackupToFile(
        jsonString,
        customDirectoryPath: state.customBackupDirectory,
      );
      final size = await file.length();

      // Extract brief summary
      final validation = BackupService.validateBackup(jsonString);
      final counts = validation.itemCounts;
      final summary = '${counts['subjects'] ?? 0} Subjects • ${counts['timetable_slots'] ?? 0} Slots • ${counts['attendance_records'] ?? 0} Logs';

      await BackupService.pruneOldBackups(state.maxBackupsToRetain, customDirectoryPath: state.customBackupDirectory);

      final now = DateTime.now();
      state = state.copyWith(
        isBackingUp: false,
        lastBackupTimestamp: now,
        lastBackupFilePath: file.path,
        lastBackupSize: size,
        lastBackupSummary: summary,
      );

      await _persistSettings();
      await refreshLocalBackupsList();

      // Dispatch phone notification
      await NotificationService.instance.showBackupNotification(
        title: 'Backup Created Successfully',
        body: 'Snapshot saved (${BackupService.formatFileSize(size)}) at ${BackupService.formatDeviceTimestamp(now)}.',
      );

      if (shareImmediately) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: 'ClassTrack Full Backup (${BackupService.formatDeviceTimestamp(now)})',
          ),
        );
      }

      if (context != null && context.mounted) {
        AppToast.success(context, 'Backup saved successfully! (${BackupService.formatFileSize(size)})');
      }

      return file;
    } catch (e) {
      state = state.copyWith(isBackingUp: false);
      if (context != null && context.mounted) {
        AppToast.error(context, 'Backup failed: ${e.toString()}');
      }
      return null;
    }
  }

  /// Restore strictly from user-picked .ctbackup file
  Future<void> restoreBackupFromFile(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ctbackup'],
      );

      if (result == null || result.files.single.path == null) return;

      final filePath = result.files.single.path!;
      if (!filePath.toLowerCase().endsWith('.ctbackup') && !filePath.toLowerCase().endsWith('.json')) {
        if (context.mounted) {
          AppToast.error(context, 'Invalid file: Please select a valid ClassTrack backup file (.ctbackup).');
        }
        return;
      }

      final file = File(filePath);
      if (context.mounted) {
        await restoreSpecificBackupFile(file, context);
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, 'Failed to open backup file: $e');
      }
    }
  }

  /// Restores a specific File with confirmation preview dialog
  Future<void> restoreSpecificBackupFile(File file, BuildContext context) async {
    try {
      if (!await file.exists()) {
        if (context.mounted) {
          AppToast.error(context, 'Selected backup file does not exist.');
        }
        return;
      }

      final content = await file.readAsString();
      final validation = BackupService.validateBackup(content);

      if (!validation.isValid) {
        if (context.mounted) {
          AppToast.error(context, validation.errorMessage ?? 'Invalid backup file.');
        }
        return;
      }

      if (!context.mounted) return;

      // Show preview dialog
      await showDialog(
        context: context,
        builder: (ctx) => RestorePreviewDialog(
          validationResult: validation,
          onConfirm: () async {
            await _executeRestore(content, context);
          },
        ),
      );
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, 'Error reading backup file: $e');
      }
    }
  }

  Future<void> _executeRestore(String jsonContent, BuildContext context) async {
    state = state.copyWith(isRestoring: true);

    try {
      final decoded = jsonDecode(jsonContent) as Map<String, dynamic>;
      await BackupService.restoreBackup(decoded, db);

      // Re-hydrate all Riverpod notifiers
      await ref.read(userProfileProvider.notifier).loadFromDb();
      await ref.read(selectedUniversityProvider.notifier).loadFromDb();
      await ref.read(activeSemesterProvider.notifier).loadFromDb();
      await ref.read(semestersListProvider.notifier).loadFromDb();
      await ref.read(subjectsProvider.notifier).loadFromDb();
      await ref.read(timetableSlotsProvider.notifier).loadFromDb();
      await ref.read(holidaysProvider.notifier).loadFromDb();
      await ref.read(attendanceRecordsProvider.notifier).loadFromDb();
      await ref.read(targetPercentageProvider.notifier).loadFromDb();
      await ref.read(activeTemplateProvider.notifier).loadFromDb();
      await ref.read(betaFeaturesEnabledProvider.notifier).loadFromDb();
      await ref.read(developerModeEnabledProvider.notifier).loadFromDb();
      await ref.read(themeModeProvider.notifier).loadFromDb();

      state = state.copyWith(isRestoring: false);

      // Dispatch phone notification for restored backup
      await NotificationService.instance.showBackupNotification(
        title: 'Backup Restored Successfully',
        body: 'All subjects, schedule slots, and attendance logs restored.',
      );

      if (context.mounted) {
        AppToast.success(context, 'Data successfully restored from backup!');
      }
    } catch (e) {
      state = state.copyWith(isRestoring: false);
      if (context.mounted) {
        AppToast.error(context, 'Restore failed: $e');
      }
    }
  }

  /// Delete a backup file
  Future<void> deleteBackupFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        await refreshLocalBackupsList();
      }
    } catch (_) {}
  }

  /// Share a backup file
  Future<void> shareBackupFile(File file) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'ClassTrack Backup (${file.path.split(Platform.pathSeparator).last})',
        ),
      );
    } catch (_) {}
  }

  /// Background Auto-Backup check on app launch
  Future<void> checkAndRunAutoBackup(AppDatabase database) async {
    if (!state.isAutoBackupEnabled) return;

    final last = state.lastBackupTimestamp;
    final interval = state.frequency.duration;

    if (last == null || DateTime.now().difference(last) >= interval) {
      try {
        final jsonString = await BackupService.generateFullBackupJson(database);
        final file = await BackupService.saveBackupToFile(
          jsonString,
          customDirectoryPath: state.customBackupDirectory,
        );
        final size = await file.length();
        await BackupService.pruneOldBackups(state.maxBackupsToRetain, customDirectoryPath: state.customBackupDirectory);

        state = state.copyWith(
          lastBackupTimestamp: DateTime.now(),
          lastBackupFilePath: file.path,
          lastBackupSize: size,
        );
        await _persistSettings();
        await refreshLocalBackupsList();

        // Dispatch phone notification for auto-backup
        await NotificationService.instance.showBackupNotification(
          title: 'Auto-Backup Completed',
          body: 'Scheduled backup saved safely (${BackupService.formatFileSize(size)}).',
        );
      } catch (_) {}
    }
  }
}

final backupProvider = StateNotifierProvider<BackupNotifier, BackupState>((ref) {
  return BackupNotifier(ref);
});
