/// Practical general-wellness suggestions, not measurements of organ function.
/// Food names are canonical keys in the existing food catalog.
class OrganGuidance {
  const OrganGuidance(this.tipsDe, this.tipsEn, this.foods, this.sources);

  final List<String> tipsDe;
  final List<String> tipsEn;
  final List<String> foods;
  final Map<String, String> sources;

  static const _diet =
      'https://www.who.int/news-room/fact-sheets/detail/healthy-diet';
  static const _digestion =
      'https://www.nhs.uk/live-well/eat-well/digestive-health/good-foods-to-help-your-digestion/';
  static const _kidney =
      'https://www.niddk.nih.gov/health-information/kidney-disease/chronic-kidney-disease-ckd/prevention';
  static const _sleep =
      'https://www.nhlbi.nih.gov/health/heart-healthy-living/sleep';

  static OrganGuidance forOrgan(String id) {
    final key = id.replaceFirst(RegExp(r'^organ\.'), '');
    if (key.startsWith('lung') || key == 'trachea') return _lungs;
    if (key.startsWith('kidney') ||
        key.startsWith('ureter') ||
        key == 'kidneys' ||
        key == 'urinary_bladder') {
      return _kidneys;
    }
    return switch (key) {
      'intestines' ||
      'duodenum' ||
      'small_intestine' ||
      'large_intestine' ||
      'rectum' ||
      'appendix' => _intestines,
      'brain' || 'cerebellum' || 'brainstem' => _brain,
      'heart' => _heart,
      'liver' => _liver,
      'stomach' || 'oesophagus' => _stomach,
      _ => _general,
    };
  }

  static double portion(String name) => switch (name) {
    'Chiasamen' => 15,
    'Walnüsse' => 30,
    'Olivenöl' => 10,
    'Griechischer Joghurt' => 150,
    'Haferflocken' => 50,
    _ => 100,
  };

  static const _lungs = OrganGuidance(
    [
      'Rauchfrei bleiben und Passivrauch meiden. Achte beim Sport auch auf die Luftqualität.',
      'Baue regelmäßige Bewegung ein, zum Beispiel zügiges Gehen oder Radfahren, und steigere dich langsam.',
      'Abwechslungsreiche Mahlzeiten unterstützen deine allgemeine Gesundheit. Einzelne Lebensmittel reinigen die Lunge nicht.',
    ],
    [
      'Stay smoke-free and avoid secondhand smoke. Consider air quality when exercising.',
      'Move regularly, for example with brisk walks or cycling, and build up gradually.',
      'Varied meals support general health. Individual foods do not cleanse the lungs.',
    ],
    ['Brokkoli', 'Äpfel', 'Beeren'],
    {
      'American Lung Association':
          'https://www.lung.org/lung-health-diseases/wellness/protecting-your-lungs',
      'WHO · Ernährung / Diet': _diet,
    },
  );

  static const _intestines = OrganGuidance(
    [
      'Iss abwechslungsreiche Ballaststoffquellen wie Hafer, Gemüse, Hülsenfrüchte und Samen. Steigere die Menge langsam und trinke dazu ausreichend.',
      'Naturbelassener Joghurt mit lebenden Kulturen kann eine Option sein, wenn du ihn verträgst. Bei Laktoseintoleranz passend ersetzen.',
      'Bewege dich täglich. Chiasamen kannst du in Joghurt oder Flüssigkeit quellen lassen; beginne mit einer kleinen Portion.',
    ],
    [
      'Vary fibre sources such as oats, vegetables, pulses and seeds. Increase gradually and drink enough alongside them.',
      'Plain yoghurt with live cultures can be an option if you tolerate it. Choose a suitable alternative for lactose intolerance.',
      'Move every day. Soak chia seeds in yoghurt or liquid and start with a small portion.',
    ],
    ['Griechischer Joghurt', 'Chiasamen', 'Haferflocken', 'Rote Linsen'],
    {
      'NHS · Verdauung / Digestion': _digestion,
      'NIDDK · Ballaststoffe / Fibre':
          'https://www.niddk.nih.gov/health-information/digestive-diseases/constipation/eating-diet-nutrition',
    },
  );

  static const _heart = OrganGuidance(
    [
      'Bewege dich regelmäßig und unterbrich langes Sitzen.',
      'Wähle häufig Vollkorn, Gemüse, Hülsenfrüchte und ungesalzene Nüsse. Verwende pflanzliche Öle und gehe sparsam mit Salz um.',
      'Plane ausreichend Schlaf und möglichst regelmäßige Schlafzeiten ein.',
    ],
    [
      'Move regularly and break up long periods of sitting.',
      'Choose whole grains, vegetables, pulses and unsalted nuts often. Use plant oils and go easy on salt.',
      'Make time for enough sleep and keep a regular sleep schedule.',
    ],
    ['Haferflocken', 'Walnüsse', 'Lachs', 'Olivenöl'],
    {'WHO · Ernährung / Diet': _diet, 'NHLBI · Schlaf / Sleep': _sleep},
  );

  static const _brain = OrganGuidance(
    [
      'Gib ausreichend Schlaf und regelmäßiger Bewegung einen festen Platz in deinem Alltag.',
      'Iss vielseitig: Vollkorn, Gemüse, Nüsse und Fisch können Teil ausgewogener Mahlzeiten sein.',
    ],
    [
      'Make enough sleep and regular movement part of your daily routine.',
      'Eat a varied diet: whole grains, vegetables, nuts and fish can be part of balanced meals.',
    ],
    ['Walnüsse', 'Lachs', 'Beeren', 'Haferflocken'],
    {'WHO · Ernährung / Diet': _diet, 'NHLBI · Schlaf / Sleep': _sleep},
  );

  static const _liver = OrganGuidance(
    [
      'Weniger Alkohol senkt alkoholbedingte Gesundheitsrisiken; alkoholfrei ist die risikoärmste Wahl.',
      'Bewege dich regelmäßig und bevorzuge vielseitige Mahlzeiten sowie ungesüßte Getränke.',
    ],
    [
      'Less alcohol lowers alcohol-related health risks; no alcohol is the lowest-risk choice.',
      'Move regularly and choose varied meals and unsweetened drinks.',
    ],
    ['Brokkoli', 'Haferflocken', 'Rote Linsen'],
    {
      'WHO · Alkohol / Alcohol':
          'https://www.who.int/news-room/fact-sheets/detail/alcohol',
      'WHO · Ernährung / Diet': _diet,
    },
  );

  static const _stomach = OrganGuidance(
    [
      'Achte darauf, welche Mahlzeiten du gut verträgst. Sehr fettige Speisen oder individuelle Auslöser können Beschwerden verstärken.',
      'Wähle passende Portionen und trinke regelmäßig. Passe Milchprodukte und Ballaststoffe an deine Verträglichkeit an.',
    ],
    [
      'Notice which meals agree with you. Very fatty foods or personal triggers can worsen symptoms.',
      'Choose comfortable portions and drink regularly. Adapt dairy and fibre to your tolerance.',
    ],
    ['Haferflocken', 'Bananen', 'Karotten'],
    {'NHS · Verdauung / Digestion': _digestion},
  );

  static const _kidneys = OrganGuidance(
    [
      'Gehe sparsam mit Salz um und bewege dich regelmäßig. Blutdruck und Blutzucker sind für die Nieren wichtig.',
      'Trinke passend zu deinem Bedarf. Bei einer Nierenerkrankung gelten individuell abgestimmte Trink- und Ernährungsempfehlungen.',
    ],
    [
      'Go easy on salt and move regularly. Blood pressure and blood sugar matter for your kidneys.',
      'Drink according to your needs. Kidney disease requires individually tailored fluid and dietary advice.',
    ],
    ['Äpfel', 'Haferflocken', 'Karotten'],
    {'NIDDK · Nieren / Kidneys': _kidney},
  );

  static const _general = OrganGuidance(
    [
      'Unterstütze deine allgemeine Gesundheit mit abwechslungsreichen Mahlzeiten und regelmäßiger Bewegung.',
      'Plane ausreichend Schlaf ein. Für dieses Organ gibt es kein einzelnes Lebensmittel mit garantierter Schutzwirkung.',
    ],
    [
      'Support your general health with varied meals and regular movement.',
      'Make time for enough sleep. No individual food guarantees protection for this organ.',
    ],
    ['Haferflocken', 'Brokkoli', 'Walnüsse'],
    {'WHO · Ernährung / Diet': _diet, 'NHLBI · Schlaf / Sleep': _sleep},
  );
}
