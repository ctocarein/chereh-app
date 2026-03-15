import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/status_banner.dart';

/// Écran de saisie / création de PIN.
/// [hasPin] false → création  /  true → vérification.
class PinScreen extends ConsumerStatefulWidget {
  final String sessionToken;
  final bool hasPin;

  const PinScreen({
    super.key,
    required this.sessionToken,
    required this.hasPin,
  });

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  final List<String> _digits = [];
  String? _error;
  bool _loading = false;
  static const _pinLength = 4;

  void _onDigit(String d) {
    if (_digits.length >= _pinLength) return;
    setState(() {
      _digits.add(d);
      _error = null;
    });
    if (_digits.length == _pinLength) _submit();
  }

  void _onDelete() {
    if (_digits.isEmpty) return;
    setState(() => _digits.removeLast());
  }

  Future<void> _submit() async {
    final pin = _digits.join();
    setState(() { _loading = true; _error = null; });
    await ref.read(authNotifierProvider.notifier).submitPin(
          sessionToken: widget.sessionToken,
          pin: pin,
          hasPin: widget.hasPin,
        );
    if (!mounted) return;
    final authAsync = ref.read(authNotifierProvider);
    if (authAsync.hasError) {
      setState(() {
        _digits.clear();
        _error = widget.hasPin ? 'PIN incorrect. Réessayez.' : 'Erreur lors de la création du PIN.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.brand,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 48),

              Text(
                widget.hasPin ? 'Saisissez votre PIN' : 'Créez votre PIN',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.hasPin
                    ? 'Entrez votre code à $_pinLength chiffres'
                    : 'Choisissez un code à $_pinLength chiffres pour sécuriser votre compte',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Indicateur de points
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pinLength, (i) {
                  final filled = i < _digits.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 18,
                    height: 18,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.25),
                    ),
                  );
                }),
              ),

              if (_error != null) ...[
                const SizedBox(height: 24),
                StatusBanner(message: _error!, type: BannerType.error),
              ],

              const Spacer(),

              // Pavé numérique
              if (_loading)
                const CircularProgressIndicator(color: Colors.white)
              else
                _NumPad(onDigit: _onDigit, onDelete: _onDelete),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumPad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onDelete;

  const _NumPad({required this.onDigit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Column(
      children: keys.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: row.map((k) {
            if (k.isEmpty) return const SizedBox(width: 72, height: 72);
            return _PadKey(
              label: k,
              onTap: () => k == '⌫' ? onDelete() : onDigit(k),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

class _PadKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PadKey({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: label == '⌫'
              ? const Icon(Icons.backspace_outlined,
                  color: Colors.white, size: 22)
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ),
    );
  }
}
