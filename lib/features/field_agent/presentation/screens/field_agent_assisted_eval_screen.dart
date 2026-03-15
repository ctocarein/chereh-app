import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/field_agent_remote_datasource.dart';
import '../../domain/models/beneficiary_registration.dart';

// ============================================================================
// FieldAgentAssistedEvalScreen
// ============================================================================

class FieldAgentAssistedEvalScreen extends ConsumerStatefulWidget {
  const FieldAgentAssistedEvalScreen({super.key});

  @override
  ConsumerState<FieldAgentAssistedEvalScreen> createState() =>
      _FieldAgentAssistedEvalScreenState();
}

class _FieldAgentAssistedEvalScreenState
    extends ConsumerState<FieldAgentAssistedEvalScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  BeneficiaryRegistration? _found;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _found = null;
      _error = null;
    });

    try {
      final registration = await ref
          .read(fieldAgentRemoteDatasourceProvider)
          .registerBeneficiary(_phoneController.text.trim());
      if (!mounted) return;
      setState(() => _found = registration);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message ?? 'Erreur lors de la recherche.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Une erreur inattendue est survenue.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Évaluation assistée',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Info banner ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.brand, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Recherchez un bénéficiaire par numéro de téléphone ou scannez son QR code.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.brandStrong,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Champ téléphone ──────────────────────────────────────
              Text(
                'Numéro de téléphone',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Form(
                key: _formKey,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.search,
                        onFieldSubmitted: (_) => _search(),
                        decoration: InputDecoration(
                          hintText: '+221 77 000 00 00',
                          prefixIcon:
                              const Icon(Icons.phone_outlined, size: 18),
                          filled: true,
                          fillColor: AppColors.surfaceAlt,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.brand, width: 1.5),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.accent, width: 1),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Entrez un numéro' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _search,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brand,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.search_rounded, size: 22),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Erreur ───────────────────────────────────────────────
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.accent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.accent,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Ou ───────────────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('ou',
                          style: TextStyle(
                              color: AppColors.muted, fontSize: 13)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
              ),

              // ── Bouton QR ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.goNamed(RouteNames.fieldAgentQr),
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                  label: const Text('Scanner le QR du bénéficiaire'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brand,
                    side: const BorderSide(color: AppColors.brand),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              // ── Card résultat ─────────────────────────────────────────
              if (_found != null) ...[
                const SizedBox(height: 28),
                _BeneficiaryResultCard(
                  registration: _found!,
                  onStart: () => context.goNamed(
                    RouteNames.beneficiaryEvaluation,
                    extra: _found!.identityId,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Card résultat bénéficiaire
// ============================================================================

class _BeneficiaryResultCard extends StatelessWidget {
  final BeneficiaryRegistration registration;
  final VoidCallback onStart;

  const _BeneficiaryResultCard({
    required this.registration,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final isNew = registration.isNew;
    final statusColor = isNew ? AppColors.support : AppColors.brand;
    final statusLabel =
        isNew ? 'Nouveau bénéficiaire enregistré' : 'Bénéficiaire existant';
    final statusIcon =
        isNew ? Icons.person_add_rounded : Icons.check_circle_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusLabel,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (registration.phone.isNotEmpty)
                      Text(
                        registration.phone,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.muted),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ID pill
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.fingerprint_rounded,
                    size: 14, color: AppColors.muted),
                const SizedBox(width: 6),
                Text(
                  'ID\u00a0: ',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted, fontSize: 11),
                ),
                Expanded(
                  child: Text(
                    registration.identityId,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.foreground,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // CTA
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.assignment_outlined, size: 18),
              label: const Text('Démarrer l\'évaluation assistée'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
