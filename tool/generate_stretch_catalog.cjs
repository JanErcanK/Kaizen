// Selected Free Exercise DB entries (Unlicense) with rewritten DE/EN guidance.
// Input: pinned names in tool/data/stretch_source_names.json.
const fs = require('node:fs');
const source = JSON.parse(fs.readFileSync('tool/data/stretch_source_names.json','utf8'));
const rows = `
90_90_Hamstring|Beinrückseite in Rückenlage (90/90)|hamstrings|Auf den Rücken legen, einen Oberschenkel senkrecht halten und das Knie langsam so weit wie angenehm strecken.|Lie on your back, hold one thigh upright and slowly straighten the knee as far as comfortable.
Adductor_Groin|Schmetterling im Sitzen|groin|Aufrecht sitzen, Fußsohlen zusammenlegen und die Knie ohne Druck nach außen sinken lassen.|Sit tall with the soles together and let the knees fall outward without pressing them down.
All_Fours_Quad_Stretch|Oberschenkeldehnung im Vierfüßlerstand|quads|Im Vierfüßlerstand einen Fuß vorsichtig zum Gesäß führen. Becken ruhig halten; bei Kniedruck abbrechen.|From all fours, gently bring one foot toward the buttock. Keep the pelvis steady; stop if the knee feels pressure.
Ankle_Circles|Fußgelenke kreisen|ankle|Im Sitzen einen Fuß anheben und langsam kleine Kreise in beide Richtungen beschreiben.|Sit with one foot lifted and slowly draw small circles in both directions.
Ankle_On_The_Knee|Gesäßdehnung im Vierersitz|glutes|Auf einem stabilen Stuhl einen Knöchel auf den anderen Oberschenkel legen. Mit geradem Rücken leicht vorbeugen; Knie entspannt lassen.|On a stable chair, rest one ankle on the opposite thigh. Hinge forward gently with a long back; keep the knee relaxed.
Arm_Circles|Arme kreisen|shoulders|Arme locker seitlich halten und kleine, langsame Kreise machen. Den Radius nur angenehm vergrößern.|Hold the arms loosely to the sides and make small, slow circles. Increase the range only as comfortable.
Calf_Stretch_Elbows_Against_Wall|Wadendehnung mit Unterarmen an der Wand|calves|Unterarme an die Wand legen, ein Bein zurückstellen und dessen Ferse bei gestrecktem Knie am Boden lassen.|Rest forearms against a wall, step one leg back and keep its heel down with the knee straight.
Calf_Stretch_Hands_Against_Wall|Wadendehnung an der Wand|calves|Hände an die Wand, ein Bein nach hinten. Hintere Ferse unten halten und das Gewicht sanft nach vorne verlagern.|Place hands on a wall and step one foot back. Keep the rear heel down while gently shifting forward.
Cat_Stretch|Katze-Kuh für den Rücken|back|Im Vierfüßlerstand den Rücken langsam runden und wieder sanft lang werden lassen. Mit der Atmung bewegen.|On all fours, slowly round the back and then gently lengthen it again. Move with your breathing.
Chair_Leg_Extended_Stretch|Beinrückseite auf dem Stuhl|hamstrings|Vorne auf einem stabilen Stuhl sitzen, ein Bein mit aufgestellter Ferse ausstrecken und aus der Hüfte leicht vorbeugen.|Sit near the front of a stable chair, extend one leg with the heel down and gently hinge forward at the hips.
Chair_Lower_Back_Stretch|Rückendehnung im Sitzen|back|Auf einem Stuhl sitzen, Füße fest abstellen und den Oberkörper langsam Richtung Oberschenkel sinken lassen.|Sit on a chair with feet planted and slowly lower the upper body toward the thighs.
Chair_Upper_Body_Stretch|Schulteröffnung am Stuhl|shoulders|Vor einem rutschfesten Stuhl knien, Unterarme auflegen und die Hüfte sanft nach hinten schieben. Rücken lang halten.|Kneel before a non-slip chair, rest forearms on it and gently move the hips back while keeping a long spine.
Chest_And_Front_Of_Shoulder_Stretch|Brustöffnung am Türrahmen|chest|Unterarm seitlich an einen Türrahmen legen und den Körper vorsichtig wegdrehen. Die Schulter nicht nach vorne drücken.|Rest a forearm against a door frame and gently turn away. Avoid pushing the shoulder forward.
Childs_Pose|Kindhaltung|back|Aus dem Kniestand das Gesäß Richtung Fersen bewegen und die Arme nach vorne ablegen. Nur so tief gehen, wie Knie und Hüfte es zulassen.|From kneeling, move the hips toward the heels and reach the arms forward. Stay within comfortable knee and hip motion.
Chin_To_Chest_Stretch|Sanfte Nackendehnung nach vorne|neck|Aufrecht sitzen und das Kinn langsam Richtung Brust neigen. Nicht mit den Händen am Kopf ziehen.|Sit tall and slowly lower the chin toward the chest. Do not pull on the head with your hands.
Dynamic_Back_Stretch|Dynamische Rückenöffnung|back|Arme vor dem Körper ausstrecken, Schulterblätter sanft auseinanderbewegen und wieder lösen.|Reach the arms forward, gently separate the shoulder blades and release again.
Dynamic_Chest_Stretch|Dynamische Brustöffnung|chest|Arme langsam seitlich öffnen und vor dem Körper wieder schließen. Ohne Schwung im angenehmen Bereich bleiben.|Slowly open the arms sideways and bring them together in front. Stay comfortable and avoid swinging.
Elbows_Back|Brustöffnung mit Ellenbogen hinten|chest|Hände locker an die Hüften legen und die Ellenbogen vorsichtig nach hinten führen, ohne ins Hohlkreuz zu gehen.|Rest hands lightly on the hips and gently draw elbows back without arching the lower back.
Front_Leg_Raises|Kontrolliertes Beinheben nach vorne|hamstrings|An einer Stütze festhalten und ein fast gestrecktes Bein langsam nach vorne anheben und absenken.|Hold a support and slowly lift a nearly straight leg forward, then lower it again.
Groin_and_Back_Stretch|Grätschsitz mit Vorbeuge|groin|Mit bequem gegrätschten Beinen sitzen und aus der Hüfte leicht nach vorne neigen. Rücken lang und Knie locker halten.|Sit with legs comfortably apart and hinge slightly forward. Keep the back long and knees relaxed.
Groiners|Leistendehnung im tiefen Ausfallschritt|groin|Aus dem Stütz einen Fuß neben die gleichseitige Hand setzen. Hinteres Knie ablegen und das Becken sanft sinken lassen.|From a plank, step one foot beside the same-side hand. Lower the rear knee and gently settle the pelvis.
Hamstring_Stretch|Beinrückseite im Stand|hamstrings|Eine Ferse niedrig auflegen, Knie leicht beugen und den Oberkörper mit geradem Rücken aus der Hüfte neigen.|Rest one heel on a low support, soften the knee and hinge forward with a long back.
Hug_Knees_To_Chest|Beide Knie zur Brust|back|In Rückenlage beide Knie locker Richtung Brust führen. Schultern ablegen und ruhig weiteratmen.|Lie on your back and gently bring both knees toward the chest. Relax the shoulders and breathe normally.
IT_Band_and_Glute_Stretch|Seitliche Hüftdehnung|glutes|Im Stand ein Bein hinter das andere kreuzen und die Hüfte sanft zur Seite schieben. An einer Stütze festhalten.|Stand with one leg crossed behind the other and gently move the hip sideways. Hold a support for balance.
Inchworm|Raupe mit kleinen Handschritten|hamstrings|Aus einer lockeren Vorbeuge mit leicht gebeugten Knien die Hände langsam nach vorne setzen und wieder zurücklaufen.|From a relaxed forward fold with soft knees, slowly walk the hands forward and back.
Knee_Across_The_Body|Knie zur gegenüberliegenden Körperseite|glutes|In Rückenlage ein gebeugtes Knie sanft zur Gegenseite führen. Beide Schultern möglichst locker am Boden lassen.|Lying on your back, gently guide one bent knee across the body. Keep both shoulders relaxed on the floor.
Kneeling_Forearm_Stretch|Unterarmdehnung im Kniestand|forearms|Im Vierfüßlerstand die Finger vorsichtig Richtung Knie drehen und das Gewicht nur leicht zurückverlagern.|On all fours, gently turn the fingers toward the knees and shift the weight back only slightly.
Kneeling_Hip_Flexor|Hüftbeuger im halben Kniestand|hipFlexors|Ein Knie weich unterlegen, den anderen Fuß vorne aufstellen. Becken leicht aufrichten und die Hüfte ohne Hohlkreuz nach vorne bewegen.|Pad one knee and place the other foot in front. Gently tuck the pelvis and move forward without arching the back.
Leg-Up_Hamstring_Stretch|Beinrückseite mit erhöhtem Bein|hamstrings|Eine Ferse auf eine niedrige, feste Ablage legen. Hüfte gerade halten und mit langem Rücken sanft vorbeugen.|Place one heel on a low, stable support. Keep hips square and hinge gently forward with a long back.
Lying_Bent_Leg_Groin|Schmetterling in Rückenlage|groin|In Rückenlage die Fußsohlen zusammenstellen und Knie locker nach außen sinken lassen. Bei Bedarf Kissen unterlegen.|Lie on your back with soles together and let knees relax outward. Support them with pillows if needed.
Lying_Glute|Gesäßdehnung in Rückenlage|glutes|Einen Knöchel auf den anderen Oberschenkel legen und das untere Bein sanft heranziehen. Nicht auf das gekreuzte Knie drücken.|Cross one ankle over the opposite thigh and gently draw the supporting leg closer. Do not press on the crossed knee.
Lying_Hamstring|Beinrückseite mit Handtuch|hamstrings|In Rückenlage ein Handtuch hinter den angehobenen Oberschenkel legen und das Knie langsam angenehm strecken.|Lying on your back, support a raised thigh with a towel and slowly straighten the knee within a comfortable range.
Lying_Prone_Quadriceps|Vorderer Oberschenkel in Bauchlage|quads|In Bauchlage ein Knie beugen und den Fuß sanft Richtung Gesäß führen. Becken auf der Unterlage lassen.|Lie face down, bend one knee and gently guide the foot toward the buttock. Keep the pelvis on the surface.
Middle_Back_Stretch|Mittlerer Rücken im Sitzen|back|Aufrecht sitzen, die Hände vorne verschränken und nach vorne schieben, sodass die Schulterblätter auseinandergehen.|Sit tall, clasp the hands in front and reach forward to separate the shoulder blades.
On_Your_Side_Quad_Stretch|Vorderer Oberschenkel in Seitenlage|quads|Auf die Seite legen, das obere Knie beugen und den Fuß sanft zum Gesäß führen. Knie nebeneinander und Becken ruhig halten.|Lie on your side, bend the top knee and gently bring the foot toward the buttock. Keep knees together and pelvis steady.
One_Arm_Against_Wall|Seitlicher Rücken an der Wand|back|Eine Hand über Kopfhöhe an die Wand legen und die Hüfte langsam nach hinten bewegen. Schulter entspannt lassen.|Place one hand high on a wall and slowly move the hips backward. Keep the shoulder relaxed.
One_Knee_To_Chest|Ein Knie zur Brust|glutes|In Rückenlage ein Knie locker zur Brust führen, während das andere Bein bequem liegen bleibt.|Lie on your back and gently bring one knee toward the chest while the other leg rests comfortably.
Overhead_Stretch|Lange Streckung über Kopf|abs|Aufrecht stehen, beide Arme nach oben führen und den Oberkörper sanft in die Länge ziehen. Rippen nicht nach vorne schieben.|Stand tall, reach both arms overhead and gently lengthen the torso without flaring the ribs.
Overhead_Triceps|Trizepsdehnung über Kopf|triceps|Einen Arm über Kopf beugen und die andere Hand locker an den Ellenbogen legen. Ohne starken Zug halten.|Bend one arm overhead and rest the other hand lightly on the elbow. Hold without pulling hard.
Seated_Biceps|Bizepsdehnung im Sitzen|biceps|Auf dem Boden sitzen, Hände etwas hinter dem Körper abstützen und die Brust vorsichtig aufrichten. Ellenbogen nicht überstrecken.|Sit on the floor with hands a little behind you and gently lift the chest. Avoid locking the elbows backward.
Seated_Calf_Stretch|Wadendehnung im Sitzen|calves|Mit ausgestrecktem Bein sitzen und ein Handtuch um den Vorfuß legen. Fußspitze sanft heranziehen, Knie locker lassen.|Sit with one leg extended and a towel around the forefoot. Gently draw the toes toward you with the knee relaxed.
Seated_Floor_Hamstring_Stretch|Beinrückseite im Langsitz|hamstrings|Im Langsitz die Knie leicht beugen und aus der Hüfte nach vorne neigen. Nicht versuchen, die Zehen mit rundem Rücken zu erzwingen.|Sit with legs forward, soften the knees and hinge from the hips. Avoid rounding the back to force a toe touch.
Seated_Glute|Gesäßdehnung im aufrechten Sitz|glutes|Im Sitzen ein Bein über das andere stellen und das gebeugte Knie sanft zum Oberkörper führen. Aufrecht bleiben.|Sit with one leg crossed over the other and gently bring the bent knee toward the torso. Stay upright.
Seated_Overhead_Stretch|Seitliche Dehnung im Sitzen|abs|Aufrecht sitzen, einen Arm über Kopf heben und den Oberkörper leicht zur Gegenseite neigen. Beide Sitzknochen belasten.|Sit tall, raise one arm overhead and lean gently to the opposite side. Keep weight on both sitting bones.
Shoulder_Circles|Schultern kreisen|shoulders|Schultern langsam nach oben, hinten und unten rollen. Danach die Richtung wechseln und den Nacken locker lassen.|Slowly roll shoulders up, back and down. Reverse direction while keeping the neck relaxed.
Shoulder_Stretch|Schulter quer vor der Brust|shoulders|Einen Arm vor der Brust zur Gegenseite führen und am Oberarm sanft unterstützen. Schulter unten lassen.|Bring one arm across the chest and gently support the upper arm. Keep the shoulder down.
Side_Neck_Stretch|Seitliche Nackendehnung|neck|Aufrecht sitzen und ein Ohr langsam Richtung Schulter neigen. Beide Schultern unten lassen und nicht am Kopf ziehen.|Sit tall and slowly tilt one ear toward the shoulder. Keep both shoulders down and do not pull the head.
Spinal_Stretch|Sanfte Rückendrehung im Sitzen|back|Aufrecht auf einem Stuhl sitzen, Füße fest aufstellen und Brustkorb langsam zur Seite drehen. Hände nur locker ablegen.|Sit tall on a chair with feet planted and slowly rotate the rib cage to one side. Rest the hands lightly without pulling.
Standing_Biceps_Stretch|Bizepsdehnung an der Wand|biceps|Eine Hand seitlich hinter dem Körper an die Wand legen und den Oberkörper vorsichtig wegdrehen. Ellenbogen weich halten.|Place one hand on a wall slightly behind you and gently turn the torso away. Keep the elbow soft.
Standing_Gastrocnemius_Calf_Stretch|Wade mit gestrecktem Knie|calves|Im Schrittstand das hintere Knie gestreckt und die Ferse unten lassen. Gewicht langsam nach vorne verlagern.|In a split stance, keep the rear knee straight and heel down. Slowly move the weight forward.
Standing_Hip_Flexors|Hüftbeugerdehnung im Stand|hipFlexors|Einen Fuß zurückstellen, Becken leicht aufrichten und das vordere Knie beugen. Rumpf aufrecht halten.|Step one foot back, gently tuck the pelvis and bend the front knee. Keep the torso upright.
Standing_Lateral_Stretch|Seitliche Rumpfdehnung im Stand|abs|Hüftbreit stehen und einen Arm über Kopf zur Gegenseite führen. Becken ruhig halten und nicht nach vorne kippen.|Stand hip-width apart and reach one arm overhead to the opposite side. Keep the pelvis steady and avoid leaning forward.
Standing_Soleus_And_Achilles_Stretch|Tiefe Wade mit gebeugtem Knie|calves|Im Schrittstand beide Knie leicht beugen. Hintere Ferse am Boden lassen und nur sanften Zug in der tiefen Wade suchen.|In a split stance, soften both knees. Keep the rear heel down and seek only a gentle stretch in the lower calf.
Tricep_Side_Stretch|Trizepsdehnung seitlich|triceps|Einen gebeugten Arm vor den Körper führen und am Oberarm sanft zur Gegenseite unterstützen.|Bring one bent arm across the body and gently support the upper arm toward the opposite side.
Upper_Back_Stretch|Oberer Rücken mit verschränkten Händen|back|Hände vor der Brust verschränken, Arme nach vorne schieben und den oberen Rücken sanft runden.|Clasp hands in front of the chest, reach forward and gently round the upper back.
Worlds_Greatest_Stretch|World's Greatest Stretch|hipFlexors|Im Ausfallschritt die Hand neben dem vorderen Fuß aufsetzen und den Brustkorb langsam zur offenen Seite drehen. Hinteres Knie bei Bedarf ablegen.|In a lunge, place a hand beside the front foot and slowly turn the chest toward the open side. Lower the rear knee if needed.
Wrist_Circles|Handgelenke kreisen|forearms|Unterarme locker halten und mit den Händen langsam kleine Kreise in beide Richtungen machen.|Relax the forearms and slowly circle the hands in both directions.
`.trim().split('\n').map(line=>line.split('|'));
const extra = [
 ['shin_seated','Fußrücken im Sitzen dehnen','Seated top-of-foot stretch','shins','Im Sitzen einen Fuß leicht anheben und Fuß sowie Zehen langsam nach unten ausstrecken. Nicht gegen Widerstand drücken.','Sit and lift one foot slightly, then slowly point the foot and toes downward. Do not push against resistance.'],
 ['toe_mobility','Zehen öffnen und schließen','Toe opening and closing','feet','Im Sitzen die Zehen langsam spreizen und wieder entspannen. Danach locker beugen und strecken, ohne zu krallen.','While sitting, slowly spread and relax the toes. Then gently bend and extend them without gripping hard.'],
 ['sole_stretch','Fußsohle sanft dehnen','Gentle sole stretch','feet','Im Sitzen einen Fuß auf dem anderen Oberschenkel ablegen. Die Zehen mit der Hand sanft Richtung Schienbein führen, bis leichter Zug in der Fußsohle entsteht.','Sit with one foot resting on the other thigh. Gently guide the toes toward the shin until a mild stretch is felt along the sole.'],
 ['pigeon_supported','Pigeon Stretch mit Unterstützung','Supported Pigeon Stretch','glutes','Ein Bein angewinkelt vor dem Körper ablegen, das andere nach hinten führen. Vorderes Gesäß mit einem Kissen stützen; bei Kniedruck die Rückenlage-Variante wählen.','Place one bent leg in front and extend the other behind. Support the front hip with a cushion; choose the lying glute stretch if the knee feels pressure.'],
 ['wrist_flexor','Handgelenkbeuger sanft dehnen','Gentle wrist flexor stretch','forearms','Arm nach vorne halten, Handfläche nach oben. Mit der anderen Hand die Finger vorsichtig nach unten führen. Ellenbogen leicht gebeugt lassen.','Reach one arm forward with the palm up. Gently guide the fingers down with the other hand, keeping the elbow slightly bent.'],
 ['wrist_extensor','Handgelenkstrecker sanft dehnen','Gentle wrist extensor stretch','forearms','Arm nach vorne halten, Handfläche nach unten. Hand locker abknicken und mit der anderen Hand sanft unterstützen.','Reach one arm forward with the palm down. Let the wrist bend and gently support it with the other hand.'],
 ['standing_quad','Vorderer Oberschenkel im Stand','Standing quad stretch','quads','An einer Stütze festhalten, ein Knie beugen und den Fuß sanft Richtung Gesäß führen. Knie nebeneinander halten.','Hold a support, bend one knee and gently guide the foot toward the buttock. Keep the knees together.'],
];
const entries=rows.map(([id,de,region,dd,ee])=>{
 const original=source.find(e=>e.id===id);if(!original)throw Error(id);
 return [id,de,original.name,region,dd,ee];
}).concat(extra);
const quote=s=>JSON.stringify(s).replaceAll('$','\\$');
const dart=`// Generated by tool/generate_stretch_catalog.cjs. See docs/STRETCH_CATALOG_SOURCES.txt.
class StretchExercise {
  const StretchExercise(this.id, this.nameDe, this.nameEn, this.region, this.instructionsDe, this.instructionsEn);
  final String id, nameDe, nameEn, region, instructionsDe, instructionsEn;
  String name(bool german) => german ? nameDe : nameEn;
  String instructions(bool german) => german ? instructionsDe : instructionsEn;
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    return [nameDe, nameEn, instructionsDe, instructionsEn, region, 'Dehnen Stretching Mobilität Mobility'].any((v) => v.toLowerCase().contains(q));
  }
}

const stretchExercises = <StretchExercise>[
${entries.map(e=>'  StretchExercise('+e.map(quote).join(', ')+'),').join('\n')}
];

List<StretchExercise> stretchesForRegion(String? region) {
  // Joint structures receive surrounding-muscle mobility, never ligament stretching.
  final regions = switch (region) {
    'knee' => ['quads', 'hamstrings'],
    'ankle' => ['calves', 'ankle'],
    'pelvis' => ['glutes', 'back'],
    'elbow' => ['forearms', 'biceps', 'triceps'],
    null || 'jaw' => <String>[],
    _ => [region],
  };
  const preferred = ['pigeon_supported', 'Lying_Glute', 'Spinal_Stretch', 'Cat_Stretch', 'Adductor_Groin', 'standing_quad', 'Kneeling_Hip_Flexor', 'Standing_Gastrocnemius_Calf_Stretch', 'Standing_Soleus_And_Achilles_Stretch', 'wrist_flexor', 'wrist_extensor'];
  final matches = stretchExercises.where((e) => regions.contains(e.region)).toList();
  matches.sort((a,b) {
    int rank(StretchExercise e) { final index = preferred.indexOf(e.id); return index < 0 ? preferred.length : index; }
    final result = rank(a).compareTo(rank(b));
    return result != 0 ? result : a.id.compareTo(b.id);
  });
  return matches.take(4).toList(growable: false);
}
`;
fs.writeFileSync('lib/data/stretch_exercise_catalog.dart',dart);
console.log(`Wrote ${entries.length} stretching and mobility exercises (${rows.length} database entries).`);
