import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/responsive/app_responsive.dart';

class LoginOrCreateScreen extends ConsumerStatefulWidget {
  const LoginOrCreateScreen({super.key});

  @override
  ConsumerState<LoginOrCreateScreen> createState() => _LoginOrCreateScreenState();
}

class _LoginOrCreateScreenState extends ConsumerState<LoginOrCreateScreen> {
  final _phoneCtrl = TextEditingController();
  final _initialPhoneNumber = PhoneNumber(isoCode: 'CI');
  PhoneNumber _phoneNumber = PhoneNumber(isoCode: 'CI');
  bool _loading = false;
  bool _isPhoneValid = false;
  String? _error;
  String? _info; // message "SMS envoyé" etc.

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_isPhoneValid) {
      setState(() => _error = 'Numéro invalide');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      final phone = _phoneNumber.phoneNumber ?? '';
      await ref.read(authNotifierProvider.notifier).submitPhone(phone);
      // submitPhone avale les exceptions via AsyncValue.guard — on les lit ici.
      if (mounted) {
        final authState = ref.read(authNotifierProvider);
        if (authState.hasError) {
          final err = authState.error;
          setState(() => _error = err is ApiException
              ? err.message
              : 'Une erreur est survenue. Réessayez.');
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Une erreur est survenue. Réessayez.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final rp = context.rp;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: rp.maxContentW),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: rp.hPad,
                vertical: rp.spXL,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Center(
                    child: Container(
                      width: rp.logoSz,
                      height: rp.logoSz,
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(rp.radiusL),
                      ),
                      child: Icon(
                        Icons.health_and_safety_outlined,
                        size: rp.logoSz * 0.52,
                        color: colors.primary,
                      ),
                    ),
                  ),

                  SizedBox(height: rp.spL),

                  Text(
                    'Entrez votre numéro',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),

                  SizedBox(height: rp.spS),

                  Text(
                    'Entrez votre numéro pour vous connecter.\n'
                    'Si vous n\'avez pas encore de compte, il sera créé automatiquement.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),

                  SizedBox(height: rp.spL),

                  // Champ téléphone
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.outline),
                      borderRadius: BorderRadius.circular(rp.radiusM),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: InternationalPhoneNumberInput(
                      onInputChanged: (number) => _phoneNumber = number,
                      onInputValidated: (isValid) {
                        setState(() {
                          _isPhoneValid = isValid;
                          if (!isValid && _phoneCtrl.text.isNotEmpty) {
                            _error = 'Numéro invalide';
                          } else {
                            _error = null;
                          }
                        });
                      },
                      selectorConfig: const SelectorConfig(
                        selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                        useEmoji: true,
                      ),
                      ignoreBlank: false,
                      autoValidateMode: AutovalidateMode.onUserInteraction,
                      initialValue: _initialPhoneNumber,
                      textFieldController: _phoneCtrl,
                      inputDecoration: const InputDecoration(
                        hintText: '07x xxx xxx',
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 16),
                      ),
                      formatInput: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: false,
                        decimal: false,
                      ),
                    ),
                  ),

                  if (_error != null) ...[
                    SizedBox(height: rp.spS),
                    _StatusBanner(
                        message: _error!, isError: true,
                        colors: colors, theme: theme),
                  ],
                  if (_info != null) ...[
                    SizedBox(height: rp.spS),
                    _StatusBanner(
                        message: _info!, isError: false,
                        colors: colors, theme: theme),
                  ],

                  SizedBox(height: rp.spL),

                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      minimumSize: Size.fromHeight(rp.buttonH),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5),
                          )
                        : const Text('Continuer'),
                  ),

                  SizedBox(height: rp.spM),

                  Text(
                    'En continuant, vous acceptez les conditions d\'utilisation '
                    'et la politique de confidentialité de Chereh.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String message;
  final bool isError;
  final ColorScheme colors;
  final ThemeData theme;

  const _StatusBanner({
    required this.message,
    required this.isError,
    required this.colors,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isError
        ? colors.errorContainer
        : colors.primaryContainer;
    final fg = isError
        ? colors.onErrorContainer
        : colors.onPrimaryContainer;
    final icon = isError ? Icons.error_outline : Icons.check_circle_outline;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: theme.textTheme.bodySmall?.copyWith(color: fg)),
          ),
        ],
      ),
    );
  }
}
