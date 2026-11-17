'use strict';

// Run: node test/anatomy_viewer_test.cjs
// Real bundled Babylon/glTF loader and GLBs, with NullEngine instead of WebGL.
// Checks application state/material/picking contracts; not visual or device FPS.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const root = path.resolve(__dirname, '..');
const B = require(path.join(root, 'assets/3d_viewer/babylon.js'));
vm.runInNewContext(fs.readFileSync(path.join(root, 'assets/3d_viewer/babylonjs.loaders.min.js'), 'utf8'), {
  BABYLON: B, require: () => B, module: {exports: {}}, exports: {},
  console, setTimeout, clearTimeout, TextDecoder, TextEncoder, atob, btoa,
});
const originalImport = B.SceneLoader.ImportMeshAsync;
const imports = [];
B.SceneLoader.ImportMeshAsync = async (names, url, file, scene) => {
  imports.push(file);
  const data = fs.readFileSync(path.join(root, 'assets/models', file));
  return originalImport(names, '', 'data:base64,' + data.toString('base64'), scene, undefined, '.glb');
};

const config = JSON.parse(fs.readFileSync(path.join(root, 'assets/3d_viewer/anatomy_config.json')));
const events = [];
const canvas = {setAttribute() {}, toDataURL: () => 'data:image/png;base64,TEST_FRAME'};
const status = {style: {}, textContent: ''};
const document = {getElementById: id => id === 'renderCanvas' ? canvas : status,
  body: {style: {}, dataset: {}}, documentElement: {}, hidden: false};
const window = {dispatchEvent: e => events.push(e.detail), addEventListener() {}};
const context = vm.createContext({BABYLON: B, URL, URLSearchParams, console, document, window,
  CustomEvent: class {constructor(type, options) {this.type = type; this.detail = options.detail;}},
  location: {search: '?expanded=true', href: 'http://127.0.0.1/3d_viewer/index.html'},
  setTimeout, clearTimeout, performance, testConfig: config,
});
let source = fs.readFileSync(path.join(root, 'assets/3d_viewer/anatomy_viewer.js'), 'utf8');
new vm.Script(source);
const start = source.indexOf('  start().catch');
assert(start > 0, 'Viewer startup hook has changed; update the harness');
source = source.slice(0, start) + `
  window.__test = {records, selectionMaterials, selectionKey, resizeViewport,
    get paused(){return state.paused},get defaultRadius(){return defaultRadius},
    get scene(){return scene}, get camera(){return camera}, get engine(){return engine},
    async init(){
      engine=new BABYLON.NullEngine({renderWidth:959,renderHeight:884,stencil:true});
      scene=new BABYLON.Scene(engine);
      camera=new BABYLON.ArcRotateCamera('test',Math.PI/2,Math.PI/2,3.8,new BABYLON.Vector3(0,.9,0),scene);
      camera.fov=.64;camera.minZ=.005;camera.maxZ=50;
      configureHorizontalOrbit();
      createGlowLayer();
      createLighting();
      camera.attachControl=()=>{};camera.detachControl=()=>{};
      config=testConfig;initialized=true;await applyState();
    }
  };
})();`;
vm.runInContext(source, context);

function confirmedPick(id) {
  const {scene, camera, engine, records} = window.__test;
  scene.render();
  const record = records.find(r => r.id === id);
  assert(record, 'Missing picking target ' + id);
  const mesh = record.mesh, positions = mesh.getVerticesData(B.VertexBuffer.PositionKind);
  const indices = mesh.getIndices(), world = mesh.computeWorldMatrix(true);
  const viewport = camera.viewport.toGlobal(engine.getRenderWidth(), engine.getRenderHeight());
  for (let i = 0, step = Math.max(1, Math.floor(indices.length / 3 / 150)); i < indices.length; i += step * 3) {
    const p = B.Vector3.Zero();
    for (let j = 0; j < 3; j++) p.addInPlace(B.Vector3.FromArray(positions, indices[i + j] * 3));
    p.scaleInPlace(1 / 3);
    const screen = B.Vector3.Project(p, world, scene.getTransformMatrix(), viewport);
    const hit = scene.pick(screen.x, screen.y, m => m.isEnabled() && m.isPickable, false, camera);
    if (hit?.pickedMesh === mesh) return {id, x: screen.x, y: screen.y};
  }
  return null;
}

async function main() {
  await window.__test.init();
  const api = window.kaizenAnatomy, internal = window.__test;
  let snap = api.snapshot();
  assert.equal(snap.ready, true);
  assert.equal(snap.mode, 'muscles');
  assert.equal(snap.glow.enabled,false,'Rested body does not run a glow pass');
  const camera = internal.camera, initialRadius = camera.radius;
  assert.equal(camera.lowerBetaLimit, Math.PI / 2);
  assert.equal(camera.upperBetaLimit, Math.PI / 2);
  assert.equal(camera.panningSensibility, 0);
  assert(camera.wheelDeltaPercentage > 0 && camera.pinchDeltaPercentage > 0);
  camera.beta = .3; camera.inertialBetaOffset = .4;
  camera.alpha = Math.PI * 8 + .3; camera.inertialAlphaOffset = .07;
  internal.scene.render();
  assert.equal(camera.beta, Math.PI / 2, 'Vertical drag cannot tilt the camera');
  assert.equal(camera.inertialBetaOffset, 0);
  assert.notEqual(camera.alpha, Math.PI * 8 + .3, 'Horizontal rotation remains enabled');
  camera.radius = 1.7; camera.inertialRadiusOffset = .08;
  internal.scene.render();
  assert.notEqual(camera.radius, 1.7, 'Zoom remains enabled');
  for (const [alpha, expected] of [[Math.PI / 4, 'back'], [-Math.PI / 4, 'front'],
    [Math.PI * 10 + Math.PI / 3, 'back'], [-Math.PI * 10 - Math.PI / 3, 'front']]) {
    camera.alpha = alpha; camera.radius = .85;
    camera.inertialAlphaOffset = .2; camera.inertialBetaOffset = .1; camera.inertialRadiusOffset = .3;
    assert.equal(api.toggleFrontBack(), expected);
    assert.equal(camera.alpha, expected === 'front' ? Math.PI / 2 : -Math.PI / 2);
    assert.equal(camera.radius, .85, 'Front/back keeps the current zoom');
    assert.equal(camera.beta, Math.PI / 2);
    assert.equal(camera.inertialAlphaOffset + camera.inertialBetaOffset + camera.inertialRadiusOffset, 0);
  }
  camera.radius = initialRadius; api.setView('front');
  const mainRecords=internal.records.filter(r=>r.asset==='main');
  const organShell=mainRecords.find(r=>r.id==='neutral.body');
  const studioShell=mainRecords.find(r=>r.id==='neutral.studio');
  assert.equal(mainRecords.length,198);
  const studioMuscleCount=snap.pickable.length;
  assert.equal(studioMuscleCount,80);
  assert(studioShell.mesh.isEnabled()&&!organShell.mesh.isEnabled());
  assert.equal(studioShell.mesh.isPickable,false);
  assert.equal(internal.scene.getMeshByName('Studio contact shadow').isPickable,false);
  assert(internal.scene.getLightByName('Studio overhead').isEnabled());
  assert(!internal.scene.getLightByName('key').isEnabled());
  // Every training region represented in the GLB still has a surface to tap.
  assert.deepEqual(new Set(snap.pickable.map(r=>r.segment)),
    new Set(mainRecords.filter(r=>r.tissue==='muscle').map(r=>r.trainingSegment)));
  assert(snap.pickable.every(p => p.segment && config.segments[p.segment]));
  const frontPick = confirmedPick('rectus_abdominis.upper.l');
  assert(frontPick, 'The declared front must expose the actual rectus, not the back');
  assert(confirmedPick('biceps_brachii.l'),'The new biceps belly can be tapped from the front');
  api.setView('back');
  for(const id of ['trapezius.l','latissimus_dorsi.l','gluteus_maximus.l','gastrocnemius_medialis.l']){
    assert(confirmedPick(id),'Posterior surface can be tapped: '+id);
  }
  api.setView('front');
  assert.equal(api.select('rectus_abdominis.upper.l'), true);
  assert.equal(events.at(-1).upperBody,true,'Upper-body picks dock their card below the model');
  assert.equal(api.snapshot().selectedKey, 'muscle:abs-upper');
  assert.equal(api.snapshot().selectionMaterials, 2);
  assert.equal(api.snapshot().glow.enabled,true);
  assert.equal(api.snapshot().glow.meshes,2,'Selection glow is limited to its own meshes');
  const selected = internal.records.filter(r => internal.selectionMaterials.has(r.mesh));
  assert(selected.every(r => r.trainingSegment === 'abs-upper'));
  assert(selected.every(r => r.mesh.material !== r.material));
  assert(internal.records.filter(r => !selected.includes(r)).every(r => r.mesh.material === r.material));
  const selectedEventCount = events.filter(e => e.type === 'selected').length;
  const loadedEventCount = events.filter(e => e.type === 'loaded').length;
  const materialCount = internal.scene.materials.length;
  for (let i = 0; i < 10; i++) await api.setState({recovery: {abs: i % 2 ? 'recent' : 'almostReady'}, afterburn: ['abs']});
  assert.equal(events.filter(e => e.type === 'selected').length, selectedEventCount, 'State sync must not reopen popups');
  assert.equal(events.filter(e => e.type === 'loaded').length, loadedEventCount, 'Same-mode sync must not echo loaded');
  assert.equal(internal.scene.materials.length, materialCount, 'Selection clones must not accumulate');
  assert.equal(api.snapshot().selectionMaterials, 2);
  api.clearSelection();
  assert.equal(api.snapshot().selectionMaterials, 0);
  assert(internal.records.every(r => r.mesh.material === r.material));
  await api.setState({recovery: {}, afterburn: []});
  for (const r of internal.records) {
    if (r.baseColor) assert(r.material.albedoColor.equals(r.baseColor), 'Recovery colour must restore ' + r.id);
    if (r.material?.emissiveColor) assert(r.material.emissiveColor.equals(r.baseEmissive));
  }
  await api.setState({mode: 'skeleton'});
  snap = api.snapshot();
  assert.equal(snap.visibleMeshes, 474);
  assert(!internal.scene.getMeshByName('Studio contact shadow').isEnabled());
  assert(internal.scene.getLightByName('key').isEnabled());
  assert(!internal.scene.getLightByName('Studio overhead').isEnabled());
  assert(snap.pickable.every(r => ['bone', 'cartilage'].includes(r.tissue)));
  assert.equal(api.select('bone_femur_l'), true);
  await api.setState({mode: 'connective'});
  snap = api.snapshot();
  assert.equal(snap.selectedKey, null);
  assert.equal(snap.visibleMeshes, 496);
  assert(internal.records.filter(r => r.mesh.isEnabled()).every(r => r.asset === 'skeleton'));
  for (const r of internal.records.filter(r => ['tendon', 'ligament'].includes(r.tissue))) {
    const expected = r.tissue === 'tendon' ? [.72, .34, .37] : [.86, .84, .79];
    assert(r.baseColor.asArray().every((v, i) => Math.abs(v - expected[i]) < 1e-6),
      'The shipped base tissue color must match the white-ligament/pink-tendon design: ' + r.id);
  }
  await api.setState({mode: 'organs'});
  snap = api.snapshot();
  assert.equal(snap.pickable.length, 28);
  assert.equal(snap.visibleMeshes, 29);
  assert(organShell.mesh.isEnabled()&&!studioShell.mesh.isEnabled());
  assert.equal(api.select('organ.heart'), true);
  assert.equal(api.snapshot().selectedKey, 'organ:heart');
  const brains = internal.records.filter(r => r.tissue === 'organ' && r.organId === 'brain');
  assert.deepEqual(Array.from(brains, r => r.id).sort(), ['organ.brain', 'organ.brainstem', 'organ.cerebellum']);
  assert.equal(new Set(internal.records.filter(r => r.tissue === 'organ').map(r => r.organId)).size, 26);
  for (const brain of brains) {
    api.clearSelection(); assert.equal(api.select(brain.id), true);
    assert.equal(api.snapshot().selectedKey, 'organ:brain');
    assert.equal(api.snapshot().selectionMaterials, 3, 'All brain pieces highlight together');
    assert(brains.every(r => internal.selectionMaterials.has(r.mesh)));
    const event = events.filter(e => e.type === 'selected').at(-1);
    assert.equal(event.name, 'Gehirn'); assert.equal(event.nameLatin, 'Encephalon');
  }
  const core = internal.records.find(r => r.asset === 'main' && r.tissue === 'neutral');
  assert.equal(core.material.alpha, .075);
  assert.equal(core.material.disableDepthWrite, true);
  assert.equal(core.mesh.isPickable, false);
  await Promise.all([api.setState({mode: 'skeleton'}), api.setState({mode: 'organs'}), api.setState({mode: 'muscles'})]);
  snap = api.snapshot();
  assert.equal(snap.mode, 'muscles');assert.equal(snap.ready, true);assert.equal(snap.selectedKey, null);
  assert.equal(core.material.alpha, 1);assert.equal(core.material.disableDepthWrite, false);
  assert.equal(core.material.transparencyMode, B.PBRMaterial.PBRMATERIAL_OPAQUE);
  await api.setState({expanded: false});
  assert.equal(api.snapshot().pickable.length, 0);assert.equal(api.select('pectoralis_major.l'), false);
  await api.setState({expanded: true});
  assert.equal(api.select('pectoralis_major.l'), true);
  assert.equal(api.select('pectoralis_major.r'), true); // Same bilateral group toggles off.
  assert.equal(api.snapshot().selectedKey, null);
  // Actual muscle data drives exactly two stages; passive tissues have one
  // participation state, with no inference of tissue recovery or injury.
  const record = id => internal.records.find(r => r.id === id);
  await api.setState({recovery: {legs: 'recent'}, trained: ['legs'], afterburn: []});
  assert.equal(record('rectus_femoris.l').trainingLevel, 2);
  assert.equal(record('pectoralis_major.l').trainingLevel, 0);
  assert.equal(api.snapshot().glow.enabled,true);
  assert.equal(api.snapshot().glow.meshes,api.snapshot().trainingHighlights.filter(r=>r.tissue==='muscle').length,
    'Muscle tint and connective outlines have independent render passes');
  assert(!record('rectus_femoris.l').material.emissiveColor.equals(record('rectus_femoris.l').baseEmissive),
    'Training adds self-illumination as well as an albedo tint');
  const hardColor = record('rectus_femoris.l').material.albedoColor.clone();
  const redSwatch = hardColor.toGammaSpace();
  assert(redSwatch.r > .75 && redSwatch.g < .25 && redSwatch.b < .18,
    'High load must stay saturated red against the natural pink muscle surface');
  await api.setState({mode: 'connective'});
  const achilles = record('tendon_calcaneal_tendon_l');
  const acl = record('ligament_anterior_cruciate_ligament_l');
  for (const r of [achilles, acl]) {
    assert.equal(r.trainingLevel, 1); assert.equal(r.trainingKind, 'involvement');
    assert(r.material.albedoColor.equals(r.baseColor), 'Training preserves the pink/white tissue surface');
  }
  assert.equal(record('ligament_acromioclavicular_ligament_l').trainingLevel, 0);
  const involvementColor = acl.material.albedoColor.clone();
  assert(acl.glowColor.equals(achilles.glowColor), 'Both tissues share a quiet blue outer outline');
  assert(achilles.glowColor.b > achilles.glowColor.r * 2,
    'Connective involvement has a blue outline');
  for (const r of [achilles, acl]) {
    assert(r.material.emissiveColor.equals(r.baseEmissive), 'Involvement must not make the tissue surface glow');
    assert(r.material.albedoColor.equals(r.baseColor), 'Do not mix blue into the tissue surface');
  }
  const connectiveGlow = internal.scene.getHighlightLayerByName('Kaizen tissue outline');
  assert.equal(connectiveGlow.innerGlow, false);
  assert.equal(connectiveGlow.outerGlow, true);
  assert.equal(connectiveGlow.blurHorizontalSize, 1.25, 'Thin tissues use the resolved afterburn contour, not a subpixel halo');
  assert.equal(api.snapshot().tissueOutline.meshes,api.snapshot().trainingHighlights.length);
  assert(connectiveGlow.hasMesh(achilles.mesh), 'The tendon halo is present');
  assert(connectiveGlow.hasMesh(acl.mesh), 'The ligament halo is present');
  api.select(acl.id);
  assert(!connectiveGlow.hasMesh(acl.mesh), 'Selection temporarily replaces the blue contour');
  assert(acl.mesh.material.albedoColor.equals(B.Color3.FromHexString('#3fd07a').toLinearSpace()), 'Green selection has priority over the training outline');
  await api.setState({recovery: {legs: 'almostReady'}});
  assert.equal(record('rectus_femoris.l').trainingLevel, 1);
  assert(!record('rectus_femoris.l').material.albedoColor.equals(hardColor));
  const yellowColor = record('rectus_femoris.l').material.albedoColor;
  assert(yellowColor.r > yellowColor.b * 2 && yellowColor.g > yellowColor.b * 2,
    'Stage 1 must retain a warm yellow PBR albedo over the salmon base');
  assert(acl.material.albedoColor.equals(involvementColor), 'Connective involvement has no second stage');
  assert(acl.mesh.material.albedoColor.equals(B.Color3.FromHexString('#3fd07a').toLinearSpace()));
  api.clearSelection(); assert(acl.mesh.material.albedoColor.equals(involvementColor));
  assert(connectiveGlow.hasMesh(acl.mesh), 'Deselecting restores the blue contour');
  await api.setState({mode: 'skeleton'});
  const bone = internal.records.find(r => r.tissue === 'bone' && r.mesh.isEnabled());
  api.select(bone.id);
  assert(bone.mesh.material.albedoColor.equals(B.Color3.FromHexString('#3fd07a').toLinearSpace()), 'Selected bone is green');
  api.clearSelection();
  assert(bone.mesh.material.albedoColor.equals(bone.baseColor), 'Deselected bone restores its base color');
  assert.equal(record('cartilage_medial_meniscus_l').trainingLevel, 1);
  const cartilageColor = record('cartilage_medial_meniscus_l').material.albedoColor;
  assert(cartilageColor.equals(record('cartilage_medial_meniscus_l').baseColor),
    'Cartilage retains its surface color beneath the warm outer contour');
  assert(connectiveGlow.hasMesh(record('cartilage_medial_meniscus_l').mesh));
  assert(!connectiveGlow.hasMesh(achilles.mesh), 'Hidden connective meshes leave the outline pass');
  assert.equal(api.snapshot().tissueOutline.meshes,api.snapshot().trainingHighlights.length);
  assert.equal(record('cartilage_glenoid_labrum_l').trainingLevel, 0);
  assert.equal(record('tendon_tendon_of_extensor_digitorum_longus_l').trainingLevel, 1, 'Toe extensor tendon belongs to legs, not forearms');
  assert(internal.records.filter(r => ['bone', 'organ', 'neutral'].includes(r.tissue)).every(r =>
    r.trainingLevel === 0 && (!r.baseColor || r.material.albedoColor.equals(r.baseColor))));
  for (const recovery of [{legs: 'lightCircuit'}, {legs: 'none'}, {legs: 'unknown'}]) {
    await api.setState({recovery, trained: ['legs'], afterburn: []});
    assert.equal(record('rectus_femoris.l').trainingLevel, recovery.legs === 'lightCircuit' ? 1 : 0,
      'Weekly training must not prolong expired muscle load colors');
  }
  await api.setState({recovery: {}, trained: [], afterburn: ['legs']});
  assert.equal(record('rectus_femoris.l').trainingLevel, 0, 'Afterburn does not imply muscle load');
  api.select('cartilage_medial_meniscus_l');
  await api.setState({recovery: {}, trained: [], afterburn: []});
  assert.equal(record('cartilage_medial_meniscus_l').trainingLevel, 0);
  api.clearSelection();
  assert(internal.records.every(r => r.trainingLevel === 0 && (!r.baseColor || r.material.albedoColor.equals(r.baseColor))),
    'Clearing training and selection restores every original white/pink/muscle material');
  assert.equal(api.snapshot().glow.enabled,false,'No extra highlight pass remains after clearing training');
  assert.equal(api.snapshot().glow.meshes,0);
  assert.equal(api.snapshot().tissueOutline.enabled,false);
  assert.equal(api.snapshot().tissueOutline.meshes,0);
  assert(internal.records.every(r => !r.material?.emissiveColor || r.material.emissiveColor.equals(r.baseEmissive)),
    'Clearing training restores base emission, including previously selected tissues');
  // Afterburn is an independent, depth-tested outer contour in muscle mode.
  await api.setState({mode:'muscles',afterburn:['chest','unknown']});
  const chest=record('pectoralis_major.l');
  assert.equal(api.snapshot().afterburn.enabled,true);
  assert.equal(api.snapshot().afterburn.meshes,4,'Pectorals and serratus follow the existing chest mapping');
  assert(api.snapshot().afterburnHighlights.every(r=>r.group==='chest'));
  assert.equal(api.snapshot().glow.enabled,false,'Afterburn alone adds no training/selection glow');
  assert(chest.material.albedoColor.equals(chest.baseColor),'Afterburn never paints the muscle blue');
  assert(chest.material.emissiveColor.equals(chest.baseEmissive),'Afterburn does not change surface emission');
  const afterburnLayer=internal.scene.getHighlightLayerByName('Kaizen afterburn outline');
  assert.equal(afterburnLayer.innerGlow,false,'Only the outer silhouette glows');
  assert.equal(afterburnLayer.outerGlow,true);
  assert(afterburnLayer.blurHorizontalSize >= 2.5 && afterburnLayer.blurVerticalSize >= 2.5,
    'Active afterburn needs a resolved halo in phone-sized views');
  assert(afterburnLayer.hasMesh(chest.mesh));
  const layerCount=internal.scene.effectLayers.length,textureCount=internal.scene.textures.length;
  for(let i=0;i<8;i++){
    await api.setState({recovery:{chest:i%2?'recent':'almostReady'},afterburn:['chest'],theme:i%2?'light':'dark'});
    assert.equal(api.snapshot().afterburn.meshes,4);
    assert.equal(api.snapshot().trainingHighlights.length,4);
    assert.equal(api.snapshot().glow.meshes,0,'Blue edges do not mix with the red/yellow halo');
    assert(!chest.material.albedoColor.equals(chest.baseColor),'Recovery fill coexists with afterburn');
    api.select(chest.id);
    assert(chest.mesh.material.albedoColor.equals(B.Color3.FromHexString('#3fd07a').toLinearSpace()), 'Selected muscle is green in both themes');
    assert.equal(api.snapshot().afterburn.enabled,false,'Green selection takes precedence over blue edges');
    assert.equal(api.snapshot().glow.meshes,4);
    api.clearSelection();
    assert.equal(api.snapshot().afterburn.meshes,4,'Deselecting restores the active blue contour');
  }
  assert.equal(internal.scene.effectLayers.length,layerCount,'State/theme changes reuse the outline layer');
  assert.equal(internal.scene.textures.length,textureCount,'State changes do not accumulate render targets');
  await api.setState({expanded:false});
  assert.equal(api.snapshot().afterburn.meshes,4,'Compact muscle view also shows afterburn');
  await api.setState({expanded:true,afterburn:[]});
  assert.equal(api.snapshot().afterburn.enabled,false,'Expired afterburn disables its rendering pass');
  assert.equal(api.snapshot().afterburn.meshes,0);
  assert.equal(api.snapshot().glow.meshes,4,'Expiry restores the normal recovery halo');
  await api.setState({recovery:{},afterburn:Object.keys(config.segments).map(key=>config.segments[key].canonicalGroup)});
  assert.equal(api.snapshot().afterburn.meshes,studioMuscleCount,'All visible mapped muscles can glow together');
  assert(internal.records.filter(r=>afterburnLayer.hasMesh(r.mesh)).every(r=>r.tissue==='muscle'&&r.mesh.isEnabled()));
  for(const mode of ['skeleton','connective','organs']){
    await api.setState({mode});
    assert.equal(api.snapshot().afterburn.enabled,false,'Afterburn stays out of '+mode);
    assert.equal(api.snapshot().afterburnHighlights.length,0);
  }
  await api.setState({mode:'muscles',afterburn:['chest']});
  assert.equal(api.snapshot().afterburn.meshes,4,'Returning to muscles restores the contour');
  await api.setState({afterburn:[]});
  assert.equal(api.snapshot().afterburnHighlights.length,0);
  assert.equal(api.snapshot().afterburn.enabled,false);
  assert(internal.records.every(r=>!afterburnLayer.hasMesh(r.mesh)),'Expired meshes leave the outline layer');
  await api.setState({mode:'organs',organHealth:{heart:'good',lungs:'careful',intestines:'mixed'}});
  const nutrition=api.snapshot().nutritionHighlights;
  assert(nutrition.some(r=>r.organId==='heart'&&r.status==='good'));
  assert(nutrition.filter(r=>r.organId.startsWith('lung.')).every(r=>r.status==='careful'));
  assert(nutrition.some(r=>r.organId==='small_intestine'&&r.status==='mixed'));
  assert(!nutrition.some(r=>r.organId==='pancreas'),'Unmapped organs receive no invented nutrition score');
  assert.equal(api.snapshot().trainingHighlights.length,0,'Food signals stay separate from muscle load');
  assert.equal(api.snapshot().glow.meshes,nutrition.length);
  const heart=internal.records.find(r=>r.organId==='heart');
  assert(heart.material.emissiveColor.g>heart.baseEmissive.g,'Nutrition has gentle emission');
  await api.setState({mode:'muscles'});
  assert.equal(api.snapshot().glow.enabled,false,'Hidden organs do not keep a glow pass running');
  await api.setState({mode:'organs',organHealth:{}});
  assert.equal(api.snapshot().nutritionHighlights.length,0);
  assert.equal(api.snapshot().glow.enabled,false,'Expired nutrition restores base organ materials');
  await api.setState({mode: 'muscles'});
  api.select('rectus_femoris.l');
  assert.equal(events.at(-1).upperBody,false,'Lower-body picks dock the card above the model');
  api.clearSelection();
  const sceneBefore = internal.scene, importsBefore = imports.length;
  camera.radius = internal.defaultRadius * .7; camera.alpha = .8;
  assert.equal(api.captureFrame('flight-1'), true);
  assert.equal(internal.paused, true);
  assert.equal(events.at(-1).dataUrl, 'data:image/png;base64,TEST_FRAME');
  assert.equal(events.at(-1).requestId, 'flight-1');
  assert(!document.body.dataset.lastEvent.includes('base64'), 'PNG bytes must not enter DOM diagnostics');
  const aspect = internal.engine.getAspectRatio;
  let pausedRenders = 0;
  const renderObserver = internal.scene.onAfterRenderObservable.add(() => pausedRenders++);
  internal.engine.getAspectRatio = () => .2;
  internal.resizeViewport();
  assert.equal(pausedRenders, 1, 'A paused resized surface still receives one target frame');
  assert(Math.abs(camera.radius / internal.defaultRadius - .7) < 1e-9, 'Viewport resize keeps relative zoom');
  assert.equal(camera.alpha, .8); assert.equal(camera.beta, Math.PI / 2);
  internal.engine.getAspectRatio = aspect;
  await api.setState({paused: true, theme: 'light'});
  assert.equal(pausedRenders, 2, 'A paused material/state update renders once without starting a loop');
  internal.scene.onAfterRenderObservable.remove(renderObserver);
  await api.setState({paused: false});
  assert.equal(internal.paused, false); assert.equal(internal.scene, sceneBefore);
  assert.equal(imports.length, importsBefore, 'Capture/resize/reopen reuses the scene and assets');
  canvas.toDataURL = () => {throw new Error('Unavailable canvas capture');};
  assert.equal(api.captureFrame('flight-failed'), false);
  assert.equal(events.at(-1).dataUrl, null);
  await api.setState({paused: false});
  assert.equal(new Set(imports).size, 3);assert.equal(imports.length, 3, 'Each asset loads once');
  assert.deepEqual(Array.from(api.snapshot().errors), []);
  console.log(JSON.stringify({result: 'PASS', frontPick, defaultRadius: api.snapshot().camera.radius,
    contracts: ['real GLB import', 'front picking', 'bilateral region highlight', 'material restoration',
      'silent state sync', 'one load per asset', 'mode counts', 'no duplicated connective geometry',
      'organ transparency restoration', 'one joint brain selection and card', 'white ligaments and pink tendons',
      'strict horizontal orbit', 'zoom retained', 'front/back from current side preserves zoom',
      'two muscle load stages', 'one anatomically mapped tissue involvement stage', 'selection restores training/base',
      'bounded shared highlight pass', 'training emission and glow clear without residue',
      'afterburn outer contour, selection priority, expiry, mode isolation and bounded resources',
      'PNG transition capture and resume', 'resize preserves zoom and scene',
      'last state wins', 'collapsed picking disabled']}, null, 2));
  await api.setState({mode:'muscles',expanded:true,musclePicker:true,
    selectedSegments:['chest','calves'],recovery:{},afterburn:[]});
  const pickerMuscles=internal.records.filter(r=>r.tissue==='muscle'&&r.mesh.isEnabled());
  for(const segment of ['chest','calves']){
    const group=pickerMuscles.filter(r=>r.trainingSegment===segment);
    assert(group.length>0, 'Picker region exists: '+segment);
    assert(group.every(r=>r.material.albedoColor.g>r.material.albedoColor.r), 'Every chosen muscle stays green');
  }
  const pickerChest=pickerMuscles.find(r=>r.trainingSegment==='chest');
  const beforePick=events.length;
  api.select(pickerChest.id);api.select(pickerChest.id);
  assert.equal(events.length,beforePick+2,'Repeated picker taps both reach Flutter for toggling');
  assert.equal(events.at(-1).type,'selected');
  await api.setState({selectedSegments:['calves']});
  assert(pickerChest.material.albedoColor.equals(pickerChest.baseColor),'Chip removal restores the muscle material');
  await api.setState({musclePicker:false,selectedSegments:[]});
  assert(pickerMuscles.every(r=>r.material.albedoColor.equals(r.baseColor)),'Leaving the picker restores all materials');
  api.dispose();
}
const timeout = setTimeout(() => {console.error('Viewer contract test timed out');process.exit(1);}, 45000);
main().catch(error => {console.error(error.stack || error);window.kaizenAnatomy.dispose();process.exitCode = 1;})
  .finally(() => {clearTimeout(timeout);B.SceneLoader.ImportMeshAsync = originalImport;});
