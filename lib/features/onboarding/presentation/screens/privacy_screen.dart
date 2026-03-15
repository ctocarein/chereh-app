import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  final _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;
  bool _accepted = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.atEdge &&
        _scrollController.position.pixels > 0 &&
        !_hasScrolledToBottom) {
      setState(() => _hasScrolledToBottom = true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Politique de confidentialité'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Contenu scrollable
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              child: _PrivacyContent(theme: theme),
            ),
          ),

          // Bandeau d'acceptation
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Indicateur scroll si pas encore lu
                if (!_hasScrolledToBottom)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_downward,
                            size: 14, color: colors.onSurface.withValues(alpha: 0.4)),
                        const SizedBox(width: 6),
                        Text(
                          'Lisez jusqu\'en bas pour continuer',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Checkbox acceptation
                CheckboxListTile(
                  value: _accepted,
                  onChanged: _hasScrolledToBottom
                      ? (v) => setState(() => _accepted = v ?? false)
                      : null,
                  title: Text(
                    'J\'ai lu et j\'accepte la politique de confidentialité',
                    style: theme.textTheme.bodyMedium,
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),

                const SizedBox(height: 12),

                FilledButton(
                  onPressed: _accepted
                      ? () => context.goNamed(RouteNames.loginOrCreate)
                      : null,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: const Text('Continuer'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Contenu de la politique
// ---------------------------------------------------------------------------
class _PrivacyContent extends StatelessWidget {
  final ThemeData theme;
  const _PrivacyContent({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Section(
          theme: theme,
          title: '1. Collecte des données',
          body:
              'Chereh collecte uniquement les données nécessaires à la fourniture de ses services : '
              'numéro de téléphone, informations de profil de santé fournies lors des évaluations, '
              'et données de géolocalisation avec votre consentement explicite.',
        ),
        _Section(
          theme: theme,
          title: '2. Utilisation des données',
          body:
              'Vos données sont utilisées exclusivement pour :\n'
              '• Vous orienter vers les ressources de santé adaptées\n'
              '• Permettre aux agents de terrain de vous accompagner\n'
              '• Améliorer la qualité de nos services\n\n'
              'Elles ne sont jamais revendues à des tiers.',
        ),
        _Section(
          theme: theme,
          title: '3. Protection des données',
          body:
              'Toutes les communications entre l\'application et nos serveurs sont chiffrées '
              '(TLS/HTTPS). Les données sensibles sont stockées de manière sécurisée sur vos '
              'appareils et sur nos serveurs conformément aux normes en vigueur.',
        ),
        _Section(
          theme: theme,
          title: '4. Fonctionnement hors-ligne',
          body:
              'Pour garantir un accès en zones à faible connectivité, certaines données '
              'sont conservées localement sur votre appareil. Elles sont synchronisées '
              'automatiquement lorsque la connexion est rétablie.',
        ),
        _Section(
          theme: theme,
          title: '5. Vos droits',
          body:
              'Conformément aux lois en vigueur, vous disposez des droits suivants :\n'
              '• Accès à vos données personnelles\n'
              '• Rectification ou suppression de vos données\n'
              '• Portabilité de vos données\n'
              '• Opposition au traitement\n\n'
              'Pour exercer ces droits, contactez-nous à : privacy@chereh.com',
        ),
        _Section(
          theme: theme,
          title: '6. Durée de conservation',
          body:
              'Vos données sont conservées pendant la durée de votre utilisation du service, '
              'augmentée d\'une période de 3 ans après votre dernière activité, sauf demande '
              'expresse de suppression de votre part.',
        ),
        _Section(
          theme: theme,
          title: '7. Modifications',
          body:
              'Nous pouvons mettre à jour cette politique. Vous serez notifié de tout changement '
              'significatif via l\'application. La poursuite de l\'utilisation vaut acceptation '
              'des nouvelles conditions.',
        ),
        const SizedBox(height: 8),
        Text(
          'Dernière mise à jour : Mars 2026',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final ThemeData theme;
  final String title;
  final String body;
  const _Section({required this.theme, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}
