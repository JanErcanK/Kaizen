import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/models/body_map_view_mode.dart';
import 'package:kaizen/services/anatomy_tips.dart';

void main() {
  const modes = [
    BodyMapViewMode.recovery,
    BodyMapViewMode.skeleton,
    BodyMapViewMode.connective,
    BodyMapViewMode.organs,
  ];

  test('40 distinct bilingual tips have traceable official sources', () {
    final sources = {
      for (final source in AnatomyTips.sources) source.id: source,
    };
    expect(sources.length, AnatomyTips.sources.length);
    final ids = <String>{};
    final usedSources = <String>{};
    for (final mode in modes) {
      final tips = AnatomyTips.forMode(mode);
      expect(tips, hasLength(10));
      for (final tip in tips) {
        expect(ids.add(tip.id), isTrue, reason: tip.id);
        expect(tip.title(true), isNotEmpty);
        expect(tip.title(false), isNotEmpty);
        expect(tip.description(true), isNotEmpty);
        expect(tip.description(false), isNotEmpty);
        expect(tip.title(true), isNot(tip.title(false)));
        expect(tip.sourceIds, isNotEmpty);
        for (final sourceId in tip.sourceIds) {
          final source = sources[sourceId];
          expect(source, isNotNull, reason: sourceId);
          expect(source!.modes, contains(mode), reason: tip.id);
          usedSources.add(sourceId);
        }
      }
    }
    expect(ids, hasLength(40));
    expect(usedSources, sources.keys.toSet());
    for (final source in sources.values) {
      expect(source.title, isNotEmpty);
      final uri = Uri.parse(source.url);
      expect(uri.scheme, 'https');
      expect(
        uri.host,
        anyOf([
          'www.who.int',
          'www.nhs.uk',
          'www.ncbi.nlm.nih.gov',
          'www.niams.nih.gov',
          'www.nia.nih.gov',
          'www.nhlbi.nih.gov',
          'www.niddk.nih.gov',
          'www.orthoinfo.org',
          'www.rnoh.nhs.uk',
          'pmc.ncbi.nlm.nih.gov',
        ]),
      );
      expect(source.modes, isNotEmpty);
    }
  });

  test('legacy muscle tabs share tips and source-category associations', () {
    expect(
      AnatomyTips.forMode(BodyMapViewMode.afterburn),
      AnatomyTips.forMode(BodyMapViewMode.recovery),
    );
    expect(
      AnatomyTips.forMode(BodyMapViewMode.trained),
      AnatomyTips.forMode(BodyMapViewMode.recovery),
    );
    for (final source in AnatomyTips.sources) {
      for (final mode in source.modes) {
        expect(
          AnatomyTips.forMode(
            mode,
          ).any((tip) => tip.sourceIds.contains(source.id)),
          isTrue,
        );
      }
    }
  });
}
