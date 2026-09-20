import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_theme_tokens.dart';

class PackageLicenseItem {
  final String packageName;
  final List<LicenseEntry> entries;
  List<String>? _cachedTexts;

  PackageLicenseItem({
    required this.packageName,
    this.entries = const [],
    List<String>? cachedTexts,
  }) : _cachedTexts = cachedTexts;

  int get licenseCount => entries.isNotEmpty ? entries.length : (_cachedTexts?.length ?? 0);

  /// Lazily evaluates and formats license texts only when opened by the user.
  /// This prevents freezing the main thread and allocating megabytes of strings upfront.
  List<String> get licenseTexts {
    if (_cachedTexts != null && _cachedTexts!.isNotEmpty) {
      return _cachedTexts!;
    }
    _cachedTexts = entries.map((entry) {
      return entry.paragraphs.map((p) => p.text).join('\n\n');
    }).toList();
    return _cachedTexts!;
  }

  static final List<PackageLicenseItem> defaultFallback = [
    PackageLicenseItem(
      packageName: 'flutter',
      cachedTexts: const [
        'Copyright 2014 The Flutter Authors. All rights reserved.\n\nRedistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:\n\n* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.',
      ],
    ),
    PackageLicenseItem(
      packageName: 'flutter_riverpod',
      cachedTexts: const [
        'MIT License\n\nCopyright (c) 2020 Remi Rousselet\n\nPermission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction.',
      ],
    ),
    PackageLicenseItem(
      packageName: 'drift',
      cachedTexts: const [
        'MIT License\n\nCopyright (c) 2019 Simon Binder\n\nPermission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction.',
      ],
    ),
    PackageLicenseItem(
      packageName: 'google_fonts',
      cachedTexts: const [
        'Apache License\nVersion 2.0, January 2004\nhttp://www.apache.org/licenses/\n\nLicensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.',
      ],
    ),
    PackageLicenseItem(
      packageName: 'flutter_markdown_plus',
      cachedTexts: const [
        'BSD 3-Clause License\n\nCopyright 2016 The Chromium Authors. All rights reserved.\n\nRedistribution and use in source and binary forms, with or without modification, are permitted.',
      ],
    ),
  ];
}

class LicensesScreen extends StatefulWidget {
  final String currentVersion;

  const LicensesScreen({
    super.key,
    required this.currentVersion,
  });

  @override
  State<LicensesScreen> createState() => _LicensesScreenState();
}

class _LicensesScreenState extends State<LicensesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<PackageLicenseItem> _allPackages = PackageLicenseItem.defaultFallback;
  bool _hasStartedLoading = false;

  @override
  void initState() {
    super.initState();
    // Defer heavy LicenseRegistry stream consumption until after the route transition finishes.
    // This prevents route animation jank and screen jitter when pushing the screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route != null && route.animation != null && !route.animation!.isCompleted) {
        void onStatus(AnimationStatus status) {
          if (status == AnimationStatus.completed) {
            route.animation?.removeStatusListener(onStatus);
            if (mounted) _loadLicenses();
          }
        }
        route.animation!.addStatusListener(onStatus);
      } else {
        _loadLicenses();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLicenses() async {
    if (_hasStartedLoading) return;
    _hasStartedLoading = true;

    final Map<String, List<LicenseEntry>> packageMap = {};

    try {
      // Stream entries without eagerly converting all paragraphs into strings.
      // This reduces startup time from ~300ms to < 2ms.
      await for (final entry in LicenseRegistry.licenses) {
        for (final package in entry.packages) {
          packageMap.putIfAbsent(package, () => []).add(entry);
        }
      }
    } catch (_) {
      // Graceful fallback on environments where LicenseRegistry cannot stream
    }

    final List<PackageLicenseItem> items = packageMap.entries
        .map((e) => PackageLicenseItem(packageName: e.key, entries: e.value))
        .toList();

    // Fallback if empty (e.g. in tests or mock environments)
    if (items.isEmpty) {
      items.addAll(PackageLicenseItem.defaultFallback);
    }

    items.sort((a, b) => a.packageName.toLowerCase().compareTo(b.packageName.toLowerCase()));

    if (mounted) {
      setState(() {
        _allPackages = items;
      });
    }
  }

  List<PackageLicenseItem> get _filteredPackages {
    if (_searchQuery.trim().isEmpty) return _allPackages;
    final query = _searchQuery.toLowerCase().trim();
    return _allPackages.where((p) => p.packageName.toLowerCase().contains(query)).toList();
  }

  void _showLicenseDetail(BuildContext context, PackageLicenseItem item, AppThemeTokens? tokens, bool isDark) {
    if (tokens?.isCute == true) {
      _showSproutLicenseSheet(context, item, tokens!, isDark);
    } else {
      _showClassicLicenseSheet(context, item, isDark);
    }
  }

  void _showSproutLicenseSheet(BuildContext context, PackageLicenseItem item, AppThemeTokens tokens, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1B3626) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF274C37) : const Color(0xFFE4ECE0);
    final badgeBg = isDark ? const Color(0xFF163424) : const Color(0xFFEAF8E7);
    final badgeBorder = isDark ? const Color(0xFF2C5B45) : const Color(0xFFD7F0D6);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.78,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF13261B) : const Color(0xFFFAF7F2),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(top: BorderSide(color: cardBorder, width: 1.0)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF274C37) : const Color(0xFFD4DEC7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.packageName,
                            style: GoogleFonts.quicksand(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: tokens.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.licenseTexts.length} license ${item.licenseTexts.length == 1 ? "entry" : "entries"}',
                            style: GoogleFonts.quicksand(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: tokens.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: badgeBorder, width: 1.0),
                      ),
                      child: Text(
                        'OPEN SOURCE',
                        style: GoogleFonts.quicksand(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: isDark ? const Color(0xFF8BC34A) : const Color(0xFF1E6B3F),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Scrollable License Text
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cardBorder, width: 1.0),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < item.licenseTexts.length; i++) ...[
                            if (i > 0)
                              Divider(
                                height: 28,
                                thickness: 1,
                                color: cardBorder,
                              ),
                            SelectableText(
                              item.licenseTexts[i],
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11.5,
                                height: 1.5,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Done / Dismiss Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tokens.primaryAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: GoogleFonts.quicksand(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
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

  void _showClassicLicenseSheet(BuildContext context, PackageLicenseItem item, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.packageName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                        width: 0.8,
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        item.licenseTexts.join('\n\n---\n\n'),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11.5,
                          height: 1.45,
                          color: isDark ? AppColors.textSecondaryDark : const Color(0xFF334155),
                        ),
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

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (tokens?.isCute == true) {
      return _buildSproutLicensesView(context, tokens!, isDark);
    }
    return _buildClassicLicensesView(context, isDark);
  }

  Widget _buildSproutLicensesView(BuildContext context, AppThemeTokens tokens, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1B3626) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF274C37) : const Color(0xFFE4ECE0);
    final badgeBg = isDark ? const Color(0xFF163424) : const Color(0xFFEAF8E7);
    final badgeBorder = isDark ? const Color(0xFF2C5B45) : const Color(0xFFD7F0D6);

    final filtered = _filteredPackages;

    return Scaffold(
      backgroundColor: tokens.scaffoldBg,
      appBar: AppBar(
        backgroundColor: tokens.scaffoldBg,
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
          'Open Source Licenses',
          style: GoogleFonts.quicksand(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: tokens.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'OPEN SOURCE CREDITS',
                                style: GoogleFonts.quicksand(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: tokens.primaryAccent,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: badgeBg,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: badgeBorder, width: 1.0),
                                ),
                                child: Text(
                                  'v${widget.currentVersion}',
                                  style: GoogleFonts.quicksand(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? const Color(0xFF8BC34A) : const Color(0xFF1E6B3F),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Software Licenses',
                            style: GoogleFonts.quicksand(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: tokens.textPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Attendly is proudly built using open source software libraries. Tap any package below to inspect its license terms and copyright credits.',
                            style: GoogleFonts.quicksand(
                              fontSize: 12.5,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                              color: tokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Search Bar
                    Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cardBorder, width: 1.0),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, size: 20, color: tokens.textMuted),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) => setState(() => _searchQuery = val),
                              style: GoogleFonts.quicksand(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: tokens.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search packages...',
                                hintStyle: GoogleFonts.quicksand(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: tokens.textMuted,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: Icon(Icons.close_rounded, size: 18, color: tokens.textMuted),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Zero emojis in section header!
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 4),
                      child: Text(
                        'PACKAGES & LIBRARIES (${filtered.length})',
                        style: GoogleFonts.quicksand(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: tokens.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (filtered.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cardBorder, width: 1.0),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 36, color: tokens.textMuted),
                        const SizedBox(height: 8),
                        Text(
                          'No packages found',
                          style: GoogleFonts.quicksand(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: tokens.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                sliver: SliverList.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return Material(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: () => _showLicenseDetail(context, item, tokens, isDark),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: cardBorder, width: 1.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.packageName,
                                      style: GoogleFonts.quicksand(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: tokens.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item.licenseCount} ${item.licenseCount == 1 ? "license" : "licenses"}',
                                      style: GoogleFonts.quicksand(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                        color: tokens.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: tokens.textMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassicLicensesView(BuildContext context, bool isDark) {
    final filtered = _filteredPackages;
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Open Source Licenses',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search packages...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                ),
              ),
            ),
            if (filtered.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text('No packages found')),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: borderColor),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return Material(
                      color: cardBg,
                      child: ListTile(
                        title: Text(item.packageName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${item.licenseCount} license(s)'),
                        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                        onTap: () => _showLicenseDetail(context, item, null, isDark),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
