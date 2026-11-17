# Third-party notices and asset provenance

The [project rights notice](../LICENSE.md) covers only the author's original work. It does not replace licenses for dependencies, external datasets or artwork.

## Inventory

| Component | Evidence / source | Status |
| --- | --- | --- |
| Flutter and Dart packages | `pubspec.yaml`, locked versions in `pubspec.lock`; license texts in the resolved packages | Preserve package notices; review final release dependency inventory |
| Local `power3d` source | `third_party/power3d/LICENSE`, MIT, copyright 2026 rashbip (Rashidul Hasan Biplob) | Local prototype reference, not a dependency declared by the main app; retain its original license if included |
| Babylon.js viewer scripts | `assets/3d_viewer/babylon.js` and loaders; [upstream](https://github.com/BabylonJS/Babylon.js) | Bundled prototype scripts; exact version/source mapping and redistribution notices still need verification |
| Arm prototype | `tools/blender/create_arm_prototype.py` and `assets/models/` | Procedural generation script present; confirm exported assets match it before making provenance claims |
| Z-Anatomy reference archive | Local reference license identifies Z-Anatomy / BodyParts3D and additional component attributions | Research files excluded from Git; no blanket clearance inferred for derived assets |
| Exercise images, hero art and 2D body paths | `assets/exercises/`, hero images, muscle-map images and `lib/widgets/body_muscle_paths*.dart` | Author/source/permission records still need completion |
| Food product data | [Open Food Facts](https://world.openfoodfacts.org/terms-of-use) | Network lookup; review attribution and database/image reuse terms |
| Map data and tiles | [OpenStreetMap copyright](https://www.openstreetmap.org/copyright) and [tile policy](https://operations.osmfoundation.org/policies/tiles/) | Review visible attribution and distribution usage requirements |

The local Z-Anatomy notice includes CC-BY-SA material and separately credited components with non-commercial restrictions. It must not be summarized as one permission covering every asset. Establish which exact sources, if any, were used for each shipped path/model.

## Release evidence required

For every shipped image, model, font or vendored script, record source URL/version, author, license/permission, modifications and the location of required attribution. For commissioned/original assets, retain ownership evidence. Do not invent missing rights or assume a free app exempts redistribution from license conditions.

Avoid committing large research archives, Blender backups, personal captures and unused experimental dependencies just to populate a portfolio. Runtime assets referenced by `pubspec.yaml` must remain available. Removing a file from Git's future view does not remove historical copies.

This is an audit inventory, not a declaration that every existing asset has been cleared for distribution. Remaining provenance gaps are release blockers in [Release preparation](RELEASE.md).
