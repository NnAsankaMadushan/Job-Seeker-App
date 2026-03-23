import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppNavigationItem {
  const AppNavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class AppFloatingNavigationBar extends StatelessWidget {
  const AppFloatingNavigationBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  final List<AppNavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  static const double _barHeight = 84;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final shellBorderColor = isDark
        ? theme.colorScheme.primary.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.92);
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.34)
        : const Color(0xFF94A3B8).withValues(alpha: 0.18);
    final topHighlight = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.8);
    final shellGradient = [
      isDark ? const Color(0xE61A2537) : const Color(0xF5FFFFFF),
      isDark ? const Color(0xD90F172A) : const Color(0xE8F7FBFF),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: shellGradient,
            ),
            border: Border.all(color: shellBorderColor),
          ),
          child: SizedBox(
            height: _barHeight,
            child: Stack(
              children: [
                Positioned(
                  left: 28,
                  right: 28,
                  top: 0,
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          topHighlight,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        for (var index = 0; index < items.length; index++)
                          Expanded(
                            child: _AppNavigationBarItem(
                              item: items[index],
                              selected: selectedIndex == index,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                onItemSelected(index);
                              },
                            ),
                          ),
                      ],
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
}

class _AppNavigationBarItem extends StatelessWidget {
  const _AppNavigationBarItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppNavigationItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;
    final activeIconColor = isDark ? const Color(0xFFF8FAFC) : scheme.primary;
    final inactiveIconColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final bubbleTop = isDark
        ? scheme.primary.withValues(alpha: 0.34)
        : scheme.primary.withValues(alpha: 0.22);
    final bubbleBottom = isDark
        ? scheme.secondary.withValues(alpha: 0.22)
        : scheme.secondary.withValues(alpha: 0.12);
    final bubbleBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.72);
    final bubbleShadow = isDark
        ? scheme.primary.withValues(alpha: 0.2)
        : scheme.primary.withValues(alpha: 0.14);

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  width: selected ? 52 : 42,
                  height: selected ? 52 : 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(selected ? 18 : 16),
                    gradient: selected
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              bubbleTop,
                              bubbleBottom,
                            ],
                          )
                        : null,
                    color: selected ? null : Colors.transparent,
                    border: Border.all(
                      color: selected ? bubbleBorder : Colors.transparent,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: bubbleShadow,
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ]
                        : const [],
                  ),
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: selected ? 1 : 0),
                      duration: const Duration(milliseconds: 360),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, -2 * value),
                          child: Transform.scale(
                            scale: 1 + (0.08 * value),
                            child: child,
                          ),
                        );
                      },
                      child: Icon(
                        selected ? item.selectedIcon : item.icon,
                        size: selected ? 24 : 22,
                        color: selected ? activeIconColor : inactiveIconColor,
                      ),
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.only(top: 6),
                  height: 3,
                  width: selected ? 18 : 0,
                  decoration: BoxDecoration(
                    color: selected ? scheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
