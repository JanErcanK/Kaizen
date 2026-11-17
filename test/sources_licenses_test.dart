import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/l10n/app_localizations.dart';
import 'package:kaizen/models/body_map_view_mode.dart';
import 'package:kaizen/screens/profile_screen.dart';
import 'package:kaizen/services/anatomy_tips.dart';
import 'package:kaizen/services/progress_store.dart';
import 'package:kaizen/theme/app_theme.dart';
import 'package:kaizen/widgets/sources_licenses_screen.dart';

Widget _host(Widget child, {bool light = true, String locale = 'de'}) =>
    MaterialApp(
      theme: AppTheme.build(light: light),
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

void main() {
  late Directory storage;
  setUp(() async {
    storage = await Directory.systemTemp.createTemp('kaizen_sources_test_');
    await ProgressStore.init(storageRootPath: storage.path);
  });
  tearDown(() async {
    await ProgressStore.closeForTesting();
    await storage.delete(recursive: true);
  });

  testWidgets('App/System settings opens the sources and licenses screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_host(const Scaffold(body: ProfileScreen())));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    final entry = find.byKey(const Key('settings-sources-licenses'));
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.byType(SourcesLicensesScreen), findsOneWidget);
    expect(find.text('Quellen & Lizenzen'), findsOneWidget);
    expect(find.byKey(const Key('anatomy-full-license')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final light in [true, false]) {
    testWidgets(
      'narrow ${light ? 'light' : 'dark'} screen loads the complete selectable license and opens references',
      (tester) async {
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        // Asset I/O runs outside the widget clock, then the screen reads the
        // same cached bundle value through its normal loading path.
        final original = await tester.runAsync(
          () => rootBundle.loadString(anatomyLicenseAsset),
        );
        Uri? opened;
        await tester.pumpWidget(
          _host(
            SourcesLicensesScreen(
              openUrl: (uri) async {
                opened = uri;
                return true;
              },
            ),
            light: light,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is SelectableText &&
                (widget.data?.contains('Z-Anatomy / BodyParts3D') ?? false),
          ),
          findsOneWidget,
        );
        await tester.runAsync(() async {
          await tester.tap(find.byKey(const Key('anatomy-full-license')));
          await tester.pumpAndSettle();
        });
        final licenseText = tester.widget<SelectableText>(
          find.byKey(const Key('anatomy-license-text')),
        );
        expect(licenseText.data, original);
        expect(licenseText.data, contains('Gauthier Kervyn'));
        expect(licenseText.data, contains('Kousaku Okubo'));
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('Zurück'));
        await tester.pumpAndSettle();

        final category = find.byKey(const Key('tip-sources-recovery'));
        await tester.scrollUntilVisible(
          category,
          240,
          scrollable: find
              .descendant(
                of: find.byKey(const Key('sources-licenses-list')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.tap(category);
        await tester.pumpAndSettle();
        final source = AnatomyTips.sources.firstWhere(
          (source) => source.modes.contains(BodyMapViewMode.recovery),
        );
        final link = find.byKey(Key('source-recovery-${source.id}'));
        await tester.ensureVisible(link);
        await tester.tap(link);
        await tester.pumpAndSettle();
        expect(opened.toString(), source.url);
        expect(find.text(source.title), findsWidgets);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'software licenses remain reachable and failed URLs are handled',
    (tester) async {
      LicenseRegistry.addLicense(
        () => Stream.value(
          const LicenseEntryWithLineBreaks([
            'Kaizen test package',
          ], 'Test package license content.'),
        ),
      );
      await tester.pumpWidget(
        _host(SourcesLicensesScreen(openUrl: (_) async => false), locale: 'en'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('source-z-anatomy')));
      await tester.pumpAndSettle();
      expect(find.text('The link could not be opened.'), findsOneWidget);
      ScaffoldMessenger.of(
        tester.element(find.byType(SourcesLicensesScreen)),
      ).hideCurrentSnackBar();
      await tester.pumpAndSettle();
      final software = find.byKey(const Key('software-licenses'));
      await tester.scrollUntilVisible(
        software,
        300,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('sources-licenses-list')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.runAsync(() async {
        await tester.tap(software);
        await tester.pumpAndSettle();
      });
      expect(find.byType(LicensePage), findsOneWidget);
      expect(find.text('Kaizen test package'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
