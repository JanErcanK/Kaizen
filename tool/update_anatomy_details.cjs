// Maintain the bilingual atlas copy without changing mesh IDs or training data.
const fs = require('node:fs');
const path = 'assets/3d_viewer/anatomy_config.json';
const catalog = JSON.parse(fs.readFileSync(path, 'utf8'));
const bones = {
  femur: ['Oberschenkelknochen', 'Thigh bone', 'Trägt das Körpergewicht zwischen Hüfte und Knie und wirkt als Hebel beim Gehen, Aufstehen und Treppensteigen.', 'Carries body weight between hip and knee and acts as a lever for walking, standing up and climbing stairs.'],
  tibia: ['Schienbein', 'Shin bone', 'Überträgt den größten Teil der Last vom Knie zum Sprunggelenk und bildet die innere Führung des Sprunggelenks.', 'Transfers most of the load from the knee to the ankle and forms the inner side of the ankle joint.'],
  fibula: ['Wadenbein', 'Outer lower-leg bone', 'Bildet den Außenknöchel, stabilisiert das Sprunggelenk und bietet Ansatzstellen für Fuß- und Unterschenkelmuskeln.', 'Forms the outer ankle, stabilizes the ankle joint and anchors foot and lower-leg muscles.'],
  ulna: ['Elle', 'Inner forearm bone', 'Bildet die knöcherne Führung des Ellenbogens. Zusammen mit der Speiche stabilisiert sie den Unterarm und ermöglicht das Drehen der Hand.', 'Forms the hinge of the elbow. Together with the radius it stabilizes the forearm and allows the hand to turn.'],
  radius: ['Speiche', 'Thumb-side forearm bone', 'Überträgt Kräfte von der Hand zum Ellenbogen. Sie trägt einen großen Teil des Handgelenks und dreht sich beim Wenden der Hand um die Elle.', 'Transfers forces from the hand to the elbow, supports much of the wrist and rotates around the ulna when turning the palm.'],
  humerus: ['Oberarmknochen', 'Upper-arm bone', 'Verbindet Schulter und Ellenbogen und dient als Hebel zum Heben, Ziehen und Drücken mit dem Arm.', 'Connects shoulder and elbow and acts as a lever for lifting, pulling and pushing with the arm.'],
  sacrum: ['Kreuzbein', 'Base of the spine', 'Verbindet die Wirbelsäule mit dem Becken und verteilt das Gewicht des Oberkörpers auf beide Hüftbeine.', 'Connects the spine to the pelvis and distributes upper-body weight to both hip bones.'],
  coccyx: ['Steißbein', 'Tailbone', 'Bietet Halt für Beckenbodenmuskeln und Bänder und unterstützt die Gewichtsverteilung beim zurückgelehnten Sitzen.', 'Anchors pelvic-floor muscles and ligaments and helps distribute weight when sitting back.'],
  hip_bone: ['Hüftbein', 'Hip bone', 'Trägt die Hüftpfanne, leitet Last vom Kreuzbein auf das Bein weiter und schützt die Organe im Becken.', 'Houses the hip socket, transfers load from the sacrum to the leg and protects pelvic organs.'],
  patella: ['Kniescheibe', 'Kneecap', 'Schützt die Vorderseite des Knies und verbessert die Hebelwirkung des vorderen Oberschenkelmuskels beim Strecken des Beins.', 'Protects the front of the knee and improves the leverage of the thigh muscles when straightening the leg.'],
  clavicle: ['Schlüsselbein', 'Collarbone', 'Hält die Schulter auf Abstand zum Brustkorb und überträgt Kräfte vom Arm auf den Rumpf.', 'Holds the shoulder away from the chest and transfers forces from the arm to the trunk.'],
  scapula: ['Schulterblatt', 'Shoulder blade', 'Trägt die Schultergelenkpfanne und bewegt sich auf dem Brustkorb mit, damit der Arm weit angehoben und gedreht werden kann.', 'Houses the shoulder socket and moves over the rib cage to allow the arm to lift and rotate.'],
  atlas_c1: ['Erster Halswirbel', 'First neck vertebra', 'Trägt den Kopf und bildet mit dem Schädel die Gelenke für die Nickbewegung.', 'Supports the head and forms the joints with the skull that allow nodding.'],
  axis_c2: ['Zweiter Halswirbel', 'Second neck vertebra', 'Sein Knochenzapfen bildet die Drehachse, um die sich der erste Halswirbel mit dem Kopf dreht.', 'Its bony peg forms the pivot around which the first neck vertebra and the head rotate.'],
  calcaneus: ['Fersenbein', 'Heel bone', 'Nimmt beim Auftreten Last auf. Die Achillessehne setzt hier an und hebt die Ferse beim Abstoßen und Zehenstand.', 'Takes load at heel contact. The Achilles tendon attaches here to lift the heel during push-off and tiptoe standing.'],
  talus: ['Sprungbein', 'Ankle bone', 'Leitet Körpergewicht vom Unterschenkel in den Fuß und ermöglicht das Heben und Senken des Fußes im Sprunggelenk.', 'Transfers body weight from the lower leg into the foot and allows the foot to move up and down at the ankle.'],
  navicular_bone: ['Kahnbein im Fuß', 'Inner midfoot bone', 'Verbindet das Sprungbein mit dem Mittelfuß und stützt das innere Längsgewölbe beim Stehen und Abrollen.', 'Links the ankle bone to the midfoot and supports the inner arch during standing and walking.'],
  cuboid_bone: ['Würfelbein im Fuß', 'Outer midfoot bone', 'Stützt den äußeren Fußrand und verbindet die Ferse mit den Mittelfußknochen der beiden äußeren Zehen.', 'Supports the outer edge of the foot and links the heel to the metatarsals of the two outer toes.'],
  medial_cuneiform_bone: ['Innerer Keilknochen im Fuß', 'Inner wedge bone of the foot', 'Stützt das Fußgewölbe und verbindet den inneren Mittelfuß mit dem Strahl der Großzehe für einen stabilen Abstoß.', 'Supports the arch and links the inner midfoot to the big-toe ray for stable push-off.'],
  intermediate_cuneiform_bone: ['Mittlerer Keilknochen im Fuß', 'Middle wedge bone of the foot', 'Verankert den zweiten Mittelfußknochen und trägt zur Stabilität des Quergewölbes bei.', 'Anchors the second metatarsal and helps stabilize the transverse arch.'],
  lateral_cuneiform_bone: ['Äußerer Keilknochen im Fuß', 'Outer wedge bone of the foot', 'Verbindet den dritten Mittelfußknochen mit der Fußwurzel und stützt das Quergewölbe.', 'Connects the third metatarsal to the midfoot and supports the transverse arch.'],
  scaphoid_bone: ['Handgelenkknochen an der Daumenseite', 'Thumb-side wrist bone', 'Verbindet beide Reihen der Handwurzel und überträgt Druck von der Hand auf die Speiche.', 'Bridges the two rows of wrist bones and transfers pressure from the hand to the radius.'],
  lunate_bone: ['Mittlerer Handgelenkknochen', 'Central wrist bone', 'Bildet einen Teil des Gelenks zur Speiche und hilft, Last bei gebeugtem und gestrecktem Handgelenk zu verteilen.', 'Forms part of the joint with the radius and helps distribute load as the wrist bends and extends.'],
  triquetrum_bone: ['Handgelenkknochen an der Kleinfingerseite', 'Little-finger-side wrist bone', 'Stabilisiert die Kleinfingerseite der Handwurzel und bewegt sich beim seitlichen Abwinkeln der Hand mit.', 'Stabilizes the little-finger side of the wrist and participates in side-to-side wrist movement.'],
  pisiform_bone: ['Kleiner Knochen am Handballen', 'Small heel-of-hand bone', 'Liegt in einer Beugesehne und verbessert deren Hebelwirkung beim Beugen des Handgelenks.', 'Sits within a flexor tendon and improves its leverage when bending the wrist.'],
  trapezium_bone: ['Handwurzelknochen unter dem Daumen', 'Wrist bone beneath the thumb', 'Bildet das Daumensattelgelenk, mit dem der Daumen den anderen Fingern beim Greifen gegenübergestellt wird.', 'Forms the saddle joint that allows the thumb to oppose the fingers when gripping.'],
  trapezoid_bone: ['Handwurzelknochen unter dem Zeigefinger', 'Wrist bone beneath the index finger', 'Stützt die Basis des Zeigefingers und stabilisiert die Hand beim festen Greifen.', 'Supports the base of the index finger and stabilizes the hand during firm gripping.'],
  capitate_bone: ['Zentraler Handwurzelknochen', 'Central bone of the wrist', 'Stützt den Mittelfingerstrahl und bildet einen zentralen Drehpunkt für Handgelenkbewegungen.', 'Supports the middle-finger ray and forms a central pivot for wrist movement.'],
  hamate_bone: ['Handwurzelknochen unter Ring- und Kleinfinger', 'Wrist bone beneath ring and little fingers', 'Stützt Ring- und Kleinfinger und bietet am Handballen Halt für Bänder und Muskeln.', 'Supports the ring and little fingers and anchors ligaments and muscles at the heel of the hand.'],
  mandible: ['Unterkiefer', 'Lower jaw', 'Trägt die unteren Zähne und bewegt sich beim Kauen, Sprechen und Öffnen des Mundes.', 'Holds the lower teeth and moves during chewing, speaking and opening the mouth.'],
  maxilla: ['Oberkiefer', 'Upper jaw', 'Trägt die oberen Zähne und bildet Teile des harten Gaumens, der Nasenhöhle und der Augenhöhle.', 'Holds the upper teeth and forms parts of the hard palate, nasal cavity and eye socket.'],
  hyoid_bone: ['Zungenbein', 'Tongue-supporting bone', 'Verankert Zungen- und Halsmuskeln und unterstützt Schlucken sowie die Lage des Kehlkopfs.', 'Anchors tongue and neck muscles and supports swallowing and the position of the voice box.'],
  frontal_bone: ['Stirnbein', 'Forehead bone', 'Schützt den vorderen Teil des Gehirns und bildet das Dach der Augenhöhlen.', 'Protects the front of the brain and forms the roof of the eye sockets.'],
  parietal_bone: ['Seitlicher Schädelknochen', 'Upper side of the skull', 'Bildet das Schädeldach und schützt die darunterliegenden Gehirnregionen.', 'Forms the upper skull and protects the underlying brain.'],
  temporal_bone: ['Schläfenbein', 'Temple bone', 'Schützt Teile des Gehirns, umschließt Mittel- und Innenohr und bildet einen Teil des Kiefergelenks.', 'Protects parts of the brain, houses the middle and inner ear and forms part of the jaw joint.'],
  occipital_bone: ['Hinterhauptbein', 'Back of the skull', 'Schützt den hinteren Gehirnbereich, verbindet den Schädel mit dem ersten Halswirbel und lässt das Rückenmark durch seine große Öffnung ziehen.', 'Protects the rear brain, joins the skull to the first neck vertebra and provides the opening for the spinal cord.'],
  sphenoid_bone: ['Zentraler Knochen der Schädelbasis', 'Central skull-base bone', 'Verbindet mehrere Schädelknochen, trägt Teile der Augenhöhlen und beherbergt die knöcherne Vertiefung für die Hirnanhangdrüse.', 'Joins several skull bones, forms parts of the eye sockets and houses the bony recess for the pituitary gland.'],
  ethmoid_bone: ['Knochen zwischen Nase und Augen', 'Bone between nose and eyes', 'Bildet Teile der Nasenhöhle und Augenhöhle; kleine Öffnungen lassen die Riechnerven zum Gehirn ziehen.', 'Forms parts of the nasal cavity and eye sockets; small openings let smell nerves reach the brain.'],
  lacrimal_bone: ['Kleiner Knochen am inneren Augenwinkel', 'Small inner eye-socket bone', 'Bildet einen Teil der inneren Augenhöhle und der Rinne, durch die Tränen zur Nase abfließen.', 'Forms part of the inner eye socket and the channel that drains tears toward the nose.'],
  nasal_bone: ['Nasenbein', 'Nose bone', 'Stützt den oberen Nasenrücken und gibt dem knöchernen Teil der Nase seine Form.', 'Supports the upper bridge and gives the bony part of the nose its shape.'],
  inferior_nasal_concha_bone: ['Untere Nasenmuschel', 'Lower nasal scroll bone', 'Vergrößert die Schleimhautfläche in der Nase und lenkt den Luftstrom zum Anwärmen und Befeuchten der Atemluft.', 'Increases the mucosal surface inside the nose and directs airflow for warming and humidifying inhaled air.'],
  palatine_bone: ['Hinterer Gaumenknochen', 'Rear palate bone', 'Bildet den hinteren harten Gaumen und trennt dort Mund- und Nasenhöhle beim Kauen und Schlucken.', 'Forms the rear hard palate, separating mouth and nasal cavity during chewing and swallowing.'],
  vomer: ['Knochen der Nasenscheidewand', 'Nasal septum bone', 'Bildet den unteren hinteren Teil der Nasenscheidewand und trennt die beiden Nasenhöhlen.', 'Forms the lower rear nasal septum and separates the two nasal cavities.'],
  zygomatic_bone: ['Wangenknochen', 'Cheekbone', 'Formt die Wange und den äußeren Rand der Augenhöhle und dient Kaumuskeln als Befestigung.', 'Shapes the cheek and outer eye socket and provides attachment for chewing muscles.'],
  body_of_sternum: ['Mittleres Brustbein', 'Central breastbone', 'Verbindet über Rippenknorpel mehrere Rippen und schützt die Organe hinter der vorderen Brustwand.', 'Connects several ribs through cartilage and protects the organs behind the front chest wall.'],
  manubrium_of_sternum: ['Oberes Brustbein', 'Upper breastbone', 'Verbindet die Schlüsselbeine und die oberen Rippen mit dem Brustkorb und überträgt Kräfte aus dem Schultergürtel.', 'Joins the collarbones and upper ribs to the chest and transfers forces from the shoulder girdle.'],
  xiphoid_process: ['Untere Brustbeinspitze', 'Lower tip of the breastbone', 'Bietet Ansatzstellen für Zwerchfell und Bauchmuskeln am unteren Ende des Brustbeins.', 'Provides attachment for the diaphragm and abdominal muscles at the lower end of the breastbone.'],
  sesamoid_bones_of_foot: ['Kleine Stützknochen unter der Großzehe', 'Small support bones under the big toe', 'Schützen die Beugesehnen unter dem Großzehengelenk und verbessern deren Hebel beim Abstoßen.', 'Protect the flexor tendons beneath the big-toe joint and improve their leverage during push-off.'],
};
const ordinals = {first:1,second:2,third:3,fourth:4,fifth:5,sixth:6,seventh:7,eighth:8,ninth:9,tenth:10,eleventh:11,twelfth:12};
function boneDetails(key) {
  if (bones[key]) return bones[key];
  let m;
  if ((m = key.match(/^vertebra_([ctl])(\d+)$/))) {
    const [de,en,dd,ee] = {
      c:['Halswirbel','Neck vertebra','Trägt und bewegt den Kopf mit den benachbarten Halswirbeln und schützt das Rückenmark im Wirbelkanal.','Supports and moves the head with adjacent neck vertebrae and protects the spinal cord in the vertebral canal.'],
      t:['Brustwirbel','Chest vertebra','Verbindet die Wirbelsäule mit den Rippen, stabilisiert den Brustkorb und schützt das Rückenmark.','Connects the spine to the ribs, stabilizes the chest and protects the spinal cord.'],
      l:['Lendenwirbel','Lower-back vertebra','Trägt einen großen Teil der Oberkörperlast und ermöglicht mit den Nachbarwirbeln das Beugen und Strecken des unteren Rückens.','Bears much of the upper-body load and works with adjacent vertebrae to bend and straighten the lower back.'],
    }[m[1]];
    return [`${de} ${m[2]}`,`${en} ${m[2]}`,dd,ee];
  }
  if ((m = key.match(/^(\w+)_rib$/))) {
    const n = ordinals[m[1]];
    return [`${n}. Rippe`, `Rib ${n}`, n>=11?'Schützt den oberen Bauchraum von hinten und bietet Atem- und Rumpfmuskeln Halt. Ihr vorderes Ende ist nicht am Brustbein befestigt.':'Schützt die Brustorgane und bewegt sich beim Atmen mit, um den Brustkorb zu erweitern und zu verkleinern.', n>=11?'Protects the upper abdomen from behind and anchors breathing and trunk muscles. Its front end is not attached to the breastbone.':'Protects chest organs and moves during breathing to expand and narrow the rib cage.'];
  }
  if ((m = key.match(/^(\w+)_meta(carpal|tarsal)_bone$/))) {
    const n=ordinals[m[1]], hand=m[2]==='carpal';
    return [`${n}. ${hand?'Mittelhand':'Mittelfuß'}knochen`,`${hand?'Palm':'Forefoot'} bone ${n}`,hand?`Stützt den ${['Daumen','Zeigefinger','Mittelfinger','Ringfinger','kleinen Finger'][n-1]} und überträgt Greifkräfte auf die Handwurzel.`:`Stützt die ${n}. Zehe, verteilt das Körpergewicht im Vorfuß und wirkt beim Abrollen und Abstoßen mit.`,hand?`Supports the ${['thumb','index finger','middle finger','ring finger','little finger'][n-1]} and transfers gripping forces to the wrist.`:`Supports toe ${n}, distributes weight across the forefoot and contributes to rolling through the foot and pushing off.`];
  }
  if ((m=key.match(/^(proximal|middle|distal)_phalanx_of_(\w+)_finger_of_(hand|foot)$/))) {
    const n=ordinals[m[2]], hand=m[3]==='hand', part={proximal:['Grundglied','Base segment'],middle:['Mittelglied','Middle segment'],distal:['Endglied','Tip segment']}[m[1]];
    const digit=hand?['Daumen','Zeigefinger','Mittelfinger','Ringfinger','Kleinfinger'][n-1]:`${n}. Zehe`;
    return [`${digit} – ${part[0]}`,`${part[1]} of ${hand?['thumb','index finger','middle finger','ring finger','little finger'][n-1]:`toe ${n}`}`,hand?(m[1]==='distal'?'Stützt die Fingerkuppe und ermöglicht mit den Beuge- und Strecksehnen präzises Greifen und Tasten.':'Bildet einen beweglichen Abschnitt des Fingers und wirkt als Hebel beim Umfassen und Festhalten von Gegenständen.'):(m[1]==='distal'?'Stützt die Zehenspitze und hilft, beim Abstoßen und Balancieren Druck auf den Boden zu übertragen.':'Bildet einen beweglichen Abschnitt der Zehe und unterstützt Gleichgewicht sowie das Abrollen des Fußes.'),hand?(m[1]==='distal'?'Supports the fingertip and works with flexor and extensor tendons for precise grip and touch.':'Forms a moving segment of the finger and acts as a lever when wrapping around and holding objects.'):(m[1]==='distal'?'Supports the toe tip and helps transfer pressure to the ground during push-off and balance.':'Forms a moving segment of the toe and helps balance and rolling through the foot.')];
  }
  if (/^(upper|lower)_/.test(key)) {
    const upper=key.startsWith('upper'), kind=key.includes('incisor')?['Schneidezahn','Incisor','Schneidet beim Abbeißen Nahrung in kleinere Stücke.','Cuts food into smaller pieces when biting.']:key.includes('canine')?['Eckzahn','Canine tooth','Hält und zerteilt Nahrung und führt die seitliche Bewegung des Kiefers mit.','Holds and tears food and helps guide sideways jaw movement.']:key.includes('premolar')?['Vormahlzahn','Premolar','Zerdrückt und zerkleinert Nahrung zwischen Eck- und Backenzähnen.','Crushes food between the canine teeth and molars.']:['Backenzahn','Molar','Zermahlt Nahrung mit seiner breiten Kaufläche.','Grinds food with its broad chewing surface.'];
    return [`${kind[0]} im ${upper?'Ober':'Unter'}kiefer`,`${upper?'Upper':'Lower'} ${kind[1].toLowerCase()}`,kind[2],kind[3]];
  }
  throw Error(`Unmapped bone: ${key}`);
}

// Regions are finer than the existing recovery groups: a leg tendon must not
// randomly receive a stretch for a different part of the leg.
function tendonRegion(k) {
  if (/tibialis_anterior|extensor_(digitorum|hallucis)_longus/.test(k)) return 'shins';
  if (/abductor_hallucis|(?:flexor|extensor)_(digitorum|hallucis)_brevis/.test(k)) return 'feet';
  if (/hallucis|digitorum_(longus|brevis)|fibularis|tibialis|calcaneal|gastrocnemius|soleus|plantaris/.test(k)) return 'calves';
  if (/pectineus|adductor_(longus|magnus)|gracilis/.test(k)) return 'groin';
  if (/vastus|rectus_femoris/.test(k)) return 'quads';
  if (/biceps_femoris|semimembranosus|semitendinosus|popliteus/.test(k)) return 'hamstrings';
  if (/gluteus|gemellus|obturator/.test(k)) return 'glutes';
  if (/iliacus|psoas|sartorius|tensor_fasciae|iliotibial/.test(k)) return 'hipFlexors';
  if (/pectoralis/.test(k)) return 'chest';
  if (/triceps|anconeus/.test(k)) return 'triceps';
  if (/biceps_brachii|coracobrachialis|brachialis/.test(k)) return 'biceps';
  if (/deltoid|infraspinatus/.test(k)) return 'shoulders';
  if (/trapezius|rhomboid|latissimus|serratus/.test(k)) return 'back';
  if (/capitis|sternocleidomast|levator_scapulae/.test(k)) return 'neck';
  if (/abdominis|rectus_sheath/.test(k)) return 'abs';
  if (/carpi|pollicis|digitorum|digiti|indicis|interossei|lumbrical|pronator|palmaris|brachioradialis/.test(k)) return 'forearms';
  throw Error(`Unmapped tendon: ${k}`);
}
function ligamentRegion(k) {
  if (/temporomandibular|mandibular|pterygospinous|stylohyoid/.test(k)) return 'jaw';
  if (/nuchal/.test(k)) return 'neck';
  if (/longitudinal|spinous|flava|intercornual|iliolumbar|costotransverse|head_of_rib/.test(k)) return 'back';
  if (/sacro|pubic|obturator/.test(k)) return 'pelvis';
  if (/iliofemoral|ischiofemoral|pubofemoral|acetabular|head_of_femur/.test(k)) return 'hipFlexors';
  if (/cruciate|menisco|poplite|collateral_ligament|head_of_fibular|fibular_head|knee/.test(k) && !/radial|ulnar/.test(k)) return 'knee';
  if (/tal|tars|calcaneo|plantar|foot|cune|cubo|tibiofibular|tibionavicular|tibiocalcaneal|intersesamoid|membrane_of_leg/.test(k)) return 'ankle';
  if (/clav|coraco|gleno|scapular|humeral|conoid|^ligament_trapezoid_ligament/.test(k)) return 'shoulders';
  if (/carp|hand|palmar|scapho|capit|hamate|triquet|lunate|piso|trapez|wrist|ulnopis/.test(k)) return 'forearms';
  if (/radius|radial|ulnar|forearm|oblique_cord|quadrate/.test(k)) return 'elbow';
  throw Error(`Unmapped ligament: ${k}`);
}
const regions = {
  calves:['Wade und Fuß','Calf and foot','beim Abstoßen, Heben und Führen des Fußes','pushing off, lifting and guiding the foot'],
  groin:['Oberschenkel innen','Inner thigh','beim Heranziehen des Beins und Stabilisieren der Hüfte','bringing the leg inward and stabilizing the hip'],
  shins:['Schienbein und Fußrücken','Shin and top of foot','beim Anheben des Fußes oder der Zehen','lifting the foot or toes'],
  feet:['Fuß und Zehen','Foot and toes','beim Führen der Zehen und Stabilisieren des Fußes','guiding the toes and stabilizing the foot'],
  quads:['Vorderer Oberschenkel','Front of thigh','beim Strecken des Knies','straightening the knee'],
  hamstrings:['Hinterer Oberschenkel und Kniekehle','Back of thigh and knee','beim Beugen und Stabilisieren des Knies','bending and stabilizing the knee'],
  glutes:['Gesäß und hintere Hüfte','Buttock and rear hip','beim Führen des Beins und Stabilisieren des Beckens','guiding the leg and stabilizing the pelvis'],
  hipFlexors:['Hüfte und Leiste','Hip and groin','beim Führen des Oberschenkels an der Hüfte','guiding the thigh at the hip'],
  chest:['Brust','Chest','beim Heranziehen und Vorführen des Arms','bringing the arm inward and forward'],
  triceps:['Hinterer Oberarm','Back of upper arm','beim Strecken des Ellenbogens','straightening the elbow'],
  biceps:['Vorderer Oberarm','Front of upper arm','bei Bewegungen des Arms','moving the arm'],
  shoulders:['Schulter','Shoulder','beim Heben, Drehen und Stabilisieren des Arms','lifting, rotating and stabilizing the arm'],
  back:['Rücken','Back','bei der Haltung und Bewegung von Rumpf und Schultergürtel','posture and movement of the trunk and shoulder girdle'],
  neck:['Nacken','Neck','beim Halten und Bewegen des Kopfes','supporting and moving the head'],
  abs:['Bauch','Abdomen','beim Beugen und Stabilisieren des Rumpfs','bending and stabilizing the trunk'],
  forearms:['Hand und Unterarm','Hand and forearm','beim Führen von Hand und Fingern','guiding the hand and fingers'],
  knee:['Knie','Knee'], ankle:['Fuß und Sprunggelenk','Foot and ankle'], pelvis:['Becken und Kreuzbein','Pelvis and sacrum'], elbow:['Ellenbogen','Elbow'], jaw:['Kiefer und Hals','Jaw and throat'],
};
for (const [id, v] of Object.entries(catalog.structures)) {
  const side=id.match(/[._]([lr])$/)?.[1];
  const suffixDe=side?` – ${side==='l'?'links':'rechts'}`:'';
  const suffixEn=side?` – ${side==='l'?'left':'right'}`:'';
  if (id.startsWith('bone_')) {
    const key=id.replace(/^bone_/,'').replace(/_[lr]$/,'');
    const [de,en,dd,ee]=boneDetails(key);
    Object.assign(v,{nameDe:de+suffixDe,nameEn:en+suffixEn,descriptionDe:dd,descriptionEn:ee,nameIsGeneric:false});
  }
  if (!['tendon','ligament'].includes(v.tissue)) continue;
  v.sourceName ??= v.nameEn;
  const tendon=v.tissue==='tendon';
  const region=tendon?tendonRegion(id):ligamentRegion(id);
  const [de,en,actionDe,actionEn]=regions[region];
  v.mobilityRegion=region;
  v.nameDe=`${tendon?'Sehne':'Band'} · ${de}${suffixDe}`;
  v.nameEn=`${en} ${tendon?'tendon':'ligament'}${suffixEn}`;
  if (id.includes('calcaneal_tendon')) {v.nameDe='Achillessehne'+suffixDe;v.nameEn='Achilles tendon'+suffixEn;}
  // Preserve the precise source atlas term beneath the everyday heading.
  if (['Tendo','Ligamentum'].includes(v.latinName)) {
    const muscleKey=id.replace(/^tendon\./,'');
    const muscle=catalog.muscles[muscleKey];
    v.latinName=muscle?.latinName?`Tendo · ${muscle.latinName}`:v.sourceName.replace(/\.[lr]$/,'');
  }
  if (id.includes('calcaneal_tendon')) v.latinName='Tendo calcaneus';
  if (id.includes('iliotibial_tract')) {v.nameDe='Sehnenplatte an der äußeren Hüfte'+suffixDe;v.nameEn='Outer hip tendon sheet'+suffixEn;v.latinName='Tractus iliotibialis';}
  if (id.includes('rectus_sheath')) {v.nameDe='Sehnenhülle am Bauch'+suffixDe;v.nameEn='Abdominal tendon sheath'+suffixEn;v.latinName='Vagina musculi recti abdominis';}
  v.descriptionDe=tendon?`Dieser Sehnenanteil überträgt Muskelzug ${actionDe}.`:`Diese Bandstruktur verbindet und stabilisiert Knochen im Bereich ${de}. Sie führt die Gelenkbewegung und begrenzt übermäßige Auslenkung.`;
  v.descriptionEn=tendon?`This tendon component transmits muscle force for ${actionEn}.`:`This ligament connects and stabilizes bones around the ${en.toLowerCase()}. It guides joint movement and limits excessive displacement.`;
  v.nameIsGeneric=false;
}
for(const url of [
  'https://openstax.org/books/anatomy-and-physiology-2e/pages/7-2-the-skull',
  'https://openstax.org/books/anatomy-and-physiology-2e/pages/7-3-the-vertebral-column',
  'https://openstax.org/books/anatomy-and-physiology-2e/pages/8-2-bones-of-the-upper-limb',
  'https://openstax.org/books/anatomy-and-physiology-2e/pages/8-4-bones-of-the-lower-limb',
]) if(!catalog.sources.includes(url)) catalog.sources.push(url);
fs.writeFileSync(path,JSON.stringify(catalog,null,2)+'\n');
console.log('Updated bone and connective atlas copy.');
