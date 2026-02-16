import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'providers/business_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final provider = BusinessProvider();
  await provider.init();

  runApp(
    ChangeNotifierProvider.value(value: provider, child: const TaxRadarApp()),
  );
}
