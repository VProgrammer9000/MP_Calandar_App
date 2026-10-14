import 'package:flutter/material.dart';

import '../models/calendar_event.dart';
import '../models/task_draft.dart';
import '../utils/dates.dart';

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
  const AddByPrompt({super.key});

  @override
  State<AddByPrompt> createState() => _AddByPromptState();
}

class _AddByPromptState extends State<AddByPrompt> {
  final _promptController = TextEditingController();

  // TODO: filled in by the assistant, the result sections are hidden while null
  TaskDraft? _readTask;
  final List<CalendarEvent> _proposedSlots = [];
  final Set<int> _pickedSlots = {};

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _readPrompt() {
    if (_promptController.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    // TODO: send the prompt to the LLM and fill _readTask and _proposedSlots
  }

  void _addPickedSlots() {
    // TODO: save the picked slots as events in the calendar
    Navigator.pop(context);
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
          onPressed: _readPrompt,
          child: const Text('Read it & find slots'),
        ),
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
          _buildSectionTitle('PROPOSED SLOTS'),
          for (var i = 0; i < _proposedSlots.length; i++)
            _buildSlotRow(i, _proposedSlots[i]),
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
