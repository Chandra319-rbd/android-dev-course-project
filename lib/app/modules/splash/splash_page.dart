import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'splash_controller.dart';

/// Chinese-style splash screen
class SplashPage extends GetView<SplashController> {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.chineseRed, AppColors.chineseRedDark],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Chinese-style decorative border
              _buildDecorativeBorder(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // App icon/logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.warmCream,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.temple_buddhist,
                        size: 64,
                        color: AppColors.chineseRed,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // App name in Chinese style
                    const Text(
                      '村庄探索',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.imperialGold,
                        letterSpacing: 8,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // English subtitle
                    Text(
                      'Village Explorer',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.warmCream.withValues(alpha: 0.9),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Loading indicator
              Obx(
                () => Column(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.imperialGold.withValues(alpha: 0.8),
                        ),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      controller.loadingText.value,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.warmCream.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Version info
              Text(
                'v1.0.0',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.warmCream.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Build decorative Chinese-style border
  Widget _buildDecorativeBorder({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.imperialGold.withValues(alpha: 0.5),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.imperialGold.withValues(alpha: 0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }
}
