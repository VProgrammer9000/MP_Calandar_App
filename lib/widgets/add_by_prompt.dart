import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../data/sample_data.dart';
import '../models/calendar_event.dart';
import '../models/task_draft.dart';
import '../services/llm_service.dart';
import '../utils/dates.dart';
import '../utils/slot_finder.dart';

const _examplePrompts = [
  'Study 6h before Friday',
  'Gym 3x this week',
];

// Black block button used for the main actions on this page
final _blackButtonStyle = TextButton.styleFrom(
  backgroundColor: Colors.black,
  foregroundColor: Colors.white,
  disabledBackgroundColor: Colors.black26,
  disabledForegroundColor: Colors.white,
  shape: const RoundedRectangleBorder(),
  alignment: Alignment.centerLeft,
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
);

// 1g: the user describes the task in their own words, the assistant reads it
// and proposes time slots that can be added to the calendar
class AddByPrompt extends StatefulWidget {
  // only used by the tests, so they don't call the real API
  final http.Client? client;
  const AddByPrompt({super.key, this.client});

  @override
  State<AddByPrompt> createState() => _AddByPromptState();
}

class _AddByPromptState extends State<AddByPrompt> {
  final _promptController = TextEditingController();

  // filled in by the assistant, the result sections are hidden while null
  TaskDraft? _readTask;
  final List<CalendarEvent> _proposedSlots = [];
  final Set<int> _pickedSlots = {};
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _readPrompt() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _errorMessage = null;
      _readTask = null;
      _proposedSlots.clear();
      _pickedSlots.clear();
    });

    try {
      final task = await readTaskFromPrompt(prompt, client: widget.client);
      final taskWithId =
          task.id == null ? task.withId(newModelId('task')) : task;
      final slots = findSlots(taskWithId, myEvents, DateTime.now());
      if (!mounted) return;
      setState(() {
        _readTask = taskWithId;
        _proposedSlots.addAll(slots);
        // all of them are picked at first, the user can remove some
        _pickedSlots.addAll(List.generate(slots.length, (i) => i));
      });
    } on LlmException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addPickedSlots() {
    for (final index in _pickedSlots) {
      myEvents.add(_proposedSlots[index]);
    }
    Navigator.pop(context, _readTask);
  }

  // shown when the blocks don't add up to the whole task
  String? _slotWarning() {
    if (_proposedSlots.isEmpty) {
      return 'No free time found before the deadline.';
    }
    var foundMinutes = 0;
    for (final slot in _proposedSlots) {
      foundMinutes += slot.end.difference(slot.start).inMinutes;
    }
    final neededMinutes = _readTask!.length?.inMinutes ?? 60;
    if (foundMinutes < neededMinutes) {
      return 'Only found ${formatDuration(Duration(minutes: foundMinutes))} '
          'of ${formatDuration(Duration(minutes: neededMinutes))} '
          'before the deadline.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const Text(
          'describe it in your own words',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _promptController,
          minLines: 3,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.zero),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Colors.black, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final example in _examplePrompts)
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black54,
                  side: const BorderSide(color: Colors.black26),
                  shape: const RoundedRectangleBorder(),
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontSize: 12),
                ),
                onPressed: () {
                  setState(() => _promptController.text = example);
                },
                child: Text(example),
              ),
          ],
        ),
        const SizedBox(height: 16),
        TextButton(
          style: _blackButtonStyle,
          onPressed: _loading ? null : _readPrompt,
          child: Text(_loading ? 'Reading...' : 'Read it & find slots'),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700)),
        ],
        if (_readTask != null) ...[
          const SizedBox(height: 20),
          const Divider(height: 2, thickness: 2, color: Colors.black),
          _buildSectionTitle('WHAT IT READ'),
          _buildReadRow('title', _readTask!.title),
          _buildReadRow(
            'length',
            _readTask!.length == null ? '' : formatDuration(_readTask!.length!),
          ),
          _buildReadRow(
            'deadline',
            _readTask!.deadline == null
                ? ''
                : formatShortDate(_readTask!.deadline!),
          ),
          _buildReadRow('type', _readTask!.fixed ? 'Fixed' : 'Flexible'),
          _buildReadRow('label', _readTask!.label ?? ''),
          if (_readTask!.location != null)
            _buildReadRow('location', _readTask!.location!),
          _buildSectionTitle('PROPOSED SLOTS'),
          for (var i = 0; i < _proposedSlots.length; i++)
            _buildSlotRow(i, _proposedSlots[i]),
          if (_slotWarning() != null) ...[
            const SizedBox(height: 12),
            Text(_slotWarning()!, style: TextStyle(color: Colors.red.shade700)),
          ],
          const SizedBox(height: 16),
          const Divider(height: 2, thickness: 2, color: Colors.black),
          const SizedBox(height: 16),
          TextButton(
            style: _blackButtonStyle,
            onPressed: _pickedSlots.isEmpty ? null : _addPickedSlots,
            child: Text(
              'Add ${_pickedSlots.length} '
              '${_pickedSlots.length == 1 ? 'block' : 'blocks'}',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 1,
          color: Colors.red.shade700,
        ),
      ),
    );
  }

  Widget _buildReadRow(String name, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              name,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildSlotRow(int index, CalendarEvent slot) {
    final picked = _pickedSlots.contains(index);

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: CheckboxListTile(
        value: picked,
        activeColor: Colors.black,
        contentPadding: EdgeInsets.zero,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _pickedSlots.add(index);
            } else {
              _pickedSlots.remove(index);
            }
          });
        },
        title: Row(
          children: [
            Container(width: 3, height: 36, color: Colors.red.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(slot.title),
                  Text(
                    '${formatShortDate(slot.start)} · '
                    '${formatTime(slot.start)}-${formatTime(slot.end)}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
