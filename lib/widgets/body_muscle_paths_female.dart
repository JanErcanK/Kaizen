import 'body_muscle_paths.dart';

/// Female mannequin SVG paths.
///
/// Female-specific anatomy and hairstyle.
class BodyMusclePathsFemale {
  BodyMusclePathsFemale._();

  // ── Female-specific path data ──────────────────────────────────────────

  // Front chest: two naturally rounded breast shapes replacing the male pectorals.
  // ViewBox 0 0 724 1448; center X ≈ 362. Right is an exact mirror of left (x → 724-x).
  // Aligned with male pecs (≈ Y 318–433) so the upper pole sits at the clavicle
  // and the inframammary fold meets the top of the abs — not the mid-ribcage.
  static const List<String> _frontChest = [
    // Left breast – teardrop covering the pec, not hanging below it
    'M348 313 C326 306 292 308 268 326 C244 344 236 376 246 402 '
        'C256 424 280 436 308 430 C332 426 350 406 352 384 '
        'C354 360 354 333 348 313 Z',
    // Right breast – exact mirror of left around x=362
    'M376 313 C398 306 432 308 456 326 C480 344 488 376 478 402 '
        'C468 424 444 436 416 430 C392 426 374 406 372 384 '
        'C370 360 370 333 376 313 Z',
  ];

  // Softer cheek and jaw contour for the female mannequin. The ears are kept
  // as part of the same head path so the neck and head remain one silhouette.
  static const String _frontHead =
      'M362 108 C329 108 307 128 304 156 C302 174 303 194 310 211 '
      'C318 232 338 248 362 255 C386 248 406 232 414 211 '
      'C421 194 422 174 420 156 C417 128 395 108 362 108 Z '
      'M305 163 C294 158 288 168 290 183 C291 193 297 199 305 197 '
      'C303 186 303 175 305 163 Z '
      'M419 163 C430 158 436 168 434 183 C433 193 427 199 419 197 '
      'C421 186 421 175 419 163 Z';

  static const String _backHead =
      'M1081 101 C1049 101 1027 121 1024 149 C1022 167 1023 190 1030 208 '
      'C1038 230 1058 247 1081 254 C1104 247 1124 230 1132 208 '
      'C1139 190 1140 167 1138 149 C1135 121 1113 101 1081 101 Z '
      'M1025 160 C1014 155 1008 166 1010 181 C1011 192 1017 198 1026 196 '
      'C1024 184 1024 173 1025 160 Z '
      'M1137 160 C1148 155 1154 166 1152 181 C1151 192 1145 198 1136 196 '
      'C1138 184 1138 173 1137 160 Z';

  // Rounded chin-length bob with a side-swept fringe. The inner contour follows
  // the forehead and cheeks, leaving the face open instead of drawing a stripe.
  static const String _frontHair =
      'M308 221 C296 209 290 185 291 158 '
      'C292 128 300 106 318 93 C337 80 361 79 381 85 '
      'C406 93 423 117 426 147 C429 178 422 211 411 231 '
      'C405 242 397 239 392 228 C387 217 387 201 385 188 '
      'C383 172 376 157 365 145 C352 158 341 171 334 187 '
      'C327 202 323 219 321 231 C319 240 312 237 308 221 Z';

  // A soft sheen follows the crown and the swept part of the bob.
  static const String _frontHairSheen =
      'M307 133 C314 106 338 91 362 91 C385 91 405 104 415 126 '
      'C401 110 385 102 368 101 C343 99 322 112 307 140 Z';

  // The back view keeps the same rounded bob and ends at the nape, with no ponytail.
  static const String _backHair =
      'M1028 218 C1018 205 1017 184 1019 160 '
      'C1021 130 1029 106 1048 93 C1067 80 1095 80 1116 92 '
      'C1138 105 1148 130 1148 161 C1149 190 1144 218 1135 235 '
      'C1125 252 1103 258 1081 258 C1059 258 1037 251 1028 235 '
      'C1024 229 1024 223 1028 218 Z';

  static const String _backHairSheen =
      'M1038 129 C1044 105 1065 91 1088 91 C1110 91 1128 104 1138 127 '
      'C1123 107 1105 100 1086 101 C1065 101 1048 113 1038 137 Z';

  // ── Public path maps ───────────────────────────────────────────────────

  static Map<String, List<String>> get front => {
    ...BodyMusclePaths.front,
    'chest': _frontChest,
    'head': [_frontHead],
    'hair': [_frontHair, _frontHairSheen],
  };

  static Map<String, List<String>> get back => {
    ...BodyMusclePaths.back,
    'head': [_backHead],
    'hair': [_backHair, _backHairSheen],
  };
}
