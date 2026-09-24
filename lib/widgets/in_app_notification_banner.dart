import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

enum InAppNotificationType { trade, reward, streak, alert, info }

class InAppNotificationPayload {
  final String title;
  final String message;
  final InAppNotificationType type;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final Duration duration;

  const InAppNotificationPayload({
    required this.title,
    required this.message,
    this.type = InAppNotificationType.info,
    this.actionLabel,
    this.onActionTap,
    this.duration = const Duration(milliseconds: 4200),
  });
}

class InAppNotificationBanner {
  static OverlayEntry? _currentEntry;
  static Timer? _autoDismissTimer;

  /// Show floating banner inside the DeviceFrame bounds
  static void show(BuildContext context, InAppNotificationPayload payload) {
    dismissCurrent();

    final overlayState = Overlay.of(context, rootOverlay: false);

    _currentEntry = OverlayEntry(
      builder: (context) => _InAppNotificationHost(
        payload: payload,
        onDismissed: () {
          _removeEntry();
        },
      ),
    );

    overlayState.insert(_currentEntry!);
  }

  static void dismissCurrent() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }

  static void _removeEntry() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _InAppNotificationHost extends StatefulWidget {
  final InAppNotificationPayload payload;
  final VoidCallback onDismissed;

  const _InAppNotificationHost({
    required this.payload,
    required this.onDismissed,
  });

  @override
  State<_InAppNotificationHost> createState() => _InAppNotificationHostState();
}

class _InAppNotificationHostState extends State<_InAppNotificationHost>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late AnimationController _progressController;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 240),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.7),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));

    _progressController = AnimationController(
      vsync: this,
      duration: widget.payload.duration,
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _dismissWithAnimation();
      }
    });

    _animController.forward();
    _progressController.forward();
  }

  void _pauseCountdown() {
    if (!_isPaused && mounted) {
      setState(() => _isPaused = true);
      _progressController.stop(canceled: false);
    }
  }

  void _resumeCountdown() {
    if (_isPaused && mounted) {
      setState(() => _isPaused = false);
      _progressController.forward();
    }
  }

  Future<void> _dismissWithAnimation() async {
    if (!mounted) return;
    await _animController.reverse();
    if (mounted) {
      widget.onDismissed();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final mediaQuery = MediaQuery.of(context);
    final topPadding =
        (mediaQuery.padding.top > 0 ? mediaQuery.padding.top : 44.0) + 8.0;

    final style = _resolveNotificationStyle(widget.payload.type, isDark);

    return Positioned(
      top: topPadding,
      left: 12.0,
      right: 12.0,
      child: Material(
        type: MaterialType.transparency,
        child: MouseRegion(
          onEnter: (_) => _pauseCountdown(),
          onExit: (_) => _resumeCountdown(),
          child: Listener(
            onPointerDown: (_) => _pauseCountdown(),
            onPointerUp: (_) => _resumeCountdown(),
            child: Dismissible(
              key: const Key('in_app_banner_dismissible'),
              direction: DismissDirection.up,
              onDismissed: (_) => widget.onDismissed(),
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.45)
                              : const Color(0xff0f172a).withOpacity(0.09),
                          blurRadius: 22,
                          spreadRadius: 0,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18.0),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xff1e293b).withOpacity(0.90)
                                : Colors.white.withOpacity(0.94),
                            borderRadius: BorderRadius.circular(18.0),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xff334155).withOpacity(0.7)
                                  : const Color(0xffe2e8f0),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14.0,
                                  vertical: 12.0,
                                ),
                                child: Row(
                                  children: [
                                    // 1. Category Icon Badge
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: style.iconBg,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: style.accentColor
                                              .withOpacity(0.3),
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Icon(
                                        style.icon,
                                        color: style.accentColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // 2. Title & Message Texts
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            widget.payload.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xff0f172a),
                                            ),
                                          ),
                                          const SizedBox(height: 2.0),
                                          Text(
                                            widget.payload.message,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 11.5,
                                              height: 1.25,
                                              color: isDark
                                                  ? const Color(0xff94a3b8)
                                                  : const Color(0xff64748b),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // 3. Quick Action CTA (Optional)
                                    if (widget.payload.actionLabel != null) ...[
                                      const SizedBox(width: 8),
                                      InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: () {
                                          _dismissWithAnimation();
                                          widget.payload.onActionTap?.call();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: style.ctaBg,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: style.accentColor
                                                  .withOpacity(0.3),
                                            ),
                                          ),
                                          child: Text(
                                            widget.payload.actionLabel!,
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: style.accentColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // 4. Countdown Progress Bar Indicator
                              AnimatedBuilder(
                                animation: _progressController,
                                builder: (context, child) {
                                  return Container(
                                    height: 2.5,
                                    width: double.infinity,
                                    color: isDark
                                        ? Colors.white.withOpacity(0.06)
                                        : const Color(0xff0f172a)
                                            .withOpacity(0.04),
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor:
                                          1.0 - _progressController.value,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: style.accentColor,
                                          borderRadius:
                                              BorderRadius.circular(1.5),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _NotificationStyle _resolveNotificationStyle(
      InAppNotificationType type, bool isDark) {
    switch (type) {
      case InAppNotificationType.trade:
        return _NotificationStyle(
          icon: Icons.trending_up_rounded,
          accentColor: const Color(0xff10b981), // Emerald
          iconBg: isDark
              ? const Color(0xff064e3b).withOpacity(0.7)
              : const Color(0xffecfdf5),
          ctaBg: isDark
              ? const Color(0xff064e3b).withOpacity(0.5)
              : const Color(0xffecfdf5),
        );
      case InAppNotificationType.reward:
        return _NotificationStyle(
          icon: Icons.workspace_premium_rounded,
          accentColor: const Color(0xfff59e0b), // Amber
          iconBg: isDark
              ? const Color(0xff78350f).withOpacity(0.6)
              : const Color(0xfffef3c7),
          ctaBg: isDark
              ? const Color(0xff78350f).withOpacity(0.5)
              : const Color(0xfffef3c7),
        );
      case InAppNotificationType.streak:
        return _NotificationStyle(
          icon: Icons.local_fire_department_rounded,
          accentColor: const Color(0xfff97316), // Orange
          iconBg: isDark
              ? const Color(0xff7c2d12).withOpacity(0.6)
              : const Color(0xfffff7ed),
          ctaBg: isDark
              ? const Color(0xff7c2d12).withOpacity(0.5)
              : const Color(0xfffff7ed),
        );
      case InAppNotificationType.alert:
        return _NotificationStyle(
          icon: Icons.warning_amber_rounded,
          accentColor: const Color(0xfff43f5e), // Rose
          iconBg: isDark
              ? const Color(0xff881337).withOpacity(0.6)
              : const Color(0xfffff1f2),
          ctaBg: isDark
              ? const Color(0xff881337).withOpacity(0.5)
              : const Color(0xfffff1f2),
        );
      case InAppNotificationType.info:
        return _NotificationStyle(
          icon: Icons.notifications_active_rounded,
          accentColor: const Color(0xff38bdf8), // Sky
          iconBg: isDark
              ? const Color(0xff0f172a)
              : const Color(0xfff1f5f9),
          ctaBg: isDark
              ? const Color(0xff1e293b)
              : const Color(0xffe2e8f0),
        );
    }
  }
}

class _NotificationStyle {
  final IconData icon;
  final Color accentColor;
  final Color iconBg;
  final Color ctaBg;

  _NotificationStyle({
    required this.icon,
    required this.accentColor,
    required this.iconBg,
    required this.ctaBg,
  });
}
