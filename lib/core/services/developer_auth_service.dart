import 'dart:convert';
import 'package:crypto/crypto.dart';

class DeveloperAuthService {
  /// Pre-computed SHA-256 hash of default master PIN '8080'
  static final String kDefaultDevPasscodeHash = hashPasscode('8080');

  /// Hash plain PIN with SHA-256
  static String hashPasscode(String pin) {
    final bytes = utf8.encode(pin.trim());
    return sha256.convert(bytes).toString();
  }

  /// Constant-time byte-level comparison to prevent timing side-channel attacks
  static bool constantTimeCompare(String a, String b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  /// Verify entered PIN against active hash (custom or default)
  static bool verifyPasscode(String enteredPin, String? activeCustomHash) {
    final enteredHash = hashPasscode(enteredPin);
    final targetHash = (activeCustomHash != null && activeCustomHash.isNotEmpty)
        ? activeCustomHash
        : kDefaultDevPasscodeHash;
    return constantTimeCompare(enteredHash, targetHash);
  }

  /// Verify QR Code payload against active hash with strict validation
  static bool verifyQrPayload(String rawPayload, String? activeCustomHash) {
    try {
      final uri = Uri.tryParse(rawPayload.trim());
      if (uri == null || uri.scheme != 'classtrack' || uri.host != 'dev-unlock') {
        return false;
      }
      final token = uri.queryParameters['hash'];
      if (token == null || !RegExp(r'^[a-f0-9]{64}$').hasMatch(token)) {
        return false;
      }
      final targetHash = (activeCustomHash != null && activeCustomHash.isNotEmpty)
          ? activeCustomHash
          : kDefaultDevPasscodeHash;
      return constantTimeCompare(token, targetHash);
    } catch (_) {
      return false;
    }
  }

  /// Generate safe QR code deep link for the active hash
  static String generateQrPayload(String? activeCustomHash) {
    final targetHash = (activeCustomHash != null && activeCustomHash.isNotEmpty)
        ? activeCustomHash
        : kDefaultDevPasscodeHash;
    return 'classtrack://dev-unlock?hash=$targetHash';
  }
}

class DeveloperRateLimiter {
  static int _failedAttempts = 0;
  static DateTime? _lockedUntil;

  static int get failedAttempts => _failedAttempts;

  static bool get isLockedOut {
    if (_lockedUntil == null) return false;
    if (DateTime.now().isAfter(_lockedUntil!)) {
      _lockedUntil = null;
      _failedAttempts = 0;
      return false;
    }
    return true;
  }

  static int get remainingLockoutSeconds {
    if (_lockedUntil == null) return 0;
    final diff = _lockedUntil!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  static void recordFailure() {
    _failedAttempts++;
    if (_failedAttempts >= 5) {
      _lockedUntil = DateTime.now().add(const Duration(seconds: 30));
    }
  }

  static void recordSuccess() {
    _failedAttempts = 0;
    _lockedUntil = null;
  }

  static void reset() {
    _failedAttempts = 0;
    _lockedUntil = null;
  }
}
