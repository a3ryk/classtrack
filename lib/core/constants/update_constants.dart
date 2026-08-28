/// In-App Update Configuration Constants
class UpdateConstants {
  UpdateConstants._();

  /// Default remote version manifest URL (raw JSON)
  /// Developers can change this to their GitHub repository raw URL, GitHub Pages, or custom server endpoint.
  /// Example: `https://raw.githubusercontent.com/owner/repo/branch/version.json`
  static const String defaultVersionCheckUrl =
      'https://raw.githubusercontent.com/a3ryk/classtrack/production/version.json';

  /// GitHub Repository Info (Fallback / Direct Releases API)
  static const String defaultGithubOwner = 'a3ryk';
  static const String defaultGithubRepo = 'classtrack';

  /// Fallback Release / Website URL
  static const String defaultWebsiteUrl = 'https://github.com/a3ryk/classtrack/releases';

  /// Network Timeout for Version Check (strict timeout)
  static const Duration requestTimeout = Duration(seconds: 10);
}
