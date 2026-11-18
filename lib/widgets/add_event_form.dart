import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/task_draft.dart';
import '../models/task_label.dart';
import '../utils/dates.dart';
import '../utils/slot_finder.dart';

class AddEventForm extends StatefulWidget {
  const AddEventForm({super.key});

  @override
  State<AddEventForm> createState() => _AddEventFormState();
}

class _AddEventFormState extends State<AddEventForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  DateTime? _start;
  DateTime? _end;
  String? _label;
  bool _fixed = false;
  Priority _priority = Priority.normal;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: dateOnly(initial),
      firstDate: dateOnly(DateTime.now()),
      lastDate: addDays(DateTime.now(), 730),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    return time == null
        ? null
        : DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickStart() async {
    final value = await _pickDateTime(_start ?? DateTime.now());
    if (value != null) setState(() => _start = value);
  }

  Future<void> _pickEnd() async {
    final value = await _pickDateTime(
      _end ?? (_start ?? DateTime.now()).add(const Duration(hours: 1)),
    );
    if (value != null) setState(() => _end = value);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_start == null || _end == null || !_end!.isAfter(_start!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a valid start and end')),
      );
      return;
    }

    final draft = TaskDraft(
      title: _title.text.trim(),
      description: _description.text.trim(),
      location: _location.text.trim().isEmpty ? null : _location.text.trim(),
      earliestStart: _start,
      deadline: _end,
      length: _end!.difference(_start!),
      label: _label,
      fixed: _fixed,
      priority: _priority,
    );
    myEvents.addAll(
        findSlots(draft.withId(newModelId('task')), myEvents, DateTime.now()));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _labelText('title'),
          TextFormField(
            controller: _title,
            decoration: _decoration(),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Give it a title'
                : null,
          ),
          const SizedBox(height: 16),
          _labelText('description'),
          TextFormField(
            controller: _description,
            maxLines: 2,
            decoration: _decoration(),
          ),
          const SizedBox(height: 16),
          _labelText('location'),
          TextFormField(
            controller: _location,
            decoration: _decoration(hint: 'Room 310, Library, Online'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _dateField('start', _start, _pickStart)),
              const SizedBox(width: 12),
              Expanded(child: _dateField('end', _end, _pickEnd)),
            ],
          ),
          const SizedBox(height: 16),
          _labelText('label'),
          _labels(),
          const SizedBox(height: 16),
          _labelText('type'),
          _type(),
          const SizedBox(height: 16),
          _labelText('priority'),
          _priorities(),
          const SizedBox(height: 12),
          const Divider(height: 2, thickness: 2, color: Colors.black),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.all(18),
            ),
            onPressed: _save,
            child: const Text('Add event'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _dateField(String name, DateTime? value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelText(name),
        TextFormField(
          key: ValueKey(value),
          readOnly: true,
          onTap: onTap,
          initialValue: value == null
              ? ''
              : '${formatShortDate(value)} ${formatTime(value)}',
          decoration: _decoration(
            icon: const Icon(Icons.event_outlined, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _labels() => Wrap(
        spacing: 6,
        children: [
          for (final label in defaultLabels)
            ChoiceChip(
              label: Text(label.name),
              selected: _label == label.name,
              onSelected: (value) =>
                  setState(() => _label = value ? label.name : null),
            ),
        ],
      );

  Widget _type() => SegmentedButton<bool>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: false, label: Text('Flexible')),
          ButtonSegment(value: true, label: Text('Fixed')),
        ],
        selected: {_fixed},
        onSelectionChanged: (value) => setState(() => _fixed = value.first),
      );

  Widget _priorities() => RadioGroup<Priority>(
        groupValue: _priority,
        onChanged: (value) {
          if (value != null) setState(() => _priority = value);
        },
        child: Row(
          children: [
            for (final priority in Priority.values)
              Expanded(
                child: RadioListTile<Priority>(
                  value: priority,
                  contentPadding: EdgeInsets.zero,
                  title: Text(priority.name[0].toUpperCase()),
                ),
              ),
          ],
        ),
      );

  Widget _labelText(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(color: Colors.black54)),
      );

  InputDecoration _decoration({String? hint, Widget? icon}) => InputDecoration(
        isDense: true,
        hintText: hint,
        suffixIcon: icon,
        border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
      );
}
