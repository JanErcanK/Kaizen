enum BodyMapViewMode {
  recovery,
  afterburn,
  trained,
  organs,
  skeleton,
  connective,
}

extension BodyMapAnatomyMode on BodyMapViewMode {
  String get anatomyMode => switch (this) {
    BodyMapViewMode.skeleton => 'skeleton',
    BodyMapViewMode.connective => 'connective',
    BodyMapViewMode.organs => 'organs',
    _ => 'muscles',
  };

  String anatomyLabel(bool german) => switch (this) {
    BodyMapViewMode.skeleton => german ? 'Skelett' : 'Skeleton',
    BodyMapViewMode.connective =>
      german ? 'Sehnen & Bänder' : 'Tendons & ligaments',
    BodyMapViewMode.organs => german ? 'Organe' : 'Organs',
    _ => german ? 'Muskeln' : 'Muscles',
  };
}
