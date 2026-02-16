import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'router/app_router.dart';

class TaxRadarApp extends StatelessWidget {
  const TaxRadarApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.router(context);
    return MaterialApp.router(
      title: '세금 레이더',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
