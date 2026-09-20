import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_theme_tokens.dart';
import '../../core/theme/app_theme_registry.dart';

/// Floating capsule navigation bar for cute/sprout themes
class SproutFloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<ThemeNavItem> items;

  const SproutFloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).extension<AppThemeTokens>() ??
        (isDark ? AppThemeTokens.cuteSproutDark : AppThemeTokens.cuteSproutLight);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: tokens.navBgColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: tokens.navBorderColor,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: tokens.navShadowColor,
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final tabWidth = availableWidth / items.length;

              return Stack(
                children: [
                  // Smooth sliding active pill capsule
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeInOutCubic,
                    left: (currentIndex * tabWidth) + 1.0,
                    top: 2,
                    bottom: 2,
                    width: tabWidth - 2.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: tokens.navActivePillColor,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: tokens.navPillBorderColor,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),

                  // Foreground tab items (vertically centered across navbar height)
                  Positioned.fill(
                    child: Row(
                      children: List.generate(items.length, (index) {
                        final item = items[index];
                        final isSelected = currentIndex == index;

                        return Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              if (currentIndex != index) {
                                onTap(index);
                              }
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedScale(
                                  scale: isSelected ? 1.03 : 0.96,
                                  duration: const Duration(milliseconds: 200),
                                  child: _buildIcon(item, isSelected, tokens),
                                ),
                                const SizedBox(height: 3),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      item.label,
                                      style: GoogleFonts.quicksand(
                                        fontSize: isSelected ? 10.75 : 10.25,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                                        color: isSelected
                                            ? tokens.navActiveTextColor
                                            : tokens.navInactiveTextColor,
                                        letterSpacing: isSelected ? 0.0 : -0.1,
                                      ),
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(ThemeNavItem item, bool isSelected, AppThemeTokens tokens) {
    if (item.iconAssetPath != null) {
      return Opacity(
        opacity: isSelected ? 1.0 : 0.85,
        child: Image.asset(
          item.iconAssetPath!,
          width: 27,
          height: 27,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            isSelected ? item.activeIcon : item.inactiveIcon,
            size: 23,
            color: isSelected ? tokens.navActiveIconColor : tokens.navInactiveIconColor,
          ),
        ),
      );
    }

    return Icon(
      isSelected ? item.activeIcon : item.inactiveIcon,
      size: 23,
      color: isSelected ? tokens.navActiveIconColor : tokens.navInactiveIconColor,
    );
  }
}
