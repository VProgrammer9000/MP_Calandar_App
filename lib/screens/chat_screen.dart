import 'package:flutter/material.dart';

enum AssistantMode { quickReply, planChanges }

enum PreviewTab { calendar, changes }

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  AssistantMode _mode = AssistantMode.quickReply;
  final List<String> _sentMessages = [];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    setState(() {
      _sentMessages.add(message);
      _messageController.clear();
    });
  }

  void _openPreview() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ChangePreviewScreen()),
    );
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
                    text: 'Can you help me make room for my study session?',
                    isUser: true,
                  ),
                  const _ChatBubble(
                    text:
                        'Sure — tell me what you would like to add, move, or remove.',
                    isUser: false,
                  ),
                  for (final message in _sentMessages) ...[
                    _ChatBubble(text: message, isUser: true),
                    _ChatBubble(
                      text: _mode == AssistantMode.planChanges
                          ? 'Here is a demo plan for those calendar changes.'
                          : 'Here is a quick reply to your request.',
                      isUser: false,
                      showReviewButton: _mode == AssistantMode.planChanges,
                      onReviewChanges: _openPreview,
                    ),
                  ],
                  const SizedBox(height: 8),
                  _ModeSelector(
                    mode: _mode,
                    onChanged: (mode) => setState(() => _mode = mode),
                  ),
                ],
              ),
            ),
            _Composer(
              controller: _messageController,
              onSend: _sendMessage,
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

class _ModeSelector extends StatelessWidget {
  final AssistantMode mode;
  final ValueChanged<AssistantMode> onChanged;

  const _ModeSelector({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<AssistantMode>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: AssistantMode.quickReply,
          label: Text('Quick reply'),
        ),
        ButtonSegment(
          value: AssistantMode.planChanges,
          label: Text('Plan changes'),
        ),
      ],
      selected: {mode},
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: Colors.black,
        selectedForegroundColor: Colors.white,
        foregroundColor: Colors.black,
        side: const BorderSide(color: Colors.black),
        shape: const RoundedRectangleBorder(),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

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
                onSubmitted: (_) => onSend(),
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
  const ChangePreviewScreen({super.key});

  @override
  State<ChangePreviewScreen> createState() => _ChangePreviewScreenState();
}

class _ChangePreviewScreenState extends State<ChangePreviewScreen> {
  final _messageController = TextEditingController();
  PreviewTab _tab = PreviewTab.calendar;
  bool _secondPreview = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _finish(String message) {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(message)));
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _LabelChip(
                      text: 'Demo preview',
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '1 added · 1 adjusted · 1 deleted',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
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
                    _WeekPreview(secondPreview: _secondPreview)
                  else
                    _ChangesList(secondPreview: _secondPreview),
                  const SizedBox(height: 20),
                  _FurtherChanges(
                    controller: _messageController,
                    onPreview: () => setState(() => _secondPreview = true),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () =>
                          _finish('Demo accepted — no calendar data changed.'),
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
                      onPressed: () =>
                          _finish('Demo rejected — no calendar data changed.'),
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

class _WeekPreview extends StatelessWidget {
  final bool secondPreview;

  const _WeekPreview({required this.secondPreview});

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'WEEK PREVIEW',
          style: TextStyle(fontSize: 11, letterSpacing: 1.2, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 330,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(
                width: 42,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('14:00', style: TextStyle(fontSize: 10)),
                    Text('15:00', style: TextStyle(fontSize: 10)),
                    Text('16:00', style: TextStyle(fontSize: 10)),
                    Text('17:00', style: TextStyle(fontSize: 10)),
                    Text('18:00', style: TextStyle(fontSize: 10)),
                    Text('19:00', style: TextStyle(fontSize: 10)),
                    Text('20:00', style: TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        for (final day in days)
                          Expanded(
                            child: Center(
                              child: Text(
                                day,
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
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) => Stack(
                          children: [
                            for (var i = 0; i < 7; i++)
                              Positioned(
                                top: i * 42,
                                left: 0,
                                right: 0,
                                child: Divider(
                                  height: 1,
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            _PreviewEvent(
                              day: 0,
                              row: 1,
                              label: 'Class',
                              type: _PreviewEventType.neutral,
                              calendarWidth: constraints.maxWidth,
                            ),
                            _PreviewEvent(
                              day: 1,
                              row: 4,
                              label: '18:00\nWorkout',
                              type: _PreviewEventType.adjusted,
                              outlined: true,
                              calendarWidth: constraints.maxWidth,
                            ),
                            _PreviewEvent(
                              day: 1,
                              row: 5,
                              label: '19:00\nWorkout\nADJUSTED',
                              type: _PreviewEventType.adjusted,
                              calendarWidth: constraints.maxWidth,
                            ),
                            _PreviewEvent(
                              day: 2,
                              row: 1,
                              label: 'Study group\nDELETED',
                              type: _PreviewEventType.deleted,
                              calendarWidth: constraints.maxWidth,
                            ),
                            _PreviewEvent(
                              day: 3,
                              row: secondPreview ? 2 : 0,
                              label: secondPreview
                                  ? 'Study session\n16:00 ADDED'
                                  : 'Study session\n14:00 ADDED',
                              type: _PreviewEventType.added,
                              calendarWidth: constraints.maxWidth,
                            ),
                            _PreviewEvent(
                              day: 4,
                              row: 3,
                              label: 'Dinner',
                              type: _PreviewEventType.neutral,
                              calendarWidth: constraints.maxWidth,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Outlined old time: Workout · Tue 18:00–19:00',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}

enum _PreviewEventType { neutral, added, adjusted, deleted }

class _PreviewEvent extends StatelessWidget {
  final int day;
  final int row;
  final String label;
  final _PreviewEventType type;
  final double calendarWidth;
  final bool outlined;

  const _PreviewEvent({
    required this.day,
    required this.row,
    required this.label,
    required this.type,
    required this.calendarWidth,
    this.outlined = false,
  });

  Color get _color {
    switch (type) {
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

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: row * 42 + 3,
      left: day * calendarWidth / 5,
      width: calendarWidth / 5,
      height: 38,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: outlined
              ? Colors.white
              : type == _PreviewEventType.neutral
                  ? Colors.grey.shade100
                  : _color.withValues(alpha: .12),
          border: Border.all(
            color: _color,
            width: outlined ? 1 : 1.5,
            style: outlined ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
        child: Text(
          label,
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

class _ChangesList extends StatelessWidget {
  final bool secondPreview;

  const _ChangesList({required this.secondPreview});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ChangeCard(
          label: 'ADDED',
          title: 'Study session',
          details: secondPreview
              ? 'Thursday 16:00–17:00'
              : 'Thursday 14:00–15:00',
          color: const Color(0xff2e7d32),
        ),
        _ChangeCard(
          label: 'ADJUSTED',
          title: 'Workout',
          details: 'Tuesday, 18:00–19:00 → 19:00–20:00',
          color: const Color(0xff1565c0),
        ),
        _ChangeCard(
          label: 'DELETED',
          title: 'Study group',
          details: 'Wednesday 15:00–16:00',
          color: const Color(0xffc62828),
        ),
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
  final VoidCallback onPreview;

  const _FurtherChanges({
    required this.controller,
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
              child: const Text('Preview changes'),
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
