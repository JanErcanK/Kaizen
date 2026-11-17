// Dependency-free integration checks against a LOCAL Firestore emulator only.
// Start it with --project_id demo-kaizen --port 8185 --rules firestore.rules.
import assert from 'node:assert/strict';
const origin = 'http://127.0.0.1:8185';
const project = 'demo-kaizen';
const base = `${origin}/v1/projects/${project}/databases/(default)/documents`;
const name = path => `projects/${project}/databases/(default)/documents/${path}`;
const encode = x => Buffer.from(JSON.stringify(x)).toString('base64url');
function token(uid) {
  const now = Math.floor(Date.now() / 1000);
  return `${encode({alg:'none',typ:'JWT'})}.${encode({sub:uid,user_id:uid,
    aud:project,iss:`https://securetoken.google.com/${project}`,iat:now,exp:now+3600,
    firebase:{sign_in_provider:'anonymous',identities:{}}})}.`;
}
function value(x) {
  if (x === null) return {nullValue:null};
  if (x instanceof Date) return {timestampValue:x.toISOString()};
  if (typeof x === 'string') return {stringValue:x};
  if (typeof x === 'boolean') return {booleanValue:x};
  if (typeof x === 'number') return Number.isInteger(x) ? {integerValue:String(x)} : {doubleValue:x};
  if (Array.isArray(x)) return {arrayValue:{values:x.map(value)}};
  return {mapValue:{fields:fields(x)}};
}
const fields = obj => Object.fromEntries(Object.entries(obj).map(([k,v]) => [k,value(v)]));
async function call(uid, method, path, body, expected = 200) {
  const response = await fetch(`${base}${path.startsWith(':') ? '' : '/'}${path}`, {
    method, headers:{'Content-Type':'application/json',
      ...(uid ? {Authorization:`Bearer ${uid === 'owner' ? uid : token(uid)}`} : {})},
    ...(body ? {body:JSON.stringify(body)} : {}), signal:AbortSignal.timeout(15000),
  });
  const text = await response.text();
  assert.equal(response.status, expected, `${uid} ${method} ${path}: ${text.slice(0,1100)}`);
  return text ? JSON.parse(text) : {};
}
const put = (uid,path,data,status=200) => call(uid,'PATCH',path,{fields:fields(data)},status);
const get = (uid,path,status=200) => call(uid,'GET',path,null,status);
const commit = (uid,writes,status=200) => call(uid,'POST',':commit',{writes},status);
const update = (path,data) => ({update:{name:name(path),fields:fields(data)}});
let passed = 0;
async function check(label, task) { await task(); passed++; console.log(`PASS ${label}`); }

// Reset only the disposable demo database on localhost, never a remote project.
const reset = await fetch(`${origin}/emulator/v1/projects/${project}/databases/(default)/documents`,{method:'DELETE'});
assert.equal(reset.status,200);
const now = new Date();
const profiles = {alice:{displayName:'Alice',friendCode:'KZN-AAAAAA'},
  bob:{displayName:'Bob',friendCode:'KZN-BBBBBB'},eve:{displayName:'Eve',friendCode:'KZN-EEEEEE'}};
for (const [uid,data] of Object.entries(profiles)) await put(uid,`users/${uid}`,data);
const presence = {routeId:'run-1',routeName:'Park loop',displayName:'Alice',latitude:52.52,
  longitude:13.405,distanceMeters:50,currentPaceSecPerKm:300,avgPaceSecPerKm:320,
  recordedPoints:[],plannedPoints:[],startedAt:now,updatedAt:now,paused:false,positionUpdatedAt:now};
const edge = (peer,acceptedBy='bob') => ({...profiles[peer],notifyOnRunStart:true,connectedAt:now,consentVersion:1,acceptedBy});
const pair = [update('users/alice/friends/bob',edge('bob')),update('users/bob/friends/alice',edge('alice'))];
const request = sender => ({fromUid:sender,...profiles[sender],createdAt:now});
const share = (type='foodDish') => ({id:'share-1',fromUid:'alice',fromName:'Alice',type,
  status:'pending',createdAt:now,payload:type==='foodDish' ? {name:'Lunch',items:[{foodName:'Eggs',grams:200,proteinG:25,carbsG:2,fatsG:20}]}
    : {name:'My workout',exercises:[{name:'Squat',setReps:[8,7,6],weight:60}]}});

await check('owner may publish valid live run',()=>put('alice','users/alice/presence/activeRun',presence));
await check('stranger and unauthenticated user cannot read location',async()=>{
  await get('eve','users/alice/presence/activeRun',403); await get(null,'users/alice/presence/activeRun',403);
});
await check('stranger cannot enumerate profiles, codes or friends',async()=>{
  await get('eve','users',403);await get('eve','friendCodes',403);await get('eve','users/alice/friends',403);
});
await check('profile/code ownership cannot be overwritten',async()=>{
  await put('alice','friendCodes/KZN-AAAAAA',{uid:'alice'});
  await put('eve','friendCodes/KZN-AAAAAA',{uid:'eve'},403);
  await put('eve','users/alice',profiles.eve,403);
});
await check('forged reciprocal friendship is denied atomically',()=>commit('eve',pair,403));
await check('legacy reciprocal edges grant no location access',async()=>{
  for (const [owner,peer] of [['alice','bob'],['bob','alice']]) {
    const {consentVersion,acceptedBy,...legacy}=edge(peer);
    await put('owner',`users/${owner}/friends/${peer}`,legacy);
  }
  await get('bob','users/alice/presence/activeRun',403);
  await call('owner','DELETE','users/alice/friends/bob');await call('owner','DELETE','users/bob/friends/alice');
});
await check('sender can request but cannot accept their own outgoing request',async()=>{
  await put('alice','users/bob/friendRequests/alice',request('alice'));
  await commit('alice',pair.map(w=>({...w,update:{...w.update,fields:{...w.update.fields,acceptedBy:value('alice')}}})),403);
  await get('bob','users/alice/presence/activeRun',403);
});
await check('request identity spoof and unapproved share are denied',async()=>{
  await put('eve','users/bob/friendRequests/alice',request('alice'),403);
  await put('alice','users/bob/inbox/share-1',share(),403);
});
await check('recipient cannot create only one half of the friendship',()=>put('bob','users/bob/friends/alice',edge('alice'),403));
await check('recipient can accept reciprocal edges and consume request atomically',async()=>{
  await commit('bob',[...pair,{delete:name('users/bob/friendRequests/alice')}]);
  await get('bob','users/bob/friendRequests/alice',404);
  await get('bob','users/alice/presence/activeRun');
});
await check('friend can read run but cannot change it or enumerate presence',async()=>{
  await put('bob','users/alice/presence/activeRun',presence,403);
  await get('bob','users/alice/presence',403);
});
await check('notify-only update preserves accepted friendship',async()=>{
  await call('alice','PATCH','users/alice/friends/bob?updateMask.fieldPaths=notifyOnRunStart',{fields:fields({notifyOnRunStart:false})});
  await get('bob','users/alice/presence/activeRun');
  await call('alice','PATCH','users/alice/friends/bob?updateMask.fieldPaths=acceptedBy',{fields:fields({acceptedBy:'eve'})},403);
});
await check('accepted friends can share dishes and both workout types',async()=>{
  for (const type of ['foodDish','gymWorkout','calisthenicsWorkout']) {
    const msg={...share(type),id:type}; await put('alice',`users/bob/inbox/${type}`,msg);
  }
  await put('alice','users/bob/inbox/share-1',share());
});
await check('spoofed sender, unrelated sender and oversized item list are rejected',async()=>{
  await put('alice','users/bob/inbox/spoof',{...share(),id:'spoof',fromUid:'eve'},403);
  await put('eve','users/bob/inbox/eve',{...share(),id:'eve',fromUid:'eve',fromName:'Eve'},403);
  await put('alice','users/bob/inbox/large',{...share(),id:'large',payload:{name:'Large',items:Array(101).fill({})}},403);
});
await check('recipient acknowledgement preserves full payload and is repeatable',async()=>{
  for(let i=0;i<2;i++) await call('bob','PATCH','users/bob/inbox/share-1?updateMask.fieldPaths=status',{fields:fields({status:'accepted'})});
  const doc=await get('bob','users/bob/inbox/share-1');
  assert.equal(doc.fields.payload.mapValue.fields.name.stringValue,'Lunch');
  await put('bob','users/bob/inbox/share-1',{...share(),status:'accepted',fromUid:'eve'},403);
});
await check('invalid coordinates, oversized paths and extra authority fields are rejected',async()=>{
  await put('alice','users/alice/presence/activeRun',{...presence,latitude:91},403);
  await put('alice','users/alice/presence/activeRun',{...presence,recordedPoints:Array(401).fill({lat:0,lon:0})},403);
  await put('alice','users/alice/presence/activeRun',{...presence,isAdmin:true},403);
});
await check('paused updates preserve start time; owner stop removes presence',async()=>{
  await call('alice','PATCH','users/alice/presence/activeRun?updateMask.fieldPaths=paused',{fields:fields({paused:true})});
  const doc=await get('bob','users/alice/presence/activeRun'); assert.ok(doc.fields.startedAt.timestampValue);
  await call('alice','DELETE','users/alice/presence/activeRun');await get('bob','users/alice/presence/activeRun',403);
});
await check('stale locations are denied by rules even with an accepted friendship',async()=>{
  const old=new Date(Date.now()-180000);
  await put('alice','users/alice/presence/activeRun',{...presence,startedAt:old,updatedAt:old});
  await get('bob','users/alice/presence/activeRun',403);
  await get('alice','users/alice/presence/activeRun');
});
const activity = {type:'cycling', durationSeconds:1800, descentMeters:80,
  maxSpeedKmh:32.5, calories:300, elevationRecorded:true, recordedAt:now.toISOString()};
const community = {ownerUid:'alice',displayName:'Alice',routeName:'Park loop',
  distanceMeters:8000,ascentMeters:95,points:[{lat:52.5,lon:13.4},{lat:52.6,lon:13.5}],createdAt:now,activity};
await check('community activity metadata and descending collection query are allowed',async()=>{
  await put('alice','communityRuns/ride',community);
  await get('eve','communityRuns?orderBy=createdAt%20desc&pageSize=30');
  await get(null,'communityRuns/ride',403);
  await get(null,'communityRuns',403);
});
await check('community owner, time and metadata cannot be forged',async()=>{
  await put('eve','communityRuns/ride',community,403);
  await put('eve','communityRuns/forged',community,403);
  await put('alice','communityRuns/ride',{...community,ownerUid:'eve'},403);
  await put('alice','communityRuns/ride',{...community,createdAt:new Date(0)},403);
  await call('eve','DELETE','communityRuns/ride',null,403);
});
await check('activity validation runs on both create and update',async()=>{
  for(const bad of [
    {...activity,type:'admin'}, {...activity,durationSeconds:-1},
    {...activity,maxSpeedKmh:501}, {...activity,elevationRecorded:'true'},
    {...activity,recordedAt:'x'.repeat(41)}, {...activity,extra:true},
    {...activity,calories:100001}, {...activity,descentMeters:-1},
    {type:'walking'},
  ]) {
    await put('alice','communityRuns/invalid',{...community,activity:bad},403);
    await put('alice','communityRuns/ride',{...community,activity:bad},403);
  }
  await put('alice','communityRuns/ride',{...community,activity:{...activity,type:'hiking'}});
  const {activity:_,...legacy}=community;
  await put('alice','communityRuns/legacy',legacy);
});
await check('friends receive route metrics and activity while strangers cannot',async()=>{
  const msg={...share(),id:'route-activity',type:'runningRoute',payload:{name:'Ride',points:community.points,activity}};
  await put('alice','users/bob/inbox/route-activity',msg);
  await get('bob','users/bob/inbox/route-activity');
  await get('eve','users/bob/inbox/route-activity',403);
  await put('alice','users/bob/inbox/bad-route',{...msg,id:'bad-route',payload:{...msg.payload,activity:{...activity,type:'bad'}}},403);
  await call('alice','DELETE','communityRuns/ride');
});
await check('removing friendship immediately revokes location and sending',async()=>{
  await put('alice','users/alice/presence/activeRun',presence);
  await commit('bob',[{delete:name('users/alice/friends/bob')},{delete:name('users/bob/friends/alice')}]);
  await get('bob','users/alice/presence/activeRun',403);
  await put('alice','users/bob/inbox/after',{...share(),id:'after'},403);
});
console.log(`${passed} Firestore rules integration checks passed (localhost only).`);
