import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/field_agent_remote_datasource.dart';
import '../../domain/models/beneficiary_registration.dart';

// ============================================================================
// État interne du scanner
// ============================================================================

enum _ScanState { scanning, processing, result, error }

// ============================================================================
// FieldAgentQrScreen
// ============================================================================

class FieldAgentQrScreen extends ConsumerStatefulWidget {
  const FieldAgentQrScreen({super.key});

  @override
  ConsumerState<FieldAgentQrScreen> createState() => _FieldAgentQrScreenState();
}

class _FieldAgentQrScreenState extends ConsumerState<FieldAgentQrScreen> {
  final MobileScannerController _camera = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  _ScanState _state = _ScanState.scanning;
  BeneficiaryRegistration? _result;
  String? _errorMessage;

  // Préfixe encodé dans le QR du bénéficiaire
  static const _qrPrefix = 'chereh://identity/';

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_state != _ScanState.scanning) return;

    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || !raw.startsWith(_qrPrefix)) return;

    final identityId = raw.substring(_qrPrefix.length).trim();
    if (identityId.isEmpty) return;

    setState(() => _state = _ScanState.processing);
    await _camera.stop();

    try {
      final registration = await ref
          .read(fieldAgentRemoteDatasourceProvider)
          .scanQr(identityId);

      if (!mounted) return;
      setState(() {
        _state = _ScanState.result;
        _result = registration;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _ScanState.error;
        _errorMessage = e.message ?? _friendlyError(e.statusCode);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = _ScanState.error;
        _errorMessage = 'Une erreur inattendue est survenue.';
      });
    }
  }

  String _friendlyError(int? code) => switch (code) {
        404 => 'Bénéficiaire introuvable.',
        422 => 'Ce QR code ne correspond pas à un bénéficiaire.',
        403 => 'Accès non autorisé.',
        _ => 'Impossible de lire ce QR code.',
      };

  void _resetScan() {
    setState(() {
      _state = _ScanState.scanning;
      _result = null;
      _errorMessage = null;
    });
    _camera.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Scanner un bénéficiaire',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_auto_rounded,
                color: Colors.white, size: 22),
            onPressed: () => _camera.toggleTorch(),
            tooltip: 'Flash',
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Caméra ──────────────────────────────────────────────────
          MobileScanner(
            controller: _camera,
            onDetect: _onDetect,
          ),

          // ── Overlay sombre + cadre de scan ───────────────────────────
          _ScanOverlay(isProcessing: _state == _ScanState.processing),

          // ── Label d'instruction ──────────────────────────────────────
          if (_state == _ScanState.scanning)
            Positioned(
              bottom: 180,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'Pointez la caméra vers le QR du bénéficiaire',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

          // ── Indicateur de chargement ─────────────────────────────────
          if (_state == _ScanState.processing)
            Positioned(
              bottom: 180,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.brand,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Vérification en cours…',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Panel résultat ──────────────────────────────────────────
          if (_state == _ScanState.result && _result != null)
            _ResultPanel(
              registration: _result!,
              onEval: () => context.goNamed(
                RouteNames.beneficiaryEvaluation,
                extra: _result!.identityId,
              ),
              onNewScan: _resetScan,
            ),

          // ── Panel erreur ─────────────────────────────────────────────
          if (_state == _ScanState.error)
            _ErrorPanel(
              message: _errorMessage ?? 'Erreur inconnue.',
              onNewScan: _resetScan,
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// Overlay avec cadre de scan
// ============================================================================

class _ScanOverlay extends StatelessWidget {
  final bool isProcessing;
  const _ScanOverlay({required this.isProcessing});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    const frameSize = 240.0;
    final frameLeft = (size.width - frameSize) / 2;
    final frameTop = (size.height - frameSize) / 2 - 30;

    return Stack(
      children: [
        // Zones sombres autour du cadre
        Positioned(top: 0, left: 0, right: 0, height: frameTop,
            child: _dimBox),
        Positioned(top: frameTop + frameSize, left: 0, right: 0,
            bottom: 0, child: _dimBox),
        Positioned(top: frameTop, left: 0, width: frameLeft,
            height: frameSize, child: _dimBox),
        Positioned(top: frameTop, left: frameLeft + frameSize,
            right: 0, height: frameSize, child: _dimBox),

        // Coins du cadre
        Positioned(
          top: frameTop,
          left: frameLeft,
          child: _ScanFrame(
            size: frameSize,
            color: isProcessing ? AppColors.brand : Colors.white,
          ),
        ),
      ],
    );
  }

  Widget get _dimBox =>
      const ColoredBox(color: Color(0x88000000));
}

class _ScanFrame extends StatelessWidget {
  final double size;
  final Color color;
  const _ScanFrame({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CornerPainter(color: color)),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  const _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const len = 28.0;
    final w = size.width;
    final h = size.height;
    // Coins : TL, TR, BR, BL
    for (final (ox, oy, sx, sy) in [
      (0.0, 0.0, 1.0, 1.0),
      (w, 0.0, -1.0, 1.0),
      (w, h, -1.0, -1.0),
      (0.0, h, 1.0, -1.0),
    ]) {
      canvas
        ..drawLine(Offset(ox, oy), Offset(ox + sx * len, oy), paint)
        ..drawLine(Offset(ox, oy), Offset(ox, oy + sy * len), paint);
    }
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.color != color;
}

// ============================================================================
// Panel résultat (bénéficiaire trouvé)
// ============================================================================

class _ResultPanel extends StatelessWidget {
  final BeneficiaryRegistration registration;
  final VoidCallback onEval;
  final VoidCallback onNewScan;

  const _ResultPanel({
    required this.registration,
    required this.onEval,
    required this.onNewScan,
  });

  @override
  Widget build(BuildContext context) {
    final isNew = registration.isNew;
    final statusLabel = isNew
        ? 'Bénéficiaire enregistré dans votre organisation'
        : 'Bénéficiaire déjà lié à votre organisation';
    final statusIcon =
        isNew ? Icons.person_add_rounded : Icons.check_circle_rounded;
    final statusColor = isNew ? AppColors.support : AppColors.brand;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E3E7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Status row
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusLabel,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 2),
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
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fingerprint_rounded,
                      size: 16, color: AppColors.muted),
                  const SizedBox(width: 8),
                  Text(
                    'ID\u00a0: ',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.muted),
                  ),
                  Expanded(
                    child: Text(
                      registration.identityId,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: AppColors.foreground,
                            fontWeight: FontWeight.w600,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // CTA évaluation assistée
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onEval,
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
            const SizedBox(height: 10),

            // Nouveau scan
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onNewScan,
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                label: const Text('Nouveau scan'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.muted,
                  side: const BorderSide(color: Color(0xFFE0E3E7)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Panel erreur
// ============================================================================

class _ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onNewScan;

  const _ErrorPanel({required this.message, required this.onNewScan});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E3E7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.qr_code_2_rounded,
                      color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QR non reconnu',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message,
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
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onNewScan,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Réessayer'),
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
      ),
    );
  }
}
