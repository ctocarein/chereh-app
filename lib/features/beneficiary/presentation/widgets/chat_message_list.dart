import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/chat_message.dart';
import 'chat_bubble.dart';

class ChatMessageList extends StatefulWidget {
  final List<ChatMessage> messages;
  final void Function(int stepIndex)? onEditStep;

  const ChatMessageList({
    super.key,
    required this.messages,
    this.onEditStep,
  });

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  final _scrollController = ScrollController();
  bool _isNearBottom = true;

  static const _nearBottomThreshold = 320.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Scroll initial
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void didUpdateWidget(ChatMessageList old) {
    super.didUpdateWidget(old);
    if (widget.messages.length != old.messages.length && _isNearBottom) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToBottom(animated: true));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    final nearBottom =
        pos.maxScrollExtent - pos.pixels < _nearBottomThreshold;
    if (nearBottom != _isNearBottom) {
      setState(() => _isNearBottom = nearBottom);
    }
  }

  void _scrollToBottom({bool animated = false}) {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (animated) {
      _scrollController.animateTo(
        pos.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(pos.maxScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(top: 12, bottom: 12),
          itemCount: widget.messages.length,
          itemBuilder: (context, i) {
            final msg = widget.messages[i];

            // Séparateur temporel si gap > 30 min ou nouveau jour
            final showSeparator = i > 0 &&
                _needsSeparator(
                    widget.messages[i - 1].timestamp, msg.timestamp);

            return Column(
              children: [
                if (showSeparator) _DateSeparator(msg.timestamp),
                ChatBubble(
                  message: msg,
                  onEdit: msg.interactive && msg.relatedStepIndex != null
                      ? () => widget.onEditStep?.call(msg.relatedStepIndex!)
                      : null,
                ),
              ],
            );
          },
        ),

        // Bouton "revenir en bas"
        if (!_isNearBottom)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: () => _scrollToBottom(animated: true),
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
              child: const Icon(Icons.keyboard_arrow_down),
            ),
          ),
      ],
    );
  }

  bool _needsSeparator(DateTime a, DateTime b) {
    final sameDay = a.year == b.year && a.month == b.month && a.day == b.day;
    if (!sameDay) return true;
    return b.difference(a).inMinutes > 30;
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator(this.date);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    final label = isToday
        ? 'Aujourd\'hui'
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.muted,
                  ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}
