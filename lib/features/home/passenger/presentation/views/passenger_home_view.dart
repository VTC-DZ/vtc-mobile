// lib/features/passenger/presentation/views/passenger_home_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/app_scaffold.dart';

/// Step 5 — Passenger Home screen.
///
/// Shows a welcome / onboarding tooltip on the very first visit.
/// The tooltip is dismissed once the user taps the primary CTA or the overlay.
class PassengerHomeView extends StatefulWidget {
  const PassengerHomeView({super.key});

  @override
  State<PassengerHomeView> createState() => _PassengerHomeViewState();
}

class _PassengerHomeViewState extends State<PassengerHomeView>
    with TickerProviderStateMixin {
  late final AnimationController _welcomeController;
  late final Animation<double> _welcomeFade;
  late final Animation<Offset> _welcomeSlide;

  bool _showWelcome = true;

  @override
  void initState() {
    super.initState();
    _welcomeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _welcomeFade = CurvedAnimation(
      parent: _welcomeController,
      curve: Curves.easeOut,
    );
    _welcomeSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _welcomeController,
      curve: Curves.easeOut,
    ));

    // Auto-show the welcome tooltip after a brief delay.
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _welcomeController.forward();
    });
  }

  @override
  void dispose() {
    _welcomeController.dispose();
    super.dispose();
  }

  void _dismissWelcome() {
    _welcomeController.reverse().then((_) {
      if (mounted) setState(() => _showWelcome = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Stack(
        children: [
          // ── Main content ────────────────────────────────────────────────────
          _HomeContent(),

          // ── Welcome tooltip overlay ─────────────────────────────────────────
          if (_showWelcome)
            GestureDetector(
              onTap: _dismissWelcome,
              behavior: HitTestBehavior.translucent,
              child: Container(
                color: AppColors.black.withValues(alpha: 0.45),
                child: Center(
                  child: FadeTransition(
                    opacity: _welcomeFade,
                    child: SlideTransition(
                      position: _welcomeSlide,
                      child: _WelcomeTooltipCard(
                        onDismiss: _dismissWelcome,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main home content (placeholder map + bottom sheet stub)
// ─────────────────────────────────────────────────────────────────────────────

class _HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Top bar ─────────────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Row(
            children: [
              // Avatar placeholder
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1.5.w,
                  ),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 22.w,
                ),
              ),

              SizedBox(width: 12.w),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good to see you 👋',
                    style: AppTextStyles.bodySmall(context),
                  ),
                  Text(
                    'Where to?',
                    style: AppTextStyles.headingSmall(context),
                  ),
                ],
              ),

              const Spacer(),

              // Notification bell
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.borderDefault(context),
                    width: 1.5.w,
                  ),
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 20.w,
                  color: AppColors.text(context),
                ),
              ),
            ],
          ),
        ),

        // ── Map placeholder ─────────────────────────────────────────────────
        Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20.w),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: AppColors.borderDefault(context),
                width: 1.w,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: Stack(
                children: [
                  // Grid pattern to simulate a map
                  CustomPaint(
                    painter: _MapGridPainter(context: context),
                    child: const SizedBox.expand(),
                  ),

                  // Center pin
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 16.r,
                                spreadRadius: 4.r,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.my_location_rounded,
                            color: AppColors.white,
                            size: 24.w,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Container(
                          width: 10.w,
                          height: 10.w,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Map label
                  Positioned(
                    bottom: 16.h,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface(context),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                              color: AppColors.borderDefault(context)),
                        ),
                        child: Text(
                          'Map coming soon',
                          style: AppTextStyles.labelSmall(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Bottom search bar ────────────────────────────────────────────────
        Container(
          margin: EdgeInsets.all(20.w),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
                color: AppColors.borderDefault(context), width: 1.5.w),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.06),
                blurRadius: 16.r,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                size: 20.w,
                color: AppColors.textSecondary(context),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Where do you want to go?',
                  style: AppTextStyles.bodyMedium(context),
                ),
              ),
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.near_me_rounded,
                  size: 16.w,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Welcome tooltip card (shown on first visit)
// ─────────────────────────────────────────────────────────────────────────────

class _WelcomeTooltipCard extends StatelessWidget {
  const _WelcomeTooltipCard({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Container(
        padding: EdgeInsets.all(28.w),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.2),
              blurRadius: 32.r,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon badge
            Container(
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primaryDark,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 20.r,
                    spreadRadius: 2.r,
                  ),
                ],
              ),
              child: Icon(
                Icons.celebration_rounded,
                size: 36.w,
                color: AppColors.white,
              ),
            ),

            SizedBox(height: 24.h),

            Text(
              'Welcome aboard! 🎉',
              style: AppTextStyles.headingMedium(context),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 12.h),

            Text(
              'Your account is all set. Start by searching for a destination — your first ride is just a tap away!',
              style: AppTextStyles.bodyMedium(context),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 28.h),

            // CTA button
            GestureDetector(
              onTap: onDismiss,
              child: Container(
                width: double.infinity,
                height: 52.h,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Center(
                  child: Text(
                    'Let\'s go!',
                    style: AppTextStyles.labelLarge(context),
                  ),
                ),
              ),
            ),

            SizedBox(height: 12.h),

            Text(
              'Tap anywhere to dismiss',
              style: AppTextStyles.labelSmall(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom painter: map grid background
// ─────────────────────────────────────────────────────────────────────────────

class _MapGridPainter extends CustomPainter {
  _MapGridPainter({required this.context});

  final BuildContext context;

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8EAED);

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;

    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw a couple of "road" lines.
    final roadPaint = Paint()
      ..color = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD5D8DC)
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.2, 0),
      Offset(size.width * 0.3, size.height),
      roadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.4),
      Offset(size.width, size.height * 0.55),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.6, 0),
      Offset(size.width * 0.75, size.height),
      roadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
