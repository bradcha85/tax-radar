import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'providers/business_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await Hive.initFlutter();

  final provider = BusinessProvider();
  await provider.init();

  runApp(
    ChangeNotifierProvider.value(value: provider, child: const TaxRadarApp()),
  );
}
