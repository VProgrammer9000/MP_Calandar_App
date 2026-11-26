import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../services/storage_service.dart';
import '../utils/dates.dart';

// Layout follows wireframe 1m. Every setting here is saved and changes how
// the assistant and the planner work, the small text under each says how.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _taskLengths = [30, 60, 90, 120];

  static String languageName(AssistantLanguage language) =>
      language == AssistantLanguage.english ? 'English' : '한국어 (Korean)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder<AppSettings>(
          valueListenable: mySettings,
          builder: (context, settings, _) => ListView(
            children: [
              _buildHeader(context),
              const Divider(height: 2, thickness: 2, color: Colors.black),
              _buildSectionTitle('PROFILE'),
              _buildRow(
                title: 'Your name',
                subtitle: 'The assistant calls you by this name',
                value: settings.name.isEmpty ? 'Not set' : settings.name,
                onTap: () => _editName(context, settings),
              ),
              _buildSectionTitle('PLANNING'),
              _buildRow(
                title: 'Day starts',
                subtitle: 'New tasks are not planned before this time',
                value: formatMinutes(settings.workStartMinutes),
                onTap: () => _editHours(context, settings, start: true),
              ),
              const Divider(height: 1),
              _buildRow(
                title: 'Day ends',
                subtitle: 'New tasks are not planned after this time',
                value: formatMinutes(settings.workEndMinutes),
                onTap: () => _editHours(context, settings, start: false),
              ),
              const Divider(height: 1),
              _buildRow(
                title: 'Default task length',
                subtitle: "Used when you don't say how long a task takes",
                value: formatDuration(
                  Duration(minutes: settings.defaultTaskMinutes),
                ),
                onTap: () => _editTaskLength(context, settings),
              ),
              _buildSectionTitle('ASSISTANT'),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                activeThumbColor: Colors.white,
                activeTrackColor: Colors.black,
                title: const Text('Ask before changing my calendar'),
                subtitle: const Text(
                  'Show the changes from the chat first. When off they are '
                  'put in your calendar right away',
                ),
                value: settings.askBeforeChanging,
                onChanged: (value) =>
                    saveSettings(settings.copyWith(askBeforeChanging: value)),
              ),
              const Divider(height: 1),
              _buildRow(
                title: 'Assistant language',
                subtitle: 'The language the assistant answers in',
                value: languageName(settings.language),
                onTap: () => _editLanguage(context, settings),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 40, 20, 20),
                child: Text(
                  'Settings are saved on this device.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PREFERENCES',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Settings',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.grey, width: 2),
              shape: const RoundedRectangleBorder(),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.red,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const Divider(height: 2, thickness: 2, color: Colors.black),
      ],
    );
  }

  Widget _buildRow({
    required String title,
    required String subtitle,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(color: Colors.grey)),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }

  Future<void> _editName(BuildContext context, AppSettings settings) async {
    final controller = TextEditingController(text: settings.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Like Viktor'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null) await saveSettings(settings.copyWith(name: name.trim()));
  }

  Future<void> _editHours(
    BuildContext context,
    AppSettings settings, {
    required bool start,
  }) async {
    final minutes = start ? settings.workStartMinutes : settings.workEndMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      // the rest of the app uses 24 hour times
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !context.mounted) return;

    final newMinutes = picked.hour * 60 + picked.minute;
    final newStart = start ? newMinutes : settings.workStartMinutes;
    final newEnd = start ? settings.workEndMinutes : newMinutes;
    if (newStart >= newEnd) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The day has to end after it starts')),
      );
      return;
    }
    await saveSettings(
      settings.copyWith(workStartMinutes: newStart, workEndMinutes: newEnd),
    );
  }

  Future<void> _editTaskLength(
    BuildContext context,
    AppSettings settings,
  ) async {
    final minutes = await _pickOne<int>(
      context,
      title: 'Default task length',
      options: _taskLengths,
      selected: settings.defaultTaskMinutes,
      label: (minutes) => formatDuration(Duration(minutes: minutes)),
    );
    if (minutes != null) {
      await saveSettings(settings.copyWith(defaultTaskMinutes: minutes));
    }
  }

  Future<void> _editLanguage(BuildContext context, AppSettings settings) async {
    final language = await _pickOne<AssistantLanguage>(
      context,
      title: 'Assistant language',
      options: AssistantLanguage.values,
      selected: settings.language,
      label: languageName,
    );
    if (language != null) {
      await saveSettings(settings.copyWith(language: language));
    }
  }

  // a dialog with radio buttons, gives back the option that was tapped
  Future<T?> _pickOne<T>(
    BuildContext context, {
    required String title,
    required List<T> options,
    required T selected,
    required String Function(T) label,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(title),
        children: [
          RadioGroup<T>(
            groupValue: selected,
            onChanged: (value) => Navigator.pop(context, value),
            child: Column(
              children: [
                for (final option in options)
                  RadioListTile<T>(
                    value: option,
                    activeColor: Colors.black,
                    title: Text(label(option)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
