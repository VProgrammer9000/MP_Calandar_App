import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../screens/settings_screen.dart';

// A small line on the AI screens that shows the settings they use right now.
// Tapping it opens the settings page, and the line updates when you come back.
class SettingsSummary extends StatelessWidget {
  final String Function(AppSettings settings) text;
  final EdgeInsets padding;

  const SettingsSummary({
    super.key,
    required this.text,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettings>(
      valueListenable: mySettings,
      builder: (context, settings, _) => InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        ),
        child: Padding(
          padding: padding,
          child: Row(
            children: [
              const Icon(Icons.tune, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text(settings),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
