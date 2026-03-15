import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/auth/auth_notifier.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/qr_datasource.dart';

// ============================================================================
// QrHubScreen — deux onglets : Mon Code | Scanner
// ============================================================================

class QrHubScreen extends ConsumerStatefulWidget {
  const QrHubScreen({super.key});

  @override
  ConsumerState<QrHubScreen> createState() => _QrHubScreenState();
}

class _QrHubScreenState extends ConsumerState<QrHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final MobileScannerController _camera = MobileScannerController();
  bool _scanProcessing = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(_onTabChanged);
    // Caméra éteinte au départ (onglet Mon Code actif)
    _camera.stop();
  }

  void _onTabChanged() {
    if (_tab.indexIsChanging) return;
    if (_tab.index == 1) {
      _camera.start();
    } else {
      _camera.stop();
      setState(() => _scanProcessing = false);
    }
  }

  @override
  void dispose() {
    _tab
      ..removeListener(_onTabChanged)
      ..dispose();
    _camera.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_scanProcessing) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() => _scanProcessing = true);
    await _camera.stop();

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ScanResultDialog(
        code: code,
        onDismiss: () {
          if (mounted) Navigator.of(context).pop(); // dialog
          if (mounted) Navigator.of(context).pop(); // QrHubScreen
        },
        onRetry: () {
          setState(() => _scanProcessing = false);
          _camera.start();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authNotifierProvider);
    final user = authAsync.valueOrNull is AuthStateAuthenticated
        ? (authAsync.valueOrNull as AuthStateAuthenticated).user
        : null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _QrAppBar(tab: _tab),
        body: TabBarView(
          controller: _tab,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // ── Onglet 0 : Mon Code ──────────────────────────────────
            _MyCodeTab(user: user),

            // ── Onglet 1 : Scanner ───────────────────────────────────
            _ScannerTab(
              camera: _camera,
              processing: _scanProcessing,
              onDetect: _onDetect,
            ),
          ],
        ),
      ),
    );
  }
}

// ── AppBar avec segment control ──────────────────────────────────────────────

class _QrAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController tab;
  const _QrAppBar({required this.tab});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 60);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Barre titre
            SizedBox(
              height: kToolbarHeight,
              child: Row(
                children: [
                  const BackButton(color: AppColors.foreground),
                  const Expanded(
                    child: Text(
                      'QR Code',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.foreground,
                      ),
                    ),
                  ),
                  // Espace symétrique au BackButton
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Segment control
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: _SegmentedTab(
                tab: tab,
                labels: const ['Mon Code', 'Scanner'],
                icons: const [
                  Icons.qr_code_2_rounded,
                  Icons.qr_code_scanner_rounded,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Segment control pill ─────────────────────────────────────────────────────

class _SegmentedTab extends StatefulWidget {
  final TabController tab;
  final List<String> labels;
  final List<IconData> icons;

  const _SegmentedTab({
    required this.tab,
    required this.labels,
    required this.icons,
  });

  @override
  State<_SegmentedTab> createState() => _SegmentedTabState();
}

class _SegmentedTabState extends State<_SegmentedTab> {
  @override
  void initState() {
    super.initState();
    widget.tab.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.tab.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(widget.labels.length, (i) {
          final active = widget.tab.index == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => widget.tab.animateTo(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: active ? AppColors.brand : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppColors.brand.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.icons[i],
                      size: 16,
                      color: active ? Colors.white : AppColors.muted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.labels[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ============================================================================
// Onglet 0 — Mon Code QR (identité du bénéficiaire)
// ============================================================================

class _MyCodeTab extends ConsumerWidget {
  final dynamic user; // AuthUser?

  const _MyCodeTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityId = user?.id ?? '';
    final name = (user?.name ?? '') as String;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final qrData = 'chereh://identity/$identityId';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
      child: Column(
        children: [
          // ── Carte QR ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: AppColors.brand,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Bénéficiaire CheReh',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 24),

                // QR
                if (identityId.isNotEmpty)
                  QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 200,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.foreground,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.foreground,
                    ),
                  )
                else
                  const SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.brand, strokeWidth: 2),
                    ),
                  ),

                const SizedBox(height: 16),

                // ID tronqué
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    identityId.length > 16
                        ? '${identityId.substring(0, 8)}...${identityId.substring(identityId.length - 6)}'.toUpperCase()
                        : identityId.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: AppColors.muted,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Info ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: AppColors.brand, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Montrez ce QR code à l\'agent de terrain lors de votre consultation ou remise de kit.',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.brandStrong,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Onglet 1 — Scanner le QR d'une organisation
// ============================================================================

class _ScannerTab extends StatelessWidget {
  final MobileScannerController camera;
  final bool processing;
  final void Function(BarcodeCapture) onDetect;

  const _ScannerTab({
    required this.camera,
    required this.processing,
    required this.onDetect,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Caméra fond noir ────────────────────────────────────────
        ColoredBox(
          color: Colors.black,
          child: MobileScanner(
            controller: camera,
            onDetect: onDetect,
          ),
        ),

        // ── Overlay ─────────────────────────────────────────────────
        _ScanOverlay(),

        // ── Flash ───────────────────────────────────────────────────
        Positioned(
          top: 12,
          right: 16,
          child: IconButton(
            onPressed: () => camera.toggleTorch(),
            icon: const Icon(Icons.flashlight_on_outlined,
                color: Colors.white, size: 24),
          ),
        ),

        // ── Label bas ───────────────────────────────────────────────
        Positioned(
          bottom: 48,
          left: 0,
          right: 0,
          child: Center(
            child: processing
                ? const CircularProgressIndicator(
                    color: AppColors.brand, strokeWidth: 2)
                : const Text(
                    'Placez le QR code de l\'organisation dans le cadre',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

// ── Overlay scan ─────────────────────────────────────────────────────────────

class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const frameSize = 230.0;
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final l = (sw - frameSize) / 2;
    final t = (sh - frameSize) / 2 - 60;

    return Stack(
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.mode(
              Color(0x99000000), BlendMode.srcOut),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Positioned(
                left: l,
                top: t,
                child: Container(
                  width: frameSize,
                  height: frameSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: l,
          top: t,
          child: _ScanFrame(size: frameSize),
        ),
      ],
    );
  }
}

class _ScanFrame extends StatelessWidget {
  final double size;
  const _ScanFrame({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          _corner(top: true, left: true),
          _corner(top: true, left: false),
          _corner(top: false, left: true),
          _corner(top: false, left: false),
        ],
      ),
    );
  }

  Widget _corner({required bool top, required bool left}) {
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: left ? 0 : null,
      right: left ? null : 0,
      child: SizedBox(
        width: 28,
        height: 28,
        child: CustomPaint(
          painter: _CornerPainter(top: top, left: left),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool top;
  final bool left;
  const _CornerPainter({required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.brand
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const r = 12.0;
    final path = Path();
    if (top && left) {
      path.moveTo(0, size.height);
      path.lineTo(0, r);
      path.arcToPoint(Offset(r, 0),
          radius: const Radius.circular(r), clockwise: true);
      path.lineTo(size.width, 0);
    } else if (top && !left) {
      path.moveTo(0, 0);
      path.lineTo(size.width - r, 0);
      path.arcToPoint(Offset(size.width, r),
          radius: const Radius.circular(r), clockwise: true);
      path.lineTo(size.width, size.height);
    } else if (!top && left) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height - r);
      path.arcToPoint(Offset(r, size.height),
          radius: const Radius.circular(r), clockwise: false);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height - r);
      path.arcToPoint(Offset(size.width - r, size.height),
          radius: const Radius.circular(r), clockwise: false);
      path.lineTo(0, size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}

// ============================================================================
// Dialog résultat du scan
// ============================================================================

class _ScanResultDialog extends ConsumerStatefulWidget {
  final String code;
  final VoidCallback onDismiss;
  final VoidCallback onRetry;

  const _ScanResultDialog({
    required this.code,
    required this.onDismiss,
    required this.onRetry,
  });

  @override
  ConsumerState<_ScanResultDialog> createState() =>
      _ScanResultDialogState();
}

class _ScanResultDialogState extends ConsumerState<_ScanResultDialog> {
  QrScanResult? _result;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _submit();
  }

  Future<void> _submit() async {
    try {
      final ds = ref.read(qrDatasourceProvider);
      final result = await ds.scan(widget.code);
      if (mounted) setState(() { _result = result; _loading = false; });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'QR code invalide ou non reconnu.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _loading
            ? const SizedBox(
                height: 120,
                child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.brand, strokeWidth: 2),
                ),
              )
            : _error != null
                ? _ErrorBody(
                    message: _error!,
                    onRetry: () {
                      Navigator.of(context).pop();
                      widget.onRetry();
                    },
                  )
                : _SuccessBody(
                    result: _result!,
                    onDone: widget.onDismiss,
                  ),
      ),
    );
  }
}

class _SuccessBody extends StatelessWidget {
  final QrScanResult result;
  final VoidCallback onDone;
  const _SuccessBody({required this.result, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final org = result.organization;
    final linked = result.alreadyLinked;
    final color = linked ? AppColors.brand : AppColors.support;
    final icon = linked ? Icons.link_rounded : Icons.check_circle_rounded;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 56),
        const SizedBox(height: 14),
        Text(
          linked ? 'Déjà lié' : 'Compte lié\u00a0!',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.foreground,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          result.message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                org.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground,
                ),
              ),
              if (org.city != null) ...[
                const SizedBox(height: 3),
                Text(
                  org.city!,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.muted),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onDone,
            style: FilledButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Terminer'),
          ),
        ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.qr_code_2_rounded,
            color: AppColors.disabled, size: 48),
        const SizedBox(height: 14),
        const Text(
          'QR code non reconnu',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.foreground,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brand,
              side: const BorderSide(color: AppColors.brand),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}
