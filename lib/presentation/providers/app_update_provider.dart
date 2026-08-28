import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/services/app_update_service.dart';
import '../../core/ui/app_toast.dart';
import '../screens/settings/update_screen.dart';
import '../widgets/up_to_date_dialog.dart';

enum UpdateCheckStatus {
  idle,
  checking,
  upToDate,
  updateAvailable,
  error,
}

class AppUpdateState {
  final UpdateCheckStatus status;
  final String currentVersion;
  final String currentBuildNumber;
  final AppReleaseInfo? releaseInfo;
  final String? errorMessage;
  final DateTime? lastCheckedTime;

  const AppUpdateState({
    this.status = UpdateCheckStatus.idle,
    this.currentVersion = '1.0.0',
    this.currentBuildNumber = '1',
    this.releaseInfo,
    this.errorMessage,
    this.lastCheckedTime,
  });

  bool get isChecking => status == UpdateCheckStatus.checking;
  bool get hasUpdate => status == UpdateCheckStatus.updateAvailable && releaseInfo != null;

  AppUpdateState copyWith({
    UpdateCheckStatus? status,
    String? currentVersion,
    String? currentBuildNumber,
    AppReleaseInfo? releaseInfo,
    String? errorMessage,
    DateTime? lastCheckedTime,
  }) {
    return AppUpdateState(
      status: status ?? this.status,
      currentVersion: currentVersion ?? this.currentVersion,
      currentBuildNumber: currentBuildNumber ?? this.currentBuildNumber,
      releaseInfo: releaseInfo ?? this.releaseInfo,
      errorMessage: errorMessage ?? this.errorMessage,
      lastCheckedTime: lastCheckedTime ?? this.lastCheckedTime,
    );
  }
}

class AppUpdateNotifier extends StateNotifier<AppUpdateState> {
  AppUpdateNotifier() : super(const AppUpdateState()) {
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      state = state.copyWith(
        currentVersion: info.version.isNotEmpty ? info.version : '1.0.0',
        currentBuildNumber: info.buildNumber.isNotEmpty ? info.buildNumber : '1',
      );
    } catch (_) {
      // Fallback in tests or uninitialized environments
      state = state.copyWith(currentVersion: '1.0.0', currentBuildNumber: '1');
    }
  }

  /// Check for updates remotely
  Future<void> checkForUpdates({
    BuildContext? context,
    bool manualTrigger = true,
    String? customManifestUrl,
  }) async {
    if (state.isChecking) return;

    state = state.copyWith(status: UpdateCheckStatus.checking, errorMessage: null);

    try {
      // 1. Fetch release info from primary manifest URL
      AppReleaseInfo? release = await AppUpdateService.fetchReleaseInfo(customUrl: customManifestUrl);

      // 2. Fallback to GitHub Releases API if primary manifest returns null
      release ??= await AppUpdateService.fetchGithubRelease();

      final currentVer = state.currentVersion;
      final currentBuild = int.tryParse(state.currentBuildNumber) ?? 1;

      if (release == null) {
        state = state.copyWith(
          status: UpdateCheckStatus.error,
          errorMessage: 'Unable to reach update server.',
          lastCheckedTime: DateTime.now(),
        );

        if (manualTrigger && context != null && context.mounted) {
          AppToast.error(context, 'Unable to check for updates. Please check your internet connection.');
        }
        return;
      }

      // 3. Evaluate if update is available
      final updateAvailable = AppUpdateService.isUpdateAvailable(
        currentVersion: currentVer,
        remoteVersion: release.latestVersion,
        currentBuild: currentBuild,
        remoteBuild: release.buildNumber,
      );

      final isMandatory = AppUpdateService.isMandatoryUpdate(
        currentVersion: currentVer,
        minSupportedVersion: release.minSupportedVersion,
        isMandatoryFlag: release.isMandatory,
      );

      final finalizedRelease = AppReleaseInfo(
        latestVersion: release.latestVersion,
        buildNumber: release.buildNumber,
        minSupportedVersion: release.minSupportedVersion,
        releaseDate: release.releaseDate,
        releaseTitle: release.releaseTitle,
        changelog: release.changelog,
        downloadUrl: release.downloadUrl,
        releasePageUrl: release.releasePageUrl,
        isMandatory: isMandatory,
      );

      if (updateAvailable) {
        state = state.copyWith(
          status: UpdateCheckStatus.updateAvailable,
          releaseInfo: finalizedRelease,
          lastCheckedTime: DateTime.now(),
        );

        if (context != null && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => UpdateScreen(releaseInfo: finalizedRelease),
            ),
          );
        }
      } else {
        state = state.copyWith(
          status: UpdateCheckStatus.upToDate,
          releaseInfo: finalizedRelease,
          lastCheckedTime: DateTime.now(),
        );

        if (manualTrigger && context != null && context.mounted) {
          showDialog(
            context: context,
            builder: (ctx) => UpToDateDialog(currentVersion: currentVer),
          );
        }
      }
    } catch (e) {
      state = state.copyWith(
        status: UpdateCheckStatus.error,
        errorMessage: e.toString(),
        lastCheckedTime: DateTime.now(),
      );

      if (manualTrigger && context != null && context.mounted) {
        AppToast.error(context, 'Error checking updates: ${e.toString()}');
      }
    }
  }
}

final appUpdateProvider = StateNotifierProvider<AppUpdateNotifier, AppUpdateState>((ref) {
  return AppUpdateNotifier();
});
