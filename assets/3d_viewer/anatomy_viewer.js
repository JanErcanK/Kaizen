'use strict';
(() => {
  const params = new URLSearchParams(location.search);
  const modes = new Set(['muscles','skeleton','connective','organs']);
  let state = {mode:modes.has(params.get('mode'))?params.get('mode'):'muscles',
    expanded:['1','true'].includes(params.get('expanded')),theme:params.get('theme')==='light'?'light':'dark',
    locale:params.get('locale')==='en'?'en':'de',recovery:{},afterburn:[],trained:[],organHealth:{},paused:false};
  let engine,scene,camera,config={muscles:{},segments:{},structures:{}};
  let glowLayer,afterburnLayer,tissueLayer;
  const atlasLights=[],studioLights=[];
  let contactShadow,studioBackdrop;
  const glowingMeshes=new Set(),afterburnMeshes=new Set(),tissueMeshes=new Set();
  let revision=0,appliedMode=null,selectedKey=null,disposed=false,defaultRadius=3.8,initialized=false;
  let bodyMinY=0,bodyHeight=1.8;
  const records=[],loads=new Map(),errors=[],selectionMaterials=new Map();
  const canvas=document.getElementById('renderCanvas'),status=document.getElementById('status');
  const files={main:'kaizen_anatomy_mobile.glb',skeleton:'kaizen_anatomy_skeleton.glb',organs:'kaizen_anatomy_organs.glb'};
  const send=payload=>{
    // PNG transitions travel only over the bridge, not into DOM diagnostics.
    document.body.dataset.lastEvent=JSON.stringify(payload.type==='transitionFrame'
      ?{type:payload.type,requestId:payload.requestId,hasFrame:Boolean(payload.dataUrl)}:payload);
    if(window.chrome?.webview)window.chrome.webview.postMessage(payload);
    else if(window.KaizenBridge?.postMessage)window.KaizenBridge.postMessage(JSON.stringify(payload));
    window.dispatchEvent(new CustomEvent('kaizen-anatomy-event',{detail:payload}));
  };
  const localized=(de,en)=>state.locale==='en'?en:de;
  const visibleTissues={muscles:new Set(['muscle','tendon','neutral']),skeleton:new Set(['bone','cartilage']),
    connective:new Set(['tendon','ligament']),organs:new Set(['organ','neutral'])};
  const pickableTissues={muscles:new Set(['muscle']),skeleton:new Set(['bone','cartilage']),
    connective:new Set(['tendon','ligament']),organs:new Set(['organ'])};
  function belongsToMode(r,mode=state.mode){
    if(!visibleTissues[mode].has(r.tissue))return false;
    if(mode==='muscles')return r.asset==='main'&&r.defaultVisible;
    if(mode==='skeleton'||mode==='connective')return r.asset==='skeleton';
    return r.asset==='organs'||(r.asset==='main'&&r.id==='neutral.body');
  }
  function extrasFor(mesh){
    for(let node=mesh;node;node=node.parent){
      const e=node.metadata?.gltf?.extras;
      if(e&&(e.tissue_type||e.muscle_id||e.structure_id||e.organ_id))return e;
    }
    return {};
  }
  function semantics(mesh,asset){
    const e=extrasFor(mesh),tissue=e.tissue_type||(asset==='organs'?'organ':mesh.name.startsWith('muscle.')?'muscle':'neutral');
    const id=tissue==='muscle'?(e.muscle_id||mesh.name.replace(/^muscle\./,'')):(e.structure_id||mesh.name);
    const detail=tissue==='muscle'?(config.muscles[id]||{}):(config.structures[id]||{});
    const segment=e.training_segment||detail.trainingSegment||null,segmentDetail=config.segments[segment]||{};
    return {mesh,asset,tissue,id,defaultVisible:e.default_visible!==false,frameBounds:e.studio_frame_bounds,
      nameDe:detail.nameDe||e.name_de||e.name_latin||mesh.name,nameEn:detail.nameEn||e.name_en||e.name_latin||mesh.name,
      latin:detail.latinName||e.name_latin||'',trainingSegment:segment,
      canonicalGroup:detail.canonicalGroup||segmentDetail.canonicalGroup||null,
      trainingGroups:Array.isArray(detail.trainingGroups)?detail.trainingGroups:[],
      trainingRelation:detail.trainingRelation||null,trainingLevel:0,trainingKind:null,afterburnActive:false,
      organId:detail.organId||e.organ_id||null,sourceName:mesh.name};
  }
  function setTheme(){
    const light=state.theme==='light';
    scene.clearColor=BABYLON.Color4.FromHexString(light?'#fafafaff':'#0a0a0aff');
    const studio=state.mode==='muscles';
    atlasLights.forEach(lamp=>lamp.setEnabled(!studio));
    studioLights.forEach(lamp=>lamp.setEnabled(studio));
    if(contactShadow){
      contactShadow.setEnabled(studio);
      contactShadow.material.setFloat('lightTheme',light?1:0);
    }
    if(studioBackdrop)studioBackdrop.isEnabled=studio&&light;
    document.body.style.background=light?'#fafafa':'#0a0a0a';status.style.color=light?'#414740':'#c7c6c1';
    document.documentElement.lang=state.locale;
    canvas.setAttribute('aria-label',localized('Drehbares anatomisches Körpermodell','Rotatable anatomical body model'));
  }
  function createLighting(){
    const fill=new BABYLON.HemisphericLight('soft fill',new BABYLON.Vector3(0,1,0),scene);
    fill.intensity=.75;fill.groundColor=new BABYLON.Color3(.22,.24,.25);
    const key=new BABYLON.DirectionalLight('key',new BABYLON.Vector3(-.6,-.8,-1),scene);key.intensity=1.65;
    const rim=new BABYLON.DirectionalLight('rim',new BABYLON.Vector3(.5,-.3,1),scene);rim.intensity=.85;
    atlasLights.push(fill,key,rim);

    const bounce=new BABYLON.HemisphericLight('Studio bounce',BABYLON.Axis.Y,scene);
    bounce.diffuse=new BABYLON.Color3(1,.97,.96);
    bounce.groundColor=new BABYLON.Color3(.44,.38,.40);bounce.intensity=.76;
    studioLights.push(bounce);
    // Camera-space placement keeps the broad key on the same cheek and shoulder
    // as the user turns the model to inspect the posterior muscles.
    for(const [name,direction,color,intensity] of [
      ['Studio softbox',[.32,-1.1,.65],[1,.97,.96],1.52],
      ['Studio rim',[-.35,-.84,-.80],[1,.94,.91],.76],
    ]){
      const lamp=new BABYLON.DirectionalLight(name,BABYLON.Vector3.FromArray(direction),scene);
      lamp.parent=camera;lamp.diffuse=BABYLON.Color3.FromArray(color);
      lamp.intensity=intensity;studioLights.push(lamp);
    }
    // The upper-body softbox has a physical falloff. Orbit it about the model,
    // independently of camera radius, so a pinch never changes the exposure.
    const softbox=new BABYLON.PointLight('Studio overhead',new BABYLON.Vector3(0,2.36,1),scene);
    softbox.diffuse=new BABYLON.Color3(1,.975,.97);softbox.intensity=1.72;
    studioLights.push(softbox);
    scene.onBeforeRenderObservable.add(()=>{
      if(!softbox.isEnabled())return;
      const a=camera.alpha-.29;
      softbox.position.x=Math.cos(a)*.99;softbox.position.z=Math.sin(a)*.99;
    });

    // A softly lit wall, fading into the card colour at the edge. Rendering
    // it in the scene also includes it in Flutter's transition frame.
    const width=32,height=64,wall=new Uint8Array(width*height*4);
    for(let row=0;row<height;row++){
      for(let col=0;col<width;col++){
        const x=col/(width-1),y=row/(height-1);
        const wash=Math.sin(Math.PI*x)*Math.sin(Math.PI*y);
        const cool=wash*Math.exp(-9*(x-.84)**2-4*(y-.64)**2);
        wall.set([250-4*wash-4*cool,250-4*wash,250-5*wash-4*cool,255],(row*width+col)*4);
      }
    }
    studioBackdrop=new BABYLON.Layer('Studio backdrop',null,scene,true);
    studioBackdrop.texture=BABYLON.RawTexture.CreateRGBATexture(wall,width,height,scene,false,false,
      BABYLON.Texture.BILINEAR_SAMPLINGMODE);

    // One transparent ground quad. The narrow footprints and broad falloff
    // rotate with the body and require no shadow map or post-processing pass.
    contactShadow=BABYLON.MeshBuilder.CreateGround('Studio contact shadow',{width:.94,height:.62},scene);
    contactShadow.position.set(0,-.004,.018);contactShadow.isPickable=false;
    const shader=new BABYLON.ShaderMaterial('Studio contact',scene,{
      vertexSource:`precision highp float;
        attribute vec3 position; attribute vec2 uv; uniform mat4 worldViewProjection; varying vec2 vUV;
        void main(){vUV=uv;gl_Position=worldViewProjection*vec4(position,1.0);}`,
      fragmentSource:`precision mediump float;
        varying vec2 vUV; uniform float lightTheme;
        void main(){
          vec2 p=vUV-.5;
          vec2 wide=p*vec2(4.7,4.8);
          vec2 foot=vec2(abs(p.x)-.105,p.y)*vec2(16.,7.);
          float density=.24*exp(-dot(wide,wide))+.27*exp(-dot(foot,foot));
          gl_FragColor=vec4(mix(vec3(0.),vec3(.34,.29,.29),lightTheme),density);
        }`
    },{attributes:['position','uv'],uniforms:['worldViewProjection','lightTheme'],needAlphaBlending:true});
    shader.disableDepthWrite=true;contactShadow.material=shader;
  }
  async function loadAsset(asset){
    if(loads.has(asset))return loads.get(asset);
    const promise=(async()=>{
      const url=new URL('../models/'+files[asset],location.href);
      const result=await BABYLON.SceneLoader.ImportMeshAsync('',url.href.slice(0,url.href.lastIndexOf('/')+1),files[asset],scene);
      for(const mesh of result.meshes){
        if(!mesh.getTotalVertices?.())continue;
        mesh.setEnabled(false);mesh.isPickable=false;
        const r=semantics(mesh,asset);
        if(mesh.material){
          // Separate materials prevent a selected or recovering group from recolouring another.
          mesh.material=mesh.material.clone('kaizen.'+asset+'.'+r.id);
          r.material=mesh.material;r.baseColor=mesh.material.albedoColor?.clone();
          r.baseEmissive=mesh.material.emissiveColor?.clone()||BABYLON.Color3.Black();
        }
        mesh.metadata={...mesh.metadata,kaizenRecord:r};records.push(r);
      }
      if(asset==='main')fitBody();
      return result;
    })();
    loads.set(asset,promise);
    try{return await promise;}catch(error){loads.delete(asset);throw error;}
  }
  function fitBody(){
    const body=records.filter(r=>r.asset==='main');if(!body.length)return;
    let min=new BABYLON.Vector3(Infinity,Infinity,Infinity),max=new BABYLON.Vector3(-Infinity,-Infinity,-Infinity);
    const frame=body.find(r=>r.frameBounds);
    if(frame){
      // All four layers share the original atlas frame, including after resize.
      const world=frame.mesh.computeWorldMatrix(true);
      const [a,b]=frame.frameBounds.map(p=>BABYLON.Vector3.TransformCoordinates(BABYLON.Vector3.FromArray(p),world));
      min=BABYLON.Vector3.Minimize(a,b);max=BABYLON.Vector3.Maximize(a,b);
    }else{
      for(const {mesh}of body){
        mesh.computeWorldMatrix(true);const b=mesh.getBoundingInfo().boundingBox;
        min=BABYLON.Vector3.Minimize(min,b.minimumWorld);max=BABYLON.Vector3.Maximize(max,b.maximumWorld);
      }
    }
    const size=max.subtract(min),span=Math.max(size.y,size.x/Math.max(engine.getAspectRatio(camera),.2));
    bodyMinY=min.y;bodyHeight=size.y;
    defaultRadius=span/(2*Math.tan(camera.fov/2))*1.10+size.z*.5;
    // setTarget rebuilds ArcRotateCamera's radius; distance must be set afterwards.
    camera.setTarget(min.add(max).scale(.5));camera.radius=defaultRadius;
    camera.lowerRadiusLimit=.32;camera.upperRadiusLimit=defaultRadius*2.5;
  }
  function clearSelection(notify=true){
    for(const[mesh,material]of selectionMaterials){
      if(mesh.material!==material)mesh.material?.dispose();mesh.material=material;
    }
    selectionMaterials.clear();selectedKey=null;document.body.dataset.selection='';syncGlow();
    if(notify)send({type:'cleared'});
  }
  function selectionColor(r){return albedoFromHex(r.tissue==='organ'?'#dcb576':'#3fd07a');}
  function selectionKey(r){
    if(r.tissue==='muscle')return'muscle:'+(r.trainingSegment||r.id);
    if(r.tissue==='organ')return'organ:'+(r.organId||r.id);
    return r.tissue+':'+r.id;
  }
  function selectRecord(r,notify=true){
    if(!state.expanded||!r.mesh.isEnabled()||!pickableTissues[state.mode].has(r.tissue))return false;
    const key=selectionKey(r);if(!state.musclePicker&&selectedKey===key){clearSelection();return true;}
    clearSelection(false);selectedKey=key;
    for(const candidate of records){
      if(state.musclePicker||!candidate.mesh.isEnabled()||selectionKey(candidate)!==key)continue;
      const mesh=candidate.mesh,original=mesh.material;if(!original)continue;
      selectionMaterials.set(mesh,original);const selected=original.clone('selected.'+candidate.id);
      if(selected.albedoColor)selected.albedoColor=selectionColor(candidate);
      if(selected.emissiveColor)selected.emissiveColor=selectionColor(candidate).scale(.14);
      mesh.material=selected;
    }
    const segment=config.segments[r.trainingSegment]||{};
    const payload={type:'selected',id:r.id,tissue:r.tissue,
      upperBody:r.mesh.getBoundingInfo().boundingBox.centerWorld.y>bodyMinY+bodyHeight*.52,
      name:state.locale==='en'?(segment.nameEn||r.nameEn):(segment.nameDe||r.nameDe),
      nameLatin:r.latin,trainingSegment:r.trainingSegment,canonicalGroup:r.canonicalGroup,organId:r.organId,
      training:{level:r.trainingLevel,kind:r.trainingKind,groups:r.trainingGroups,relation:r.trainingRelation}};
    syncGlow();document.body.dataset.selection=JSON.stringify(payload);if(notify)send(payload);updateDomSnapshot();return true;
  }
  // CSS/hex swatches are sRGB; glTF PBR albedo factors and saved baseColor are
  // linear. Blend in that same space so the output gamma is applied only once.
  function albedoFromHex(hex){return BABYLON.Color3.FromHexString(hex).toLinearSpace();}
  function createGlowLayer(){
    // One bounded blur target, shared by every highlight and kept across resize.
    glowLayer=new BABYLON.HighlightLayer('Kaizen training glow',scene,{
      mainTextureFixedSize:512,blurTextureSizeRatio:.5,
      blurHorizontalSize:1.4,blurVerticalSize:1.4,
      alphaBlendingMode:BABYLON.Engine.ALPHA_COMBINE,camera,
    });
    glowLayer.isEnabled=false;
  }
  function syncGlow(){
    if(!glowLayer)return;
    // Muscle load needs only a narrow outer halo. Keep the surface shading
    // intact instead of darkening its inside edge when dimming the glow.
    const muscleMode=state.mode==='muscles';
    glowLayer.innerGlow=false;
    glowLayer.outerGlow=true;
    glowLayer.blurHorizontalSize=glowLayer.blurVerticalSize=muscleMode?.5:1.4;
    const next=new Set(records.filter(r=>r.mesh.isEnabled()&&
      ((r.glowColor&&!r.afterburnActive&&r.trainingKind!=='involvement')||selectionMaterials.has(r.mesh))).map(r=>r.mesh));
    for(const mesh of glowingMeshes)if(!next.has(mesh)){glowLayer.removeMesh(mesh);glowingMeshes.delete(mesh);}
    for(const mesh of next){
      const selected=selectionMaterials.has(mesh),record=mesh.metadata.kaizenRecord;
      const color=selected?selectionColor(record):record.glowColor;
      // Muscle load is primarily a surface tint; keep its halo much quieter
      // than the independent blue afterburn contour and selection.
      const strength=selected?1:record.tissue==='muscle'?.12:.55;
      const halo=color.toGammaSpace().scale(strength);
      glowLayer.addMesh(mesh,halo);glowingMeshes.add(mesh);
    }
    glowLayer.isEnabled=next.size>0;
    syncAfterburn();
    syncTissueOutline();
  }
  function syncTissueOutline(){
    // Thin tendons and joint cartilage need the same resolved outer silhouette
    // as muscle afterburn. A 512px mask, subpixel blur and background-tinted RGB
    // made their previous halo disappear at phone sizes.
    const next=new Set(records.filter(r=>r.mesh.isEnabled()&&
      r.trainingKind==='involvement'&&!selectionMaterials.has(r.mesh)&&
      (state.mode==='connective'||state.mode==='skeleton')).map(r=>r.mesh));
    if(!tissueLayer&&next.size){
      tissueLayer=new BABYLON.HighlightLayer('Kaizen tissue outline',scene,{
        mainTextureFixedSize:768,blurTextureSizeRatio:.5,
        blurHorizontalSize:1.25,blurVerticalSize:1.25,
        alphaBlendingMode:BABYLON.Engine.ALPHA_COMBINE,camera,
      });
      tissueLayer.innerGlow=false;tissueLayer.outerGlow=true;
      // Joint cartilage sits inside the bones. Keep bones in the normal scene,
      // but out of this contour mask so they cannot erase the joint marker.
      for(const r of records)if(r.tissue==='bone')tissueLayer.addExcludedMesh(r.mesh);
    }
    if(!tissueLayer)return;
    for(const mesh of tissueMeshes)if(!next.has(mesh)){
      tissueLayer.removeMesh(mesh);tissueMeshes.delete(mesh);
    }
    for(const mesh of next){
      const cartilage=mesh.metadata.kaizenRecord.tissue==='cartilage';
      const color=BABYLON.Color3.FromHexString(cartilage?
        (state.theme==='light'?'#a97936':'#d7ad65'):
        (state.theme==='light'?'#398bc7':'#78bfff'));
      tissueLayer.addMesh(mesh,color);tissueMeshes.add(mesh);
    }
    tissueLayer.isEnabled=next.size>0;
  }
  function syncAfterburn(){
    // A shared outer silhouette joins the pieces of active muscle groups.
    // Keep the normal depth-tested scene in this pass so hidden muscles do not
    // shine through the body. Selection temporarily takes precedence.
    const next=new Set(records.filter(r=>state.mode==='muscles'&&r.mesh.isEnabled()&&
      r.afterburnActive&&!selectionMaterials.has(r.mesh)).map(r=>r.mesh));
    if(!afterburnLayer&&next.size){
      afterburnLayer=new BABYLON.HighlightLayer('Kaizen afterburn outline',scene,{
        mainTextureFixedSize:768,blurTextureSizeRatio:.5,
        blurHorizontalSize:3,blurVerticalSize:3,
        alphaBlendingMode:BABYLON.Engine.ALPHA_COMBINE,camera,
      });
      afterburnLayer.innerGlow=false;
      afterburnLayer.outerGlow=true;
    }
    if(!afterburnLayer)return;
    for(const mesh of afterburnMeshes)if(!next.has(mesh)){
      afterburnLayer.removeMesh(mesh);afterburnMeshes.delete(mesh);
    }
    const color=BABYLON.Color3.FromHexString(state.theme==='light'?'#0074c9':'#45cfff');
    for(const mesh of next){afterburnLayer.addMesh(mesh,color);afterburnMeshes.add(mesh);}
    afterburnLayer.isEnabled=next.size>0;
  }
  function applyMaterials(){
    const oldSelection=selectedKey;clearSelection(false);
    const recovery=state.recovery||{},policy=config.trainingHighlightPolicy||{};
    const afterburn=new Set(state.afterburn||[]);
    // Reuse the stored muscle-group heuristic; no tissue recovery is inferred.
    const levelFor=group=>recovery[group]==='recent'?2:
      (['almostReady','lightCircuit'].includes(recovery[group])?1:0);
    const level1=albedoFromHex(policy.muscleLevel1Color||'#d8b84e');
    const level2=albedoFromHex(policy.muscleLevel2Color||'#e51c05');
    const involvement=albedoFromHex(policy.involvementColor||'#d39a4b');
    const connectiveOutline=albedoFromHex(policy.connectiveOutlineColor||'#619bc6');
    for(const r of records){
      r.trainingLevel=0;r.trainingKind=null;r.glowColor=null;
      r.afterburnActive=r.tissue==='muscle'&&afterburn.has(r.canonicalGroup);
      r.nutritionStatus=null;
      const m=r.material;if(!m)continue;
      if(r.baseColor)m.albedoColor.copyFrom(r.baseColor);
      if(m.emissiveColor)m.emissiveColor.copyFrom(r.baseEmissive);
      m.alpha=1;m.disableDepthWrite=false;
      if(r.tissue==='neutral'&&state.mode==='organs'){
        m.alpha=.075;m.transparencyMode=BABYLON.PBRMaterial.PBRMATERIAL_ALPHABLEND;m.disableDepthWrite=true;
      }else if(m.transparencyMode!==undefined)m.transparencyMode=BABYLON.PBRMaterial.PBRMATERIAL_OPAQUE;
      if(r.tissue==='muscle'){
        r.trainingLevel=levelFor(r.canonicalGroup);r.trainingKind=r.trainingLevel?'muscle-load':null;
        if(r.trainingLevel){
          r.glowColor=r.trainingLevel===2?level2:level1;
          const blend=r.trainingLevel===2?(policy.muscleLevel2Blend??.97):(policy.muscleBlend??.68);
          if(r.baseColor)m.albedoColor=BABYLON.Color3.Lerp(r.baseColor,r.glowColor,blend);
          if(m.emissiveColor)m.emissiveColor=r.baseEmissive.add(r.glowColor.scale(r.trainingLevel===2 ? .026 : .018));
        }
        if(state.musclePicker&&(state.selectedSegments||[]).includes(r.trainingSegment)){
          r.glowColor=selectionColor(r);
          if(m.albedoColor)m.albedoColor.copyFrom(r.glowColor);
          if(m.emissiveColor)m.emissiveColor=r.baseEmissive.add(r.glowColor.scale(.14));
        }
      }else if(r.tissue==='organ'){
        // Reuse the app's existing food assessment only for supported organs.
        const aliases={'lung.l':'lungs','lung.r':'lungs','kidney.l':'kidneys','kidney.r':'kidneys',
          duodenum:'intestines',small_intestine:'intestines',large_intestine:'intestines',rectum:'intestines'};
        const status=state.organHealth?.[aliases[r.organId]||r.organId];
        const colors={good:'#78ad81',careful:'#ce6660',mixed:'#d3b567'};
        if(colors[status]){
          r.nutritionStatus=status;r.glowColor=albedoFromHex(colors[status]);
          if(r.baseColor)m.albedoColor=BABYLON.Color3.Lerp(r.baseColor,r.glowColor,.38);
          if(m.emissiveColor)m.emissiveColor=r.baseEmissive.add(r.glowColor.scale(.10));
        }
      }else if(['tendon','ligament','cartilage'].includes(r.tissue)&&r.trainingGroups.some(group=>levelFor(group)>0)){
        r.trainingLevel=1;r.trainingKind='involvement';
        // Preserve pink tendons, white ligaments and the cartilage surface.
        // Involvement uses an independent outer contour, never a glowing fill.
        r.glowColor=r.tissue==='cartilage'?involvement:connectiveOutline;
      }
    }
    if(oldSelection&&state.expanded&&!state.musclePicker){
      const selected=records.find(r=>selectionKey(r)===oldSelection&&r.mesh.isEnabled()&&pickableTissues[state.mode].has(r.tissue));
      if(selected)selectRecord(selected,false);
    }
    syncGlow();
  }
  function snapshot(){
    const visible=records.filter(r=>r.mesh.isEnabled());
    return{mode:state.mode,expanded:state.expanded,ready:initialized&&appliedMode===state.mode,
      loadedAssets:[...loads.keys()],meshes:records.length,visibleMeshes:visible.length,
      triangles:visible.reduce((n,r)=>n+r.mesh.getTotalIndices()/3,0),
      pickable:visible.filter(r=>r.mesh.isPickable).map(r=>({id:r.id,tissue:r.tissue,segment:r.trainingSegment})),
      selectedKey,selectionMaterials:selectionMaterials.size,errors:[...errors],
      glow:{enabled:glowLayer?.isEnabled||false,meshes:glowingMeshes.size},
      afterburn:{enabled:afterburnLayer?.isEnabled||false,meshes:afterburnMeshes.size},
      tissueOutline:{enabled:tissueLayer?.isEnabled||false,meshes:tissueMeshes.size},
      afterburnHighlights:visible.filter(r=>state.mode==='muscles'&&r.afterburnActive)
        .map(r=>({id:r.id,group:r.canonicalGroup})),
      trainingHighlights:visible.filter(r=>r.trainingLevel>0).map(r=>({id:r.id,tissue:r.tissue,level:r.trainingLevel,kind:r.trainingKind})),
      nutritionHighlights:visible.filter(r=>r.nutritionStatus).map(r=>({id:r.id,organId:r.organId,status:r.nutritionStatus})),
      camera:{alpha:camera?.alpha,beta:camera?.beta,radius:camera?.radius},fps:engine?.getFps()||0};
  }
  function updateDomSnapshot(){
    if(!scene||disposed)return;const s=snapshot();
    document.body.dataset.qa=JSON.stringify(s);document.body.dataset.mode=state.mode;document.body.dataset.ready=String(s.ready);
  }
  async function applyState(){
    if(!initialized||disposed)return;
    const token=++revision,mode=state.mode;
    status.textContent=localized('Modell wird geladen …','Loading model …');
    try{
      await loadAsset('main');
      if(mode==='skeleton'||mode==='connective')await loadAsset('skeleton');
      if(mode==='organs')await loadAsset('organs');
      if(token!==revision||disposed)return;
      const modeChanged=appliedMode!==mode;
      if(modeChanged)clearSelection(false);
      for(const r of records){
        const show=belongsToMode(r);r.mesh.setEnabled(show);
        r.mesh.isPickable=show&&state.expanded&&pickableTissues[mode].has(r.tissue);
      }
      setTheme();applyMaterials();if(!state.expanded)clearSelection(false);
      if(state.expanded)camera.attachControl(canvas,true);else camera.detachControl();
      appliedMode=mode;status.textContent='';
      if(state.paused)scene.render();
      updateDomSnapshot();const s=snapshot();
      if(modeChanged)send({type:'loaded',mode,meshes:s.visibleMeshes,triangles:s.triangles,radius:camera.radius,minZ:camera.minZ});
    }catch(error){
      if(token!==revision||disposed)return;errors.push(String(error));
      status.textContent=localized('Die 3D-Ansicht konnte nicht geladen werden.','The 3D view could not be loaded.');
      send({type:'error',mode,message:String(error)});updateDomSnapshot();
    }
  }
  function setState(patch={}){
    const next={...state,...patch};if(!modes.has(next.mode))next.mode=state.mode;
    next.expanded=Boolean(next.expanded);next.locale=next.locale==='en'?'en':'de';next.theme=next.theme==='light'?'light':'dark';
    state=next;return applyState();
  }
  function setView(view){
    if(!camera)return;
    const angles={front:Math.PI/2,front45:Math.PI/4,side:0,back45:-Math.PI/4,back:-Math.PI/2};
    if(!(view in angles))return;
    camera.alpha=angles[view];camera.beta=Math.PI/2;
    camera.inertialAlphaOffset=camera.inertialBetaOffset=camera.inertialRadiusOffset=0;updateDomSnapshot();
  }
  function toggleFrontBack(){
    if(!camera)return;
    const view=Math.sin(camera.alpha)>=0?'back':'front';
    setView(view);return view;
  }
  function configureHorizontalOrbit(){
    camera.beta=camera.lowerBetaLimit=camera.upperBetaLimit=Math.PI/2;
    camera.wheelDeltaPercentage=.025;camera.pinchDeltaPercentage=.012;camera.panningSensibility=0;
    camera.inputs.attached.pointers.buttons=[0];
    camera.onAfterCheckInputsObservable.add(()=>{
      camera.beta=Math.PI/2;camera.inertialBetaOffset=0;
    });
  }
  function captureFrame(requestId){
    let dataUrl=null;
    try{
      if(!disposed&&initialized&&appliedMode===state.mode){
        state.paused=true;
        camera.inertialAlphaOffset=camera.inertialBetaOffset=camera.inertialRadiusOffset=0;
        camera.inertialPanningX=camera.inertialPanningY=0;
        scene.render();dataUrl=canvas.toDataURL('image/png');
      }
    }catch(_){dataUrl=null;}
    send({type:'transitionFrame',requestId,dataUrl});return Boolean(dataUrl);
  }
  function resizeViewport(){
    if(disposed||!camera)return;
    const zoom=camera.radius/defaultRadius,alpha=camera.alpha;
    engine.resize();fitBody();camera.alpha=alpha;camera.beta=Math.PI/2;
    camera.radius=defaultRadius*(state.expanded?zoom:1);
    if(state.paused)scene.render();
    updateDomSnapshot();
  }
  window.kaizenAnatomy={setState,clearSelection,setView,toggleFrontBack,captureFrame,resetView:()=>{fitBody();setView('front');},snapshot,
    select:id=>{const r=records.find(r=>r.id===id&&r.mesh.isEnabled());return r?selectRecord(r):false;},
    dispose:()=>{disposed=true;clearSelection(false);scene?.dispose();engine?.dispose();}};
  window.setViewerExpanded=value=>setState({expanded:Boolean(value)});
  async function start(){
    engine=new BABYLON.Engine(canvas,true,{preserveDrawingBuffer:false,stencil:true,powerPreference:'high-performance'},false);
    engine.setHardwareScalingLevel(1/Math.min(window.devicePixelRatio||1,1.5));
    scene=new BABYLON.Scene(engine);
    camera=new BABYLON.ArcRotateCamera('Kaizen camera',Math.PI/2,Math.PI/2,3.8,new BABYLON.Vector3(0,.9,0),scene);
    camera.fov=.64;camera.minZ=.005;camera.maxZ=50;
    configureHorizontalOrbit();
    createGlowLayer();
    createLighting();
    scene.onPointerObservable.add(info=>{
      if(!state.expanded||info.type!==BABYLON.PointerEventTypes.POINTERTAP)return;
      const r=info.pickInfo?.pickedMesh?.metadata?.kaizenRecord;
      if(info.pickInfo?.hit&&r)selectRecord(r);else clearSelection();
    });
    const response=await fetch(new URL('./anatomy_config.json',location.href));
    if(!response.ok)throw new Error('Anatomy catalog '+response.status);
    config=await response.json();let lastQaUpdate=0;
    engine.runRenderLoop(()=>{
      if(disposed||document.hidden||state.paused)return;
      if(!state.expanded)camera.alpha+=Math.min(engine.getDeltaTime(),60)*.00018;
      scene.render();const now=performance.now();
      if(now-lastQaUpdate>1000){lastQaUpdate=now;updateDomSnapshot();}
    });
    window.addEventListener('resize',resizeViewport);
    initialized=true;await applyState();
  }
  start().catch(error=>{
    errors.push(String(error));status.textContent=localized('Die 3D-Ansicht konnte nicht starten.','The 3D view could not start.');
    send({type:'error',message:String(error)});
  });
})();

