import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../data/sample_data.dart';
import '../models/calendar_change.dart';
import '../models/calendar_event.dart';
import '../services/chat_service.dart';
import '../services/llm_service.dart';
import '../utils/dates.dart';

enum PreviewTab { calendar, changes }

class ChatScreen extends StatefulWidget {
  // only used by the tests, so they don't call the real API
  final http.Client? client;

  const ChatScreen({super.key, this.client});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

// One bubble in the chat. The plan is only set on answers from the assistant.
class _Message {
  final String text;
  final bool isUser;
  final ChatPlan? plan;
  // null until the user accepts or rejects the plan
  final bool? accepted;

  const _Message(
    this.text, {
    this.isUser = false,
    this.plan,
    this.accepted,
  });

  // the changes can be reviewed until the user has accepted or rejected them
  bool get showReview =>
      plan != null && plan!.changes.isNotEmpty && accepted == null;

  // What the LLM gets to see of this message when the next one is sent.
  // Errors are left out, they were never an answer from the LLM.
  Map<String, String>? toHistory() {
    if (isUser) return {'role': 'user', 'content': text};
    if (plan == null) return null;
    return _assistantTurn(text, plan!, accepted);
  }
}

// An answer from the LLM for the history, with the changes it proposed and
// whether the user accepted them
Map<String, String> _assistantTurn(
    String reply, ChatPlan plan, bool? accepted) {
  if (plan.changes.isEmpty) return {'role': 'assistant', 'content': reply};

  final status = switch (accepted) {
    true => 'The user accepted these, they are in the calendar now:',
    false => 'The user rejected these, nothing was changed:',
    null => 'Not accepted yet, so they are not in the calendar:',
  };
  final changes = plan.changes.map((c) => '- ${c.describe()}').join('\n');
  return {'role': 'assistant', 'content': '$reply\n\n$status\n$changes'};
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final List<_Message> _messages = [];
  bool _loading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    // the chat so far, before the new message is added to it
    final history = [
      for (final m in _messages)
        if (m.toHistory() != null) m.toHistory()!,
    ];
    setState(() {
      _messages.add(_Message(message, isUser: true));
      _messageController.clear();
      _loading = true;
    });

    try {
      final plan = await planChanges(message, myEvents,
          history: history, client: widget.client);
      if (!mounted) return;
      setState(() => _messages.add(_Message(plan.reply, plan: plan)));
    } on LlmException catch (e) {
      if (!mounted) return;
      setState(() => _messages.add(_Message(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openPreview(_Message message) async {
    // the chat up to and with this answer, so the review page can refine it
    final index = _messages.indexOf(message);
    final history = [
      for (final m in _messages.take(index + 1))
        if (m.toHistory() != null) m.toHistory()!,
    ];

    final result = await Navigator.of(context).push<(bool, ChatPlan)>(
      MaterialPageRoute(
        builder: (_) => ChangePreviewScreen(
          plan: message.plan!,
          history: history,
          client: widget.client,
        ),
      ),
    );
    // null means the user went back without deciding
    if (result == null || !mounted) return;
    final (accepted, plan) = result;
    // a plan can only be accepted or rejected once. The plan can be a refined
    // one, so the next messages know what was really accepted
    setState(() {
      _messages[_messages.indexOf(message)] =
          _Message(message.text, plan: plan, accepted: accepted);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar assistant')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  const _ChatBubble(
                    text:
                        'Hi! Tell me what you would like to add, move, or remove.',
                    isUser: false,
                  ),
                  for (final message in _messages)
                    _ChatBubble(
                      text: message.text,
                      isUser: message.isUser,
                      showReviewButton: message.showReview,
                      onReviewChanges: () => _openPreview(message),
                    ),
                  if (_loading)
                    const _ChatBubble(text: 'Thinking...', isUser: false),
                ],
              ),
            ),
            _Composer(
              controller: _messageController,
              // only one message at a time
              onSend: _loading ? null : _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool showReviewButton;
  final VoidCallback? onReviewChanges;

  const _ChatBubble({
    required this.text,
    required this.isUser,
    this.showReviewButton = false,
    this.onReviewChanges,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isUser ? Colors.black : Colors.grey.shade100;
    final textColor = isUser ? Colors.white : Colors.black;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 330),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bubbleColor,
          border: Border.all(color: isUser ? Colors.black : Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text, style: TextStyle(color: textColor, height: 1.35)),
            if (showReviewButton) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onReviewChanges,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.black),
                  shape: const RoundedRectangleBorder(),
                ),
                child: const Text('Review changes'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onSend;

  const _Composer({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend?.call(),
                minLines: 1,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onSend,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}

class ChangePreviewScreen extends StatefulWidget {
  final ChatPlan plan;
  // the chat that led to this plan, sent along when the user refines it
  final List<Map<String, String>> history;
  // only used by the tests, so they don't call the real API
  final http.Client? client;

  const ChangePreviewScreen({
    super.key,
    required this.plan,
    this.history = const [],
    this.client,
  });

  @override
  State<ChangePreviewScreen> createState() => _ChangePreviewScreenState();
}

class _ChangePreviewScreenState extends State<ChangePreviewScreen> {
  final _messageController = TextEditingController();
  PreviewTab _tab = PreviewTab.calendar;
  // replaced every time the user refines the plan
  late ChatPlan _plan = widget.plan;
  late final List<Map<String, String>> _history = [...widget.history];
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _refine() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final plan = await planChanges(message, myEvents,
          history: _history, client: widget.client);
      if (!mounted) return;
      setState(() {
        _history.add({'role': 'user', 'content': message});
        _history.add(_assistantTurn(plan.reply, plan, null));
        _plan = plan;
        _messageController.clear();
      });
    } on LlmException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // goes back to the chat and tells it if the changes were accepted
  void _finish(bool accepted) {
    if (accepted) applyChanges(_plan.changes, myEvents);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop((accepted, _plan));
    messenger.showSnackBar(SnackBar(
      content: Text(accepted
          ? 'The changes are in your calendar.'
          : 'Nothing was changed.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review changes')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  if (_plan.skipped > 0) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _LabelChip(
                        text: '${_plan.skipped} '
                            '${_plan.skipped == 1 ? 'change' : 'changes'}'
                            ' left out',
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Text(
                    _summary(_plan.changes),
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 14),
                  const _Legend(),
                  const SizedBox(height: 18),
                  SegmentedButton<PreviewTab>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: PreviewTab.calendar,
                        label: Text('Calendar'),
                      ),
                      ButtonSegment(
                        value: PreviewTab.changes,
                        label: Text('Changes list'),
                      ),
                    ],
                    selected: {_tab},
                    onSelectionChanged: (selection) =>
                        setState(() => _tab = selection.first),
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: Colors.black,
                      selectedForegroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black),
                      shape: const RoundedRectangleBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_tab == PreviewTab.calendar)
                    _WeekPreview(changes: _plan.changes)
                  else
                    _ChangesList(changes: _plan.changes),
                  const SizedBox(height: 20),
                  _FurtherChanges(
                    controller: _messageController,
                    loading: _loading,
                    // only one request at a time
                    onPreview: _loading ? null : _refine,
                  ),
                  // the answer to the last refine, the first one is in the chat
                  if (_plan != widget.plan) ...[
                    const SizedBox(height: 10),
                    Text(_plan.reply,
                        style: const TextStyle(color: Colors.black54)),
                  ],
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(_errorMessage!,
                        style: TextStyle(color: Colors.red.shade700)),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _finish(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(),
                      ),
                      child: const Text('Accept changes'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _finish(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black),
                        shape: const RoundedRectangleBorder(),
                      ),
                      child: const Text('Reject changes'),
                    ),
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

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: const [
        _LegendItem(label: 'Added', color: Color(0xff2e7d32)),
        _LegendItem(label: 'Adjusted', color: Color(0xff1565c0)),
        _LegendItem(label: 'Deleted', color: Color(0xffc62828)),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 5),
        Text(label),
      ],
    );
  }
}

// One block in the preview, made from an event or a change
class _PreviewBlock {
  final String title;
  final DateTime start;
  final DateTime end;
  final _PreviewEventType type;
  // where a moved event was before, shown in its label
  final DateTime? movedFrom;

  const _PreviewBlock(
    this.title,
    this.start,
    this.end,
    this.type, {
    this.movedFrom,
  });
}

// The days the changes touch, with the events on them and the changes on top
List<_PreviewBlock> _previewBlocks(
  List<CalendarChange> changes,
  List<CalendarEvent> events,
) {
  final days = <DateTime>{};
  final moved = <CalendarEvent, CalendarChange>{};
  final deleted = <CalendarEvent>{};
  for (final change in changes) {
    if (change.start != null) days.add(dateOnly(change.start!));
    if (change.event != null) days.add(dateOnly(change.event!.start));
    if (change.type == ChangeType.move) moved[change.event!] = change;
    if (change.type == ChangeType.delete) deleted.add(change.event!);
  }

  final blocks = <_PreviewBlock>[];
  for (final event in events) {
    if (!days.contains(dateOnly(event.start))) continue;
    final move = moved[event];
    if (move != null) {
      // only at the new time, the old one is in the changes list
      blocks.add(_PreviewBlock(
          event.title, move.start!, move.end!, _PreviewEventType.adjusted,
          movedFrom: event.start));
    } else if (deleted.contains(event)) {
      blocks.add(_PreviewBlock(
          event.title, event.start, event.end, _PreviewEventType.deleted));
    } else {
      blocks.add(_PreviewBlock(
          event.title, event.start, event.end, _PreviewEventType.neutral));
    }
  }
  for (final change in changes) {
    if (change.type == ChangeType.add) {
      blocks.add(_PreviewBlock(
          change.title, change.start!, change.end!, _PreviewEventType.added));
    }
  }
  return blocks;
}

// Blocks that overlap on the same day are put next to each other. Gives each
// block its lane and how many lanes its group of overlapping blocks has.
Map<_PreviewBlock, (int, int)> _lanes(List<_PreviewBlock> blocks) {
  final result = <_PreviewBlock, (int, int)>{};
  final sorted = [...blocks]..sort((a, b) => a.start.compareTo(b.start));

  // blocks in the group that is being filled, and where each lane ends
  var group = <_PreviewBlock>[];
  var laneEnds = <DateTime>[];
  void closeGroup() {
    for (final block in group) {
      result[block] = (result[block]!.$1, laneEnds.length);
    }
    group = [];
    laneEnds = [];
  }

  for (final block in sorted) {
    final overlapsGroup = group.isNotEmpty &&
        isSameDay(group.first.start, block.start) &&
        laneEnds.any((end) => end.isAfter(block.start));
    if (!overlapsGroup) closeGroup();

    // the first lane that is free when this block starts
    var lane = laneEnds.indexWhere((end) => !end.isAfter(block.start));
    if (lane == -1) {
      lane = laneEnds.length;
      laneEnds.add(block.end);
    } else {
      laneEnds[lane] = block.end;
    }
    group.add(block);
    result[block] = (lane, 0);
  }
  closeGroup();
  return result;
}

const _hourHeight = 42.0;

class _WeekPreview extends StatelessWidget {
  final List<CalendarChange> changes;

  const _WeekPreview({required this.changes});

  @override
  Widget build(BuildContext context) {
    final blocks = _previewBlocks(changes, myEvents);
    final days = blocks.map((b) => dateOnly(b.start)).toSet().toList()..sort();
    if (days.isEmpty) return const SizedBox.shrink();

    // only the hours that have something in them, but at least 3
    var firstHour = 23;
    var lastHour = 0;
    for (final block in blocks) {
      if (block.start.hour < firstHour) firstHour = block.start.hour;
      final endHour = block.end.minute == 0 && isSameDay(block.start, block.end)
          ? block.end.hour
          : block.end.hour + 1;
      if (endHour > lastHour) lastHour = endHour;
    }
    if (lastHour - firstHour < 3) lastHour = firstHour + 3;
    final hours = lastHour - firstHour;
    final lanes = _lanes(blocks);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PREVIEW',
          style:
              TextStyle(fontSize: 11, letterSpacing: 1.2, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const SizedBox(width: 42),
            for (final day in days)
              Expanded(
                child: Center(
                  child: Text(
                    '${weekdayNames[day.weekday - 1].substring(0, 3)} '
                    '${day.day}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: hours * _hourHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 42,
                child: Stack(
                  children: [
                    for (var i = 0; i < hours; i++)
                      Positioned(
                        top: i * _hourHeight,
                        child: Text(
                          '${twoDigits(firstHour + i)}:00',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => Stack(
                    children: [
                      for (var i = 0; i < hours; i++)
                        Positioned(
                          top: i * _hourHeight,
                          left: 0,
                          right: 0,
                          child: Divider(
                            height: 1,
                            color: Colors.grey.shade300,
                          ),
                        ),
                      for (final block in blocks)
                        _PreviewEvent(
                          block: block,
                          column: days.indexOf(dateOnly(block.start)),
                          columnWidth: constraints.maxWidth / days.length,
                          lane: lanes[block]!.$1,
                          laneCount: lanes[block]!.$2,
                          firstHour: firstHour,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _PreviewEventType { neutral, added, adjusted, deleted }

class _PreviewEvent extends StatelessWidget {
  final _PreviewBlock block;
  final int column;
  final double columnWidth;
  // overlapping blocks share the column
  final int lane;
  final int laneCount;
  final int firstHour;

  const _PreviewEvent({
    required this.block,
    required this.column,
    required this.columnWidth,
    required this.lane,
    required this.laneCount,
    required this.firstHour,
  });

  Color get _color {
    switch (block.type) {
      case _PreviewEventType.added:
        return const Color(0xff2e7d32);
      case _PreviewEventType.adjusted:
        return const Color(0xff1565c0);
      case _PreviewEventType.deleted:
        return const Color(0xffc62828);
      case _PreviewEventType.neutral:
        return Colors.grey;
    }
  }

  // e.g. " (was 13:00)", with the date if it was on another day
  String _movedFromText() {
    final from = block.movedFrom;
    if (from == null) return '';
    if (isSameDay(from, block.start)) return ' (was ${formatTime(from)})';
    return ' (was ${formatShortDate(from)} ${formatTime(from)})';
  }

  // hours after the first hour of the preview, e.g. 1.5 for half past
  double _hoursFromTop(DateTime time) =>
      time.hour - firstHour + time.minute / 60;

  @override
  Widget build(BuildContext context) {
    final top = _hoursFromTop(block.start) * _hourHeight;
    final height =
        block.end.difference(block.start).inMinutes / 60 * _hourHeight;

    final laneWidth = columnWidth / laneCount;

    return Positioned(
      top: top + 2,
      left: column * columnWidth + lane * laneWidth,
      width: laneWidth,
      height: height - 4,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          // solid colors, so nothing shows through from behind
          color: block.type == _PreviewEventType.neutral
              ? Colors.grey.shade100
              : Color.alphaBlend(_color.withValues(alpha: .12), Colors.white),
          border: Border.all(color: _color, width: 1.5),
        ),
        child: Text(
          '${formatTime(block.start)} ${block.title}${_movedFromText()}',
          style: TextStyle(
            color: _color,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// e.g. "1 added · 1 adjusted · 0 deleted"
String _summary(List<CalendarChange> changes) {
  int count(ChangeType type) => changes.where((c) => c.type == type).length;
  return '${count(ChangeType.add)} added · '
      '${count(ChangeType.move)} adjusted · '
      '${count(ChangeType.delete)} deleted';
}

// e.g. "Wed 11 Nov 13:00–14:00"
String _timeRange(DateTime start, DateTime end) =>
    '${formatShortDate(start)} ${formatTime(start)}–${formatTime(end)}';

class _ChangesList extends StatelessWidget {
  final List<CalendarChange> changes;

  const _ChangesList({required this.changes});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final change in changes)
          switch (change.type) {
            ChangeType.add => _ChangeCard(
                label: 'ADDED',
                title: change.title,
                details: _timeRange(change.start!, change.end!),
                color: const Color(0xff2e7d32),
              ),
            ChangeType.move => _ChangeCard(
                label: 'ADJUSTED',
                title: change.title,
                details: '${_timeRange(change.event!.start, change.event!.end)}'
                    ' → ${_timeRange(change.start!, change.end!)}',
                color: const Color(0xff1565c0),
              ),
            ChangeType.delete => _ChangeCard(
                label: 'DELETED',
                title: change.title,
                details: _timeRange(change.event!.start, change.event!.end),
                color: const Color(0xffc62828),
              ),
          },
      ],
    );
  }
}

class _ChangeCard extends StatelessWidget {
  final String label;
  final String title;
  final String details;
  final Color color;

  const _ChangeCard({
    required this.label,
    required this.title,
    required this.details,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ListTile(
        leading: Container(width: 4, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(details),
        trailing: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _FurtherChanges extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final VoidCallback? onPreview;

  const _FurtherChanges({
    required this.controller,
    required this.loading,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Want to refine this preview?',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Describe a further change...',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: onPreview,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black),
                shape: const RoundedRectangleBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 14,
                ),
              ),
              child: Text(loading ? 'Thinking...' : 'Preview changes'),
            ),
          ],
        ),
      ],
    );
  }
}

class _LabelChip extends StatelessWidget {
  final String text;
  final Color color;

  const _LabelChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        border: Border.all(color: color),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: .8,
        ),
      ),
    );
  }
}
