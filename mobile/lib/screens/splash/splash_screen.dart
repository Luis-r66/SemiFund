import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/session_provider.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/buttons.dart';
import '../../widgets/error_banner.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SessionProvider session = context.watch<SessionProvider>();

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: <Widget>[
              const Spacer(flex: 2),
              const AppLogo(size: 58),
              const SizedBox(height: 28),
              Text('SemiFund', style: AppTextStyles.h2),
              const SizedBox(height: 8),
              Text(
                'Tu tesorería, clara y compartida.',
                style: AppTextStyles.small.copyWith(color: AppColors.ink2),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
              if (session.bootstrapError != null)
                ErrorBanner(
                  message: session.bootstrapError!,
                  onRetry: session.retryBootstrap,
                )
              else
                Column(
                  children: <Widget>[
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Preparando tu tesorería...',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.ink3,
                      ),
                    ),
                  ],
                ),
              const Spacer(),
              if (session.bootstrapError != null)
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'Reintentar',
                    onPressed: session.retryBootstrap,
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
