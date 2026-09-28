import 'package:flutter/material.dart';

/// Personal calendar colors a member can choose (SRS 2.1.8).
const memberColors = [
  '#E57373',
  '#F06292',
  '#BA68C8',
  '#7986CB',
  '#4FC3F7',
  '#4DB6AC',
  '#81C784',
  '#FFB74D',
  '#A1887F',
  '#90A4AE',
];

Color hexColor(String? hex, {Color fallback = Colors.grey}) {
  if (hex == null || hex.length != 7 || !hex.startsWith('#')) return fallback;
  final value = int.tryParse(hex.substring(1), radix: 16);
  return value == null ? fallback : Color(0xFF000000 | value);
}

/// Text color that stays readable on [background].
Color onColor(Color background) =>
    background.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
