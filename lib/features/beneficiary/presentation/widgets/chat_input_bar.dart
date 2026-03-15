import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/responsive/app_responsive.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/question.dart';

/// Saisie contextuelle — s'adapte automatiquement au [Question.type].
/// Transitions animées entre chaque changement de question.
class ChatInputBar extends StatefulWidget {
  final Question question;
  final bool disabled;
  final void Function(dynamic value, {File? file}) onAnswer;

  const ChatInputBar({
    super.key,
    required this.question,
    required this.onAnswer,
    this.disabled = false,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _textCtrl = TextEditingController();
  final List<String> _selected = [];
  double _sliderValue = 0;
  double _ratingValue = 0;
  File? _pickedFile;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.question.min ?? 0;
  }

  @override
  void didUpdateWidget(ChatInputBar old) {
    super.didUpdateWidget(old);
    if (old.question.id != widget.question.id) {
      _textCtrl.clear();
      _selected.clear();
      _sliderValue = widget.question.min ?? 0;
      _ratingValue = 0;
      _pickedFile = null;
      _error = null;
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _submit(dynamic value, {File? file}) {
    if (widget.disabled) return;
    if (value is String && value.trim().isEmpty) {
      setState(() => _error = 'Ce champ est obligatoire.');
      return;
    }
    setState(() => _error = null);
    HapticFeedback.lightImpact();
    widget.onAnswer(value, file: file);
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: widget.disabled,
      child: AnimatedOpacity(
        opacity: widget.disabled ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            context.rp.hPad, 16, context.rp.hPad, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 380),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.14),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(widget.question.id),
                  child: _buildInput(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 6),
                Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput() {
    final q = widget.question;

    return switch (q.type) {
      QuestionType.info ||
      QuestionType.custom ||
      QuestionType.valide =>
        _AckButton(onPressed: () => _submit(true)),

      QuestionType.boolean => _BooleanButtons(
          onAnswer: (v) => _submit(v),
        ),

      QuestionType.text => _TextInput(
          controller: _textCtrl,
          keyboardType: TextInputType.multiline,
          maxLines: null,
          onSend: () => _submit(_textCtrl.text.trim()),
        ),

      QuestionType.number => _TextInput(
          controller: _textCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onSend: () {
            final v = num.tryParse(_textCtrl.text.trim());
            if (v != null) _submit(v);
          },
        ),

      QuestionType.selectOne ||
      QuestionType.radio =>
        _SelectOneInput(
          options: q.options ?? [],
          onAnswer: (label) => _submit(q.valueForLabel(label)),
        ),

      QuestionType.selectMultiple ||
      QuestionType.checkbox =>
        _SelectMultipleInput(
          options: q.options ?? [],
          selected: _selected,
          onToggle: (label) => setState(() {
            _selected.contains(label)
                ? _selected.remove(label)
                : _selected.add(label);
          }),
          onValidate: () =>
              _submit(_selected.map((l) => q.valueForLabel(l)).toList()),
        ),

      QuestionType.slider => _SliderInput(
          value: _sliderValue,
          min: q.min ?? 0,
          max: q.max ?? 10,
          step: q.step ?? 1,
          onChanged: (v) => setState(() => _sliderValue = v),
          onSend: () => _submit(_sliderValue),
        ),

      QuestionType.scale => _ScaleInput(
          min: (q.min ?? 1).toInt(),
          max: (q.max ?? 5).toInt(),
          onAnswer: (v) => _submit(v),
        ),

      QuestionType.date => _DateInput(onAnswer: (v) => _submit(v)),

      QuestionType.time => _TimeInput(onAnswer: (v) => _submit(v)),

      QuestionType.rating => _RatingInput(
          value: _ratingValue,
          max: (q.max ?? 5).toInt(),
          step: q.step ?? 1,
          onChanged: (v) => setState(() => _ratingValue = v),
          onSend: () => _submit(_ratingValue),
        ),

      QuestionType.location => _TextInput(
          controller: _textCtrl,
          keyboardType: TextInputType.streetAddress,
          hint: 'Saisissez votre adresse…',
          onSend: () => _submit(_textCtrl.text.trim()),
          trailing: IconButton(
            icon: const Icon(Icons.my_location, color: AppColors.brand),
            onPressed: () => _submit('GPS_PENDING'),
          ),
        ),

      QuestionType.file ||
      QuestionType.image ||
      QuestionType.audio ||
      QuestionType.video =>
        _FileInput(
          mediaType: q.type.name,
          pickedFile: _pickedFile,
          onPick: (f) => setState(() => _pickedFile = f),
          onSend: () {
            if (_pickedFile != null) {
              _submit(_pickedFile!.path, file: _pickedFile);
            }
          },
        ),
    };
  }
}

// ---------------------------------------------------------------------------
// Bouton d'acquittement
// ---------------------------------------------------------------------------

class _AckButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _AckButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.thumb_up_rounded, size: 18),
      label: const Text('J\'ai compris'),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: AppColors.brand,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Oui / Non — grandes cartes tapables
// ---------------------------------------------------------------------------

class _BooleanButtons extends StatelessWidget {
  final void Function(bool) onAnswer;
  const _BooleanButtons({required this.onAnswer});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TapCard(
            icon: Icons.close_rounded,
            label: 'Non',
            color: AppColors.accent,
            onTap: () => onAnswer(false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TapCard(
            icon: Icons.check_rounded,
            label: 'Oui',
            color: AppColors.support,
            onTap: () => onAnswer(true),
          ),
        ),
      ],
    );
  }
}

class _TapCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TapCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_TapCard> createState() => _TapCardState();
}

class _TapCardState extends State<_TapCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final soft = Color.lerp(widget.color, Colors.white, 0.87)!;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: soft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: widget.color, size: 30),
              const SizedBox(height: 6),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
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
// Sélection unique — cartes radio (≤ 6) ou dropdown searchable (> 6)
// ---------------------------------------------------------------------------

/// Seuil au-delà duquel on bascule vers le dropdown avec recherche.
const _kSearchableThreshold = 6;

class _SelectOneInput extends StatelessWidget {
  final List<String> options;
  final void Function(String) onAnswer;

  const _SelectOneInput({required this.options, required this.onAnswer});

  @override
  Widget build(BuildContext context) {
    if (options.length > _kSearchableThreshold) {
      return _SearchableSelectInput(
        options: options,
        onAnswer: onAnswer,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < options.length; i++) ...[
          _RadioCard(label: options[i], onTap: () => onAnswer(options[i])),
          if (i < options.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Dropdown searchable — bottom sheet avec barre de recherche autocomplete
// ---------------------------------------------------------------------------

class _SearchableSelectInput extends StatefulWidget {
  final List<String> options;
  final void Function(String) onAnswer;

  const _SearchableSelectInput({
    required this.options,
    required this.onAnswer,
  });

  @override
  State<_SearchableSelectInput> createState() => _SearchableSelectInputState();
}

class _SearchableSelectInputState extends State<_SearchableSelectInput> {
  String? _selected;

  Future<void> _openSheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SelectSearchSheet(options: widget.options),
    );
    if (result != null && mounted) {
      setState(() => _selected = result);
      widget.onAnswer(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openSheet,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _selected != null ? AppColors.brandSoft : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _selected != null ? AppColors.brand : AppColors.disabled,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _selected != null
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: _selected != null ? AppColors.brand : AppColors.disabled,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selected ?? 'Choisir une option…',
                style: TextStyle(
                  fontSize: 15,
                  color: _selected != null
                      ? AppColors.brand
                      : AppColors.muted,
                  fontWeight: _selected != null
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
            const Icon(Icons.expand_more_rounded,
                color: AppColors.muted, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Normalise une chaîne pour la recherche : minuscules + suppression des diacritiques.
String _strip(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[àáâãä]'), 'a')
    .replaceAll(RegExp(r'[èéêë]'), 'e')
    .replaceAll(RegExp(r'[ìíîï]'), 'i')
    .replaceAll(RegExp(r'[òóôõö]'), 'o')
    .replaceAll(RegExp(r'[ùúûü]'), 'u')
    .replaceAll(RegExp(r'[ýÿ]'), 'y')
    .replaceAll('ñ', 'n')
    .replaceAll('ç', 'c')
    .replaceAll('œ', 'oe')
    .replaceAll('æ', 'ae');

/// Bottom sheet avec champ de recherche et liste filtrée.
class _SelectSearchSheet extends StatefulWidget {
  final List<String> options;
  const _SelectSearchSheet({required this.options});

  @override
  State<_SelectSearchSheet> createState() => _SelectSearchSheetState();
}

class _SelectSearchSheetState extends State<_SelectSearchSheet> {
  final _ctrl = TextEditingController();
  List<String> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.options;
    _ctrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _strip(_ctrl.text.trim());
    setState(() {
      _filtered = q.isEmpty
          ? widget.options
          : widget.options.where((o) => _strip(o).contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final sheetH = mq.size.height * 0.75;

    return Container(
      height: sheetH,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Poignée ────────────────────────────────────────────
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.disabled,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // ── Titre ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Choisir une option',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                  color: AppColors.muted,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),

          // ── Barre de recherche ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Rechercher…',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.muted,
                  size: 20,
                ),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            size: 18, color: AppColors.muted),
                        onPressed: () {
                          _ctrl.clear();
                          setState(() => _filtered = widget.options);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.surfaceAlt,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),

          // ── Compteur de résultats ──────────────────────────────
          if (_ctrl.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_filtered.length} résultat${_filtered.length != 1 ? 's' : ''}',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.muted),
                ),
              ),
            ),

          const SizedBox(height: 4),

          // ── Liste filtrée ──────────────────────────────────────
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off_rounded,
                            color: AppColors.disabled, size: 40),
                        const SizedBox(height: 8),
                        Text(
                          'Aucun résultat',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final opt = _filtered[i];
                      final query = _ctrl.text.toLowerCase();
                      return _OptionTile(
                        label: opt,
                        query: query,
                        onTap: () => Navigator.pop(context, opt),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Tile avec mise en évidence du texte recherché.
class _OptionTile extends StatelessWidget {
  final String label;
  final String query;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(child: _HighlightText(text: label, query: query)),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.disabled, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

/// Texte avec la partie correspondant à la recherche mise en gras/colorée.
class _HighlightText extends StatelessWidget {
  final String text;
  final String query;

  const _HighlightText({required this.text, required this.query});

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text,
          style: const TextStyle(fontSize: 15, color: AppColors.foreground));
    }

    final idx = _strip(text).indexOf(_strip(query));
    if (idx < 0) {
      return Text(text,
          style: const TextStyle(fontSize: 15, color: AppColors.foreground));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 15, color: AppColors.foreground),
        children: [
          if (idx > 0) TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + query.length),
            style: const TextStyle(
              color: AppColors.brand,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (idx + query.length < text.length)
            TextSpan(text: text.substring(idx + query.length)),
        ],
      ),
    );
  }
}

class _RadioCard extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _RadioCard({required this.label, required this.onTap});

  @override
  State<_RadioCard> createState() => _RadioCardState();
}

class _RadioCardState extends State<_RadioCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _pressed ? AppColors.brandSoft : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _pressed ? AppColors.brand : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _pressed ? AppColors.brand : AppColors.disabled,
                  width: 2,
                ),
              ),
              child: _pressed
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.brand,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 15,
                  color: _pressed ? AppColors.brand : AppColors.foreground,
                  fontWeight:
                      _pressed ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sélection multiple — cartes checkbox
// ---------------------------------------------------------------------------

class _SelectMultipleInput extends StatelessWidget {
  final List<String> options;
  final List<String> selected;
  final void Function(String) onToggle;
  final VoidCallback onValidate;

  const _SelectMultipleInput({
    required this.options,
    required this.selected,
    required this.onToggle,
    required this.onValidate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < options.length; i++) ...[
          _CheckCard(
            label: options[i],
            isSelected: selected.contains(options[i]),
            onTap: () => onToggle(options[i]),
          ),
          if (i < options.length - 1) const SizedBox(height: 8),
        ],
        if (selected.isNotEmpty) ...[
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onValidate,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: AppColors.brand,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              'Valider (${selected.length} sélection${selected.length > 1 ? 's' : ''})',
            ),
          ),
        ],
      ],
    );
  }
}

class _CheckCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CheckCard({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandSoft : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.brand : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.brand : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? AppColors.brand : AppColors.disabled,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: isSelected ? AppColors.brand : AppColors.foreground,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Slider — valeur en grand + piste colorée
// ---------------------------------------------------------------------------

class _SliderInput extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final double step;
  final void Function(double) onChanged;
  final VoidCallback onSend;

  const _SliderInput({
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final display =
        step < 1 ? value.toStringAsFixed(1) : value.toStringAsFixed(0);

    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: anim,
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: Text(
            display,
            key: ValueKey(display),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: AppColors.brand,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            thumbColor: AppColors.brand,
            activeTrackColor: AppColors.brand,
            inactiveTrackColor: AppColors.brandSoft,
            trackHeight: 6,
            thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 13),
            overlayColor: AppColors.brand.withValues(alpha: 0.12),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: ((max - min) / step).round(),
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(min.toStringAsFixed(0),
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.muted)),
              Text(max.toStringAsFixed(0),
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.muted)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: onSend,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: AppColors.brand,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Confirmer'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Scale / Likert — emoji (1-5) ou pastilles numériques (1-10+)
// ---------------------------------------------------------------------------

class _ScaleInput extends StatefulWidget {
  final int min;
  final int max;
  final void Function(int) onAnswer;

  const _ScaleInput({
    required this.min,
    required this.max,
    required this.onAnswer,
  });

  @override
  State<_ScaleInput> createState() => _ScaleInputState();
}

class _ScaleInputState extends State<_ScaleInput> {
  int? _selected;

  static const _emojis = ['😢', '😕', '😐', '🙂', '😄'];

  bool get _useEmoji => (widget.max - widget.min + 1) == 5;

  @override
  Widget build(BuildContext context) {
    final values = List.generate(
      widget.max - widget.min + 1,
      (i) => widget.min + i,
    );

    return _useEmoji ? _buildEmoji(values) : _buildNumbers(values);
  }

  Widget _buildEmoji(List<int> values) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: values.asMap().entries.map((e) {
        final val = e.value;
        final emoji = _emojis[e.key];
        final selected = _selected == val;

        return GestureDetector(
          onTap: () {
            setState(() => _selected = val);
            Future.delayed(
              const Duration(milliseconds: 200),
              () => widget.onAnswer(val),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 58,
            height: 72,
            decoration: BoxDecoration(
              color: selected ? AppColors.brandSoft : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    selected ? AppColors.brand : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: selected ? 1.3 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(emoji,
                      style: const TextStyle(fontSize: 26)),
                ),
                const SizedBox(height: 4),
                Text(
                  val.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    color: selected ? AppColors.brand : AppColors.muted,
                    fontWeight: selected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNumbers(List<int> values) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: values.map((val) {
        final selected = _selected == val;
        return GestureDetector(
          onTap: () {
            setState(() => _selected = val);
            Future.delayed(
              const Duration(milliseconds: 180),
              () => widget.onAnswer(val),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: selected ? AppColors.brand : AppColors.surfaceAlt,
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    selected ? AppColors.brand : AppColors.disabled,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                val.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: selected ? Colors.white : AppColors.foreground,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Saisie texte — champ arrondi avec bouton send intégré
// ---------------------------------------------------------------------------

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? hint;
  final VoidCallback onSend;
  final Widget? trailing;
  final int? maxLines;

  const _TextInput({
    required this.controller,
    required this.onSend,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.hint,
    this.trailing,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textInputAction: maxLines == 1
                ? TextInputAction.send
                : TextInputAction.newline,
            onSubmitted: maxLines == 1 ? (_) => onSend() : null,
            maxLines: maxLines,
            minLines: 1,
            style: const TextStyle(color: AppColors.foreground),
            decoration: InputDecoration(
              hintText: hint ?? 'Votre réponse…',
              hintStyle: const TextStyle(color: AppColors.disabled),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide:
                    const BorderSide(color: AppColors.brand, width: 1.5),
              ),
              filled: true,
              fillColor: AppColors.surfaceAlt,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
          ),
        ),
        ?trailing,
        const SizedBox(width: 8),
        SizedBox(
          height: 46,
          width: 46,
          child: FilledButton(
            onPressed: onSend,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              shape: const CircleBorder(),
            ),
            child: const Icon(Icons.send_rounded, size: 20),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Date — bouton avec prévisualisation + confirmation
// ---------------------------------------------------------------------------

class _DateInput extends StatefulWidget {
  final void Function(String) onAnswer;
  const _DateInput({required this.onAnswer});

  @override
  State<_DateInput> createState() => _DateInputState();
}

class _DateInputState extends State<_DateInput> {
  DateTime? _picked;

  @override
  Widget build(BuildContext context) {
    final label = _picked != null
        ? '${_picked!.day.toString().padLeft(2, '0')}/${_picked!.month.toString().padLeft(2, '0')}/${_picked!.year}'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _picked ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: Theme.of(ctx).colorScheme.copyWith(
                        primary: AppColors.brand,
                      ),
                ),
                child: child!,
              ),
            );
            if (d != null) setState(() => _picked = d);
          },
          icon: const Icon(Icons.calendar_today_outlined, size: 18),
          label: Text(label ?? 'Choisir une date'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            side: const BorderSide(color: AppColors.brand),
            foregroundColor: AppColors.brand,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
        if (_picked != null) ...[
          const SizedBox(height: 10),
          FilledButton(
            onPressed: () {
              final p = _picked!;
              widget.onAnswer(
                '${p.year}-${p.month.toString().padLeft(2, '0')}-${p.day.toString().padLeft(2, '0')}',
              );
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: AppColors.brand,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Heure — idem DateInput
// ---------------------------------------------------------------------------

class _TimeInput extends StatefulWidget {
  final void Function(String) onAnswer;
  const _TimeInput({required this.onAnswer});

  @override
  State<_TimeInput> createState() => _TimeInputState();
}

class _TimeInputState extends State<_TimeInput> {
  TimeOfDay? _picked;

  @override
  Widget build(BuildContext context) {
    final label = _picked != null
        ? '${_picked!.hour.toString().padLeft(2, '0')}:${_picked!.minute.toString().padLeft(2, '0')}'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () async {
            final t = await showTimePicker(
              context: context,
              initialTime: _picked ?? TimeOfDay.now(),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: Theme.of(ctx).colorScheme.copyWith(
                        primary: AppColors.brand,
                      ),
                ),
                child: child!,
              ),
            );
            if (t != null) setState(() => _picked = t);
          },
          icon: const Icon(Icons.access_time_outlined, size: 18),
          label: Text(label ?? 'Choisir une heure'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            side: const BorderSide(color: AppColors.brand),
            foregroundColor: AppColors.brand,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
        if (_picked != null) ...[
          const SizedBox(height: 10),
          FilledButton(
            onPressed: () => widget.onAnswer(label!),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: AppColors.brand,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Étoiles — notation avec animation sur sélection
// ---------------------------------------------------------------------------

class _RatingInput extends StatelessWidget {
  final double value;
  final int max;
  final double step;
  final void Function(double) onChanged;
  final VoidCallback onSend;

  const _RatingInput({
    required this.value,
    required this.max,
    required this.step,
    required this.onChanged,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final halfStar = step <= 0.5;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(max, (i) {
            final full = value >= i + 1;
            final half = halfStar && !full && value > i;
            final active = full || half;
            return GestureDetector(
              onTap: () => onChanged((i + 1).toDouble()),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: AnimatedScale(
                  scale: active ? 1.18 : 1.0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    full
                        ? Icons.star_rounded
                        : half
                            ? Icons.star_half_rounded
                            : Icons.star_outline_rounded,
                    size: 40,
                    color: active
                        ? AppColors.warning
                        : AppColors.disabled,
                  ),
                ),
              ),
            );
          }),
        ),
        if (value > 0) ...[
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onSend,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: AppColors.brand,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Fichier / Image / Audio / Vidéo
// ---------------------------------------------------------------------------

class _FileInput extends StatefulWidget {
  final String mediaType;
  final File? pickedFile;
  final void Function(File) onPick;
  final VoidCallback onSend;

  const _FileInput({
    required this.mediaType,
    required this.pickedFile,
    required this.onPick,
    required this.onSend,
  });

  @override
  State<_FileInput> createState() => _FileInputState();
}

class _FileInputState extends State<_FileInput> {
  final _imagePicker = ImagePicker();
  bool _loading = false;

  Future<void> _pick() async {
    setState(() => _loading = true);
    try {
      File? file;

      switch (widget.mediaType) {
        case 'image':
          final source = await _showImageSourceDialog();
          if (source == null) break;
          final picked =
              await _imagePicker.pickImage(source: source, imageQuality: 85);
          if (picked != null) file = File(picked.path);

        case 'video':
          final source = await _showImageSourceDialog(isVideo: true);
          if (source == null) break;
          final picked = await _imagePicker.pickVideo(source: source);
          if (picked != null) file = File(picked.path);

        case 'audio':
          final result = await FilePicker.platform.pickFiles(
            type: FileType.audio,
            allowMultiple: false,
          );
          if (result != null && result.files.single.path != null) {
            file = File(result.files.single.path!);
          }

        default:
          final result = await FilePicker.platform.pickFiles(
            allowMultiple: false,
          );
          if (result != null && result.files.single.path != null) {
            file = File(result.files.single.path!);
          }
      }

      if (file != null) widget.onPick(file);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<ImageSource?> _showImageSourceDialog({bool isVideo = false}) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.disabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.brandSoft,
                  child: Icon(Icons.camera_alt_rounded,
                      color: AppColors.brand),
                ),
                title: Text(isVideo ? 'Filmer' : 'Prendre une photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.brandSoft,
                  child: Icon(Icons.photo_library_rounded,
                      color: AppColors.brand),
                ),
                title: Text(isVideo
                    ? 'Choisir une vidéo'
                    : 'Choisir dans la galerie'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final picked = widget.pickedFile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _loading ? null : _pick,
          icon: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.brand),
                )
              : Icon(_iconFor(widget.mediaType)),
          label: Text(_loading ? 'Chargement…' : _labelFor(widget.mediaType)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            side: const BorderSide(color: AppColors.brand),
            foregroundColor: AppColors.brand,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
        if (picked != null) ...[
          const SizedBox(height: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.brand.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(_iconFor(widget.mediaType),
                    size: 18, color: AppColors.brand),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    picked.path.split('/').last,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                            color: AppColors.brand,
                            fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: _pick,
                  child: const Icon(Icons.swap_horiz_rounded,
                      size: 18, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: widget.onSend,
            icon: const Icon(Icons.upload_rounded),
            label: const Text('Envoyer'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: AppColors.brand,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ],
    );
  }

  IconData _iconFor(String type) => switch (type) {
        'image' => Icons.image_outlined,
        'audio' => Icons.mic_outlined,
        'video' => Icons.videocam_outlined,
        _ => Icons.attach_file,
      };

  String _labelFor(String type) => switch (type) {
        'image' => 'Ajouter une image',
        'audio' => 'Choisir un audio',
        'video' => 'Ajouter une vidéo',
        _ => 'Joindre un fichier',
      };
}
