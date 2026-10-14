import 'package:flutter/material.dart';

import '../models/task_draft.dart';
import '../models/task_label.dart';
import '../utils/dates.dart';

// null means the task stays one block
const _splitOptions = <Duration?>[
  null,
  Duration(minutes: 30),
  Duration(hours: 1),
  Duration(hours: 2),
  Duration(hours: 3),
];

// 1h: add a task by filling in every field yourself
class AddByForm extends StatefulWidget {
  const AddByForm({super.key});

  @override
  State<AddByForm> createState() => _AddByFormState();
}

class _AddByFormState extends State<AddByForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _startController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _lengthController = TextEditingController();

  DateTime? _earliestStart;
  DateTime? _deadline;
  Duration? _splitInto;
  String? _label;
  bool _fixed = false;
  Priority _priority = Priority.normal;

  @override
  void dispose() {
    _titleController.dispose();
    _startController.dispose();
    _deadlineController.dispose();
    _lengthController.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final today = dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _earliestStart ?? today,
      firstDate: today,
      lastDate: addDays(today, 365 * 2),
    );
    if (picked == null) return;
    setState(() {
      _earliestStart = picked;
      _startController.text = formatShortDate(picked);
    });
  }

  Future<void> _pickDeadline() async {
    final first = _earliestStart ?? dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _deadline != null && !_deadline!.isBefore(first) ? _deadline! : first,
      firstDate: first,
      lastDate: addDays(first, 365 * 2),
    );
    if (picked == null) return;
    setState(() {
      _deadline = picked;
      _deadlineController.text = formatShortDate(picked);
    });
  }

  // "1.5" or "1,5" -> 1h 30m
  Duration? _parseLength(String text) {
    final hours = double.tryParse(text.trim().replaceAll(',', '.'));
    if (hours == null || hours <= 0) return null;
    return Duration(minutes: (hours * 60).round());
  }

  void _schedule() {
    if (!_formKey.currentState!.validate()) return;

    final task = TaskDraft(
      title: _titleController.text.trim(),
      earliestStart: _earliestStart,
      deadline: _deadline,
      length: _parseLength(_lengthController.text),
      splitInto: _splitInto,
      label: _label,
      fixed: _fixed,
      priority: _priority,
    );
    // TODO: give the task to the scheduler so it finds free slots
    Navigator.pop(context, task);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _fieldLabel('title'),
          TextFormField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            decoration: _inputDecoration(),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Give it a title'
                : null,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('earliest start'),
                    TextFormField(
                      controller: _startController,
                      readOnly: true,
                      onTap: _pickStart,
                      decoration: _inputDecoration(
                        suffixIcon: const Icon(Icons.event_outlined, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('deadline'),
                    TextFormField(
                      controller: _deadlineController,
                      readOnly: true,
                      onTap: _pickDeadline,
                      decoration: _inputDecoration(
                        suffixIcon: const Icon(Icons.event_outlined, size: 18),
                      ),
                      validator: (_) => _deadline != null &&
                              _earliestStart != null &&
                              _deadline!.isBefore(_earliestStart!)
                          ? 'Before the start'
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('length'),
                    TextFormField(
                      controller: _lengthController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _inputDecoration(suffixText: 'h'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        return _parseLength(value) == null
                            ? 'Hours, like 1.5'
                            : null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('split into'),
                    DropdownButtonFormField<Duration?>(
                      initialValue: _splitInto,
                      isExpanded: true,
                      decoration: _inputDecoration(),
                      items: [
                        for (final option in _splitOptions)
                          DropdownMenuItem(
                            value: option,
                            child: Text(
                              option == null
                                  ? 'One block'
                                  : '${formatDuration(option)} blocks',
                            ),
                          ),
                      ],
                      onChanged: (value) => setState(() => _splitInto = value),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _fieldLabel('label'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final label in defaultLabels)
                ChoiceChip(
                  selected: _label == label.name,
                  showCheckmark: false,
                  selectedColor: Colors.grey.shade300,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.black26),
                  shape: const RoundedRectangleBorder(),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  labelPadding: const EdgeInsets.only(left: 2, right: 4),
                  avatarBoxConstraints: const BoxConstraints.tightFor(
                    width: 14,
                    height: 14,
                  ),
                  avatar: Container(width: 10, height: 10, color: label.color),
                  label: Text(label.name, style: const TextStyle(fontSize: 11)),
                  onSelected: (selected) {
                    setState(() => _label = selected ? label.name : null);
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          _fieldLabel('type'),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: false, label: Text('Flexible')),
                ButtonSegment(value: true, label: Text('Fixed')),
              ],
              selected: {_fixed},
              onSelectionChanged: (selection) {
                setState(() => _fixed = selection.first);
              },
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: Colors.black,
                selectedForegroundColor: Colors.white,
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black),
                shape: const RoundedRectangleBorder(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _fieldLabel('priority'),
          RadioGroup<Priority>(
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
                      activeColor: Colors.black,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      title: Text(
                        priority.name[0].toUpperCase() +
                            priority.name.substring(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 2, thickness: 2, color: Colors.black),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            ),
            onPressed: _schedule,
            child: const Text('Schedule it'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.black),
              shape: const RoundedRectangleBorder(),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
    );
  }

  InputDecoration _inputDecoration({String? suffixText, Widget? suffixIcon}) {
    return InputDecoration(
      isDense: true,
      suffixText: suffixText,
      suffixIcon: suffixIcon,
      border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Colors.black, width: 1.5),
      ),
    );
  }
}
