import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'providers/business_provider.dart';
import 'services/notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await Hive.initFlutter();
  await NotificationService.initialize();

  final provider = BusinessProvider();
  await provider.init();

  if (provider.weeklyReminderEnabled) {
    await NotificationService.scheduleWeeklyReminder(
      weekday: DateTime.monday,
      hour: 15,
      minute: 0,
    );
  }

  runApp(
    ChangeNotifierProvider.value(value: provider, child: const TaxRadarApp()),
  );
}
