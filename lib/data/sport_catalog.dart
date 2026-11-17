/// A practical selection of 40 popular club and leisure activities in Germany,
/// not an exact ranking (membership and participation measure different things).
/// Selection: https://www.dosb.de/service/bestandserhebung and
/// https://www.freizeitmonitor.de/2026/sportliche-aktivitaeten-2/
/// METs are approximate recreational intensities, informed by
/// https://pacompendium.com/ (2024 Adult Compendium); Padel uses a tennis proxy.
class SportActivity {
  const SportActivity(this.de, this.en, this.met, [this.aliases = const []]);

  final String de;
  final String en;
  final double met;
  final List<String> aliases;

  String label(bool german) => german ? de : en;

  bool matches(String query) => [
    de,
    en,
    ...aliases,
  ].any((name) => name.toLowerCase().contains(query.trim().toLowerCase()));

  static SportActivity? find(String name) {
    final key = name.trim().toLowerCase();
    for (final sport in sportCatalog) {
      if ([
        sport.de,
        sport.en,
        ...sport.aliases,
      ].any((label) => label.toLowerCase() == key)) {
        return sport;
      }
    }
    return null;
  }
}

const sportCatalog = <SportActivity>[
  SportActivity('Laufen', 'Running', 7.5, ['Joggen', 'Jogging']),
  SportActivity('Walking', 'Walking', 3.8, ['Gehen', 'Spazieren']),
  SportActivity('Nordic Walking', 'Nordic walking', 4.8),
  SportActivity('Wandern', 'Hiking', 5.3),
  SportActivity('Radfahren', 'Cycling', 7.5, ['Fahrradfahren']),
  SportActivity('Mountainbiken', 'Mountain biking', 8.5, ['MTB']),
  SportActivity('Schwimmen', 'Swimming', 6.0),
  SportActivity('Krafttraining', 'Strength training', 3.5, ['Fitness', 'Gym']),
  SportActivity('Calisthenics', 'Calisthenics', 3.8, ['Bodyweight']),
  SportActivity('Yoga', 'Yoga', 2.3),
  SportActivity('Pilates', 'Pilates', 2.8),
  SportActivity('Turnen', 'Gymnastics', 3.8),
  SportActivity('Tanzen', 'Dancing', 5.0),
  SportActivity('Fußball', 'Football', 7.0, ['Fussball', 'Soccer']),
  SportActivity('Basketball', 'Basketball', 6.5),
  SportActivity('Volleyball', 'Volleyball', 4.0),
  SportActivity('Beachvolleyball', 'Beach volleyball', 8.0),
  SportActivity('Handball', 'Handball', 8.0),
  SportActivity('Tennis', 'Tennis', 7.3),
  SportActivity('Padel', 'Padel', 6.0, ['Padel-Tennis', 'Paddle tennis']),
  SportActivity('Badminton', 'Badminton', 5.5),
  SportActivity('Tischtennis', 'Table tennis', 4.0, ['Pingpong']),
  SportActivity('Squash', 'Squash', 7.3),
  SportActivity('Golf', 'Golf', 4.5),
  SportActivity('Rudern', 'Rowing', 6.0),
  SportActivity('Paddeln / Kajak', 'Paddling / kayaking', 5.0, [
    'Paddel',
    'Kanu',
    'Kanufahren',
    'Canoeing',
    'Kayaking',
  ]),
  SportActivity('Stand-up-Paddling', 'Stand-up paddleboarding', 6.5, ['SUP']),
  SportActivity('Segeln', 'Sailing', 3.0),
  SportActivity('Surfen', 'Surfing', 3.0, ['Wellenreiten']),
  SportActivity('Boxen', 'Boxing', 7.8),
  SportActivity('Kampfsport', 'Martial arts', 5.3, [
    'Karate',
    'Judo',
    'Taekwondo',
  ]),
  SportActivity('Klettern', 'Climbing', 8.0),
  SportActivity('Bouldern', 'Bouldering', 8.8),
  SportActivity('Reiten', 'Horse riding', 5.5, ['Equestrian']),
  SportActivity('Skifahren', 'Skiing', 7.0, ['Ski']),
  SportActivity('Skilanglauf', 'Cross-country skiing', 6.8, ['Langlauf']),
  SportActivity('Snowboarden', 'Snowboarding', 5.3, ['Snowboard']),
  SportActivity('Inlineskaten', 'Inline skating', 7.5, ['Rollerblading']),
  SportActivity('Eislaufen', 'Ice skating', 7.0, ['Schlittschuhlaufen']),
  SportActivity('Leichtathletik', 'Athletics', 6.0, ['Track and field']),
];
