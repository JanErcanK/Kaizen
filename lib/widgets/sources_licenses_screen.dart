import 'app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/body_map_view_mode.dart';
import '../services/anatomy_tips.dart';

const anatomyLicenseAsset = 'assets/models/KAIZEN_ANATOMY_LICENSE.txt';

/// One place for the shipped anatomy attribution, tip references and package
/// licenses. Links open in the system browser, outside the anatomy WebView.
class SourcesLicensesScreen extends StatelessWidget {
  const SourcesLicensesScreen({super.key, this.bundle, this.openUrl});

  final AssetBundle? bundle;
  final Future<bool> Function(Uri)? openUrl;

  static bool _german(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'de';

  Future<void> _openSource(BuildContext context, String value) async {
    final uri = Uri.tryParse(value);
    var opened = false;
    if (uri != null && uri.scheme == 'https' && uri.host.isNotEmpty) {
      try {
        opened =
            await (openUrl?.call(uri) ??
                launchUrl(uri, mode: LaunchMode.externalApplication));
      } on Exception {
        opened = false;
      }
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _german(context)
                ? 'Der Link konnte nicht geöffnet werden.'
                : 'The link could not be opened.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final german = _german(context);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        leadingWidth: 44,
        title: Text(german ? 'Quellen & Lizenzen' : 'Sources & licenses'),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              key: const Key('sources-licenses-list'),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _SectionTitle(german ? 'Anatomiemodell' : 'Anatomy model'),
                _SourceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SelectableText(
                          german
                              ? 'Anatomie: Z-Anatomy / BodyParts3D · CC BY-SA · für Kaizen bearbeitet'
                              : 'Anatomy: Z-Anatomy / BodyParts3D · CC BY-SA · adapted for Kaizen',
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 14,
                            height: 1.45,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: OutlinedButton.icon(
                          key: const Key('anatomy-full-license'),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => _AnatomyLicenseScreen(
                                bundle: bundle ?? rootBundle,
                              ),
                            ),
                          ),
                          icon: const Icon(
                            Icons.description_outlined,
                            size: 18,
                          ),
                          label: Text(
                            german
                                ? 'Vollständige Lizenz & Änderungen'
                                : 'Full license & modifications',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      _SourceLink(
                        id: 'z-anatomy',
                        title: 'Z-Anatomy · Models of human anatomy',
                        url:
                            'https://github.com/Z-Anatomy/Models-of-human-anatomy',
                        onTap: _openSource,
                      ),
                      _SourceLink(
                        id: 'bodyparts3d',
                        title: 'BodyParts3D · Database Center for Life Science',
                        url:
                            'https://dbarchive.biosciencedbc.jp/en/bodyparts3d/desc.html',
                        onTap: _openSource,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _SectionTitle(german ? 'Quellen der Tipps' : 'Tip references'),
                Text(
                  german
                      ? 'Die Hinweise im Anatomie-Infofeld stützen sich auf diese Quellen. Wähle eine Kategorie und öffne die Originalinformationen.'
                      : 'The anatomy tips draw on these references. Choose a category to open the original information.',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                for (final mode in const [
                  BodyMapViewMode.recovery,
                  BodyMapViewMode.skeleton,
                  BodyMapViewMode.connective,
                  BodyMapViewMode.organs,
                ]) ...[
                  _SourceCard(
                    child: ExpansionTile(
                      key: Key('tip-sources-${mode.name}'),
                      shape: const Border(),
                      collapsedShape: const Border(),
                      iconColor: colors.onSurfaceVariant,
                      collapsedIconColor: colors.onSurfaceVariant,
                      title: Text(
                        mode.anatomyLabel(german),
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      children: [
                        for (final source in AnatomyTips.sources.where(
                          (source) => source.modes.contains(mode),
                        ))
                          _SourceLink(
                            id: '${mode.name}-${source.id}',
                            title: source.title,
                            url: source.url,
                            onTap: _openSource,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 16),
                _SectionTitle(german ? 'App & Software' : 'App & software'),
                _SourceCard(
                  child: ListTile(
                    key: const Key('software-licenses'),
                    leading: Icon(
                      Icons.code_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                    title: Text(
                      german ? 'Open-Source-Lizenzen' : 'Open-source licenses',
                    ),
                    subtitle: Text(
                      german
                          ? 'Flutter und verwendete Pakete'
                          : 'Flutter and included packages',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: 'Kaizen',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnatomyLicenseScreen extends StatefulWidget {
  const _AnatomyLicenseScreen({required this.bundle});
  final AssetBundle bundle;

  @override
  State<_AnatomyLicenseScreen> createState() => _AnatomyLicenseScreenState();
}

class _AnatomyLicenseScreenState extends State<_AnatomyLicenseScreen> {
  late final Future<String> _license = widget.bundle.loadString(
    anatomyLicenseAsset,
  );

  @override
  Widget build(BuildContext context) {
    final german = SourcesLicensesScreen._german(context);
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        leadingWidth: 44,
        title: Text(german ? 'Anatomie-Lizenz' : 'Anatomy license'),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: FutureBuilder<String>(
              future: _license,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    child: SelectableText(
                      snapshot.data!,
                      key: const Key('anatomy-license-text'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      german
                          ? 'Der Lizenztext konnte nicht geladen werden.'
                          : 'The license text could not be loaded.',
                    ),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );
}

class _SourceLink extends StatelessWidget {
  const _SourceLink({
    required this.id,
    required this.title,
    required this.url,
    required this.onTap,
  });

  final String id;
  final String title;
  final String url;
  final Future<void> Function(BuildContext, String) onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    key: Key('source-$id'),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    title: Text(
      title,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
    subtitle: Text(
      url,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 11,
        height: 1.4,
      ),
    ),
    trailing: Icon(
      Icons.open_in_new_rounded,
      size: 17,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
    onTap: () => onTap(context, url),
  );
}
