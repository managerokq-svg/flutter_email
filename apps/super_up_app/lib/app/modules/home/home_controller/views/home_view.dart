// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:s_translation/generated/l10n.dart';
import 'package:super_up/app/modules/home/mobile/calls_tab/views/calls_tab_view.dart';
import 'package:super_up/app/modules/home/mobile/rooms_tab/views/rooms_tab_view.dart';
import 'package:super_up/app/modules/home/mobile/users_tab/views/users_tab_view.dart';
import 'package:super_up_core/super_up_core.dart';

import '../../../../core/api_service/profile/profile_api_service.dart';
import '../../home_wide_modules/home/view/home_wide_view.dart';
import '../../mobile/settings_tab/views/settings_tab_view.dart';
import '../../mobile/story_tab/views/story_tab_view.dart';
import '../controllers/home_controller.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  late final HomeController controller;
  final sizer = GetIt.I.get<AppSizeHelper>();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    controller = HomeController(
      GetIt.I.get<ProfileApiService>(),
      context,
    );
    controller.onInit();
  }

  @override
  void dispose() {
    controller.onClose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (sizer.isWide(context)) {
      return const HomeWideView();
    }
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return ValueListenableBuilder<SLoadingState<int>>(
      valueListenable: controller,
      builder: (_, value, __) {
        return Scaffold(
          body: Stack(
            children: [
              // Tab content
              IndexedStack(
                index: _currentIndex,
                children: const [
                  RoomsTabView(),
                  StoryTabView(),
                  CallsTabView(),
                  UsersTabView(),
                  SettingsTabView(),
                ],
              ),
              // Floating pill navigation bar
              Positioned(
                left: 16,
                right: 16,
                bottom: bottomPadding + 12,
                child: _TelegramPillNavBar(
                  currentIndex: _currentIndex,
                  onTap: (index) => setState(() => _currentIndex = index),
                  items: [
                    _NavBarItem(
                      icon: CupertinoIcons.chat_bubble_2,
                      label: S.of(context).chats,
                      badgeCount: controller.totalChatUnRead,
                    ),
                    _NavBarItem(
                      icon: CupertinoIcons.play_circle,
                      label: S.of(context).stories,
                    ),
                    _NavBarItem(
                      icon: CupertinoIcons.phone,
                      label: S.of(context).phone,
                    ),
                    _NavBarItem(
                      icon: CupertinoIcons.person_2,
                      label: S.of(context).users,
                    ),
                    _NavBarItem(
                      icon: CupertinoIcons.settings,
                      label: S.of(context).settings,
                      badgeCount: controller
                              .versionCheckerController.value.isNeedUpdates
                          ? 1
                          : 0,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavBarItem {
  final IconData icon;
  final String label;
  final int badgeCount;

  const _NavBarItem({
    required this.icon,
    required this.label,
    this.badgeCount = 0,
  });
}

/// Telegram-style floating pill navigation bar
class _TelegramPillNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_NavBarItem> items;

  const _TelegramPillNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF2C2C2E).withValues(alpha: 0.75),
                      const Color(0xFF1C1C1E).withValues(alpha: 0.85),
                    ],
                  )
                : null,
            color:
                isDark ? null : const Color(0xFFF2F2F7).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.05),
              width: 0.5,
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: items.asMap().entries.map((entry) {
              return Expanded(
                child: _PillNavItem(
                  item: entry.value,
                  isSelected: entry.key == currentIndex,
                  onTap: () => onTap(entry.key),
                  isDark: isDark,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// Individual navigation item with animated icon and text
class _PillNavItem extends StatefulWidget {
  final _NavBarItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _PillNavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_PillNavItem> createState() => _PillNavItemState();
}

class _PillNavItemState extends State<_PillNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    if (widget.isSelected) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_PillNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward(from: 0.0);
      } else {
        _controller.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF007AFF);
    final inactiveColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.5);
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? activeColor.withValues(alpha: 0.18 * _controller.value)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Transform.scale(
                      scale: widget.isSelected ? _scaleAnimation.value : 1.0,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                        child: Icon(
                          widget.item.icon,
                          key: ValueKey(widget.isSelected),
                          size: 22,
                          color:
                              widget.isSelected ? activeColor : inactiveColor,
                        ),
                      ),
                    ),
                    if (widget.item.badgeCount > 0)
                      Positioned(
                        right: -10,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(minWidth: 18),
                          child: Text(
                            widget.item.badgeCount > 99
                                ? '99+'
                                : widget.item.badgeCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 1),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: widget.isSelected ? 10.5 : 10,
                    fontWeight:
                        widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: widget.isSelected ? activeColor : inactiveColor,
                  ),
                  child: Text(
                    widget.item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
