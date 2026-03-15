import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/chat_message.dart';

/// Bulle de chat avec animation slide+fade à l'apparition.
class ChatBubble extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback? onEdit;

  const ChatBubble({super.key, required this.message, this.onEdit});

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    final isBot = widget.message.role == ChatRole.bot;
    _slide = Tween<Offset>(
      begin: Offset(isBot ? -0.08 : 0.08, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBot = widget.message.role == ChatRole.bot;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment:
                isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isBot) _Avatar() else const SizedBox.shrink(),
              if (isBot) const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: isBot
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.end,
                  children: [
                    _Bubble(message: widget.message, onEdit: widget.onEdit),
                    if (widget.message.interactive &&
                        widget.message.role == ChatRole.user &&
                        widget.onEdit != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, right: 2),
                        child: _EditChip(onTap: widget.onEdit!),
                      ),
                    _Timestamp(widget.message.timestamp),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sous-widgets
// ---------------------------------------------------------------------------

class _Avatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: AppColors.brandSoft,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.health_and_safety_outlined,
          size: 17, color: AppColors.brand),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onEdit;

  const _Bubble({required this.message, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isBot = message.role == ChatRole.bot;

    final bg = switch (message.variant) {
      'accent' => AppColors.accent,
      'soft' => AppColors.brandSoft,
      _ => isBot ? Colors.white : AppColors.brand,
    };
    final fg = isBot ? AppColors.foreground : Colors.white;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isBot ? 4 : 18),
      bottomRight: Radius.circular(isBot ? 18 : 4),
    );

    if (message.isTyping) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: radius),
        child: const _TypingIndicator(),
      );
    }

    Widget bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message.text ?? '',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: fg, height: 1.45),
      ),
    );

    if (message.interactive) {
      return Semantics(
        button: true,
        label: 'Modifier la réponse',
        child: GestureDetector(
          onTap: onEdit,
          child: bubble,
        ),
      );
    }

    return bubble;
  }
}

class _EditChip extends StatelessWidget {
  final VoidCallback onTap;
  const _EditChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.brandSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.brand.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.edit_outlined, size: 13, color: AppColors.brand),
            SizedBox(width: 4),
            Text(
              'Modifier',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.brand,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = ((_ctrl.value - i * 0.2) % 1.0).clamp(0.0, 1.0);
            final scale = 1.0 + (t < 0.5 ? t : 1.0 - t) * 0.6;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _Timestamp extends StatelessWidget {
  final DateTime timestamp;
  const _Timestamp(this.timestamp);

  @override
  Widget build(BuildContext context) {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
      child: Text(
        '$h:$m',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.muted.withValues(alpha: 0.6),
              fontSize: 10,
            ),
      ),
    );
  }
}
