import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/tax_calculator.dart';

enum WeatherSize { large, small }

class WeatherIcon extends StatelessWidget {
  final TaxWeather weather;
  final WeatherSize size;

  const WeatherIcon({
    super.key,
    required this.weather,
    this.size = WeatherSize.large,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = _emoji;
    final label = _label;
    final color = _color;
    final bgColor = _bgColor;

    if (size == WeatherSize.large) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.textTheme.titleMedium?.copyWith(
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    // Small
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String get _emoji {
    switch (weather) {
      case TaxWeather.sunny:
        return '☀️';
      case TaxWeather.cloudy:
        return '⛅';
      case TaxWeather.stormy:
        return '⛈️';
    }
  }

  String get _label {
    switch (weather) {
      case TaxWeather.sunny:
        return '맑음';
      case TaxWeather.cloudy:
        return '보통';
      case TaxWeather.stormy:
        return '주의';
    }
  }

  Color get _color {
    switch (weather) {
      case TaxWeather.sunny:
        return AppColors.success;
      case TaxWeather.cloudy:
        return AppColors.warning;
      case TaxWeather.stormy:
        return AppColors.danger;
    }
  }

  Color get _bgColor {
    switch (weather) {
      case TaxWeather.sunny:
        return AppColors.successLight;
      case TaxWeather.cloudy:
        return AppColors.warningLight;
      case TaxWeather.stormy:
        return AppColors.dangerLight;
    }
  }
}
