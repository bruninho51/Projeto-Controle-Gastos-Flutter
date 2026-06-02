import 'package:flutter/material.dart';

class DashboardCardConfig {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final bool isCount;

  const DashboardCardConfig({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.isCount = false,
  });
}
