// Downloads a pinned official emulator, verifies it, tests localhost, then exits.
// Requirements: Node 22+ and Java 21+ on PATH (or JAVA_HOME).
import {spawn} from 'node:child_process';
import {createHash} from 'node:crypto';
import {createReadStream, createWriteStream} from 'node:fs';
import {mkdir, stat} from 'node:fs/promises';
import {pipeline} from 'node:stream/promises';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
const root = fileURLToPath(new URL('../',import.meta.url));
const dir = path.join(root,'build','social-emulator');
const jar = path.join(dir,'firestore.jar');
const sha = '9b6498b7f62714d67f48f59b3818883cd682dbcd46b9f59511de81c97bb5166c';
await mkdir(dir,{recursive:true});
if (!await stat(jar).catch(()=>null)) {
  const response=await fetch('https://storage.googleapis.com/firebase-preview-drop/emulator/cloud-firestore-emulator-v1.22.0.jar');
  if (!response.ok) throw new Error(`Emulator download: ${response.status}`);
  await pipeline(response.body,createWriteStream(jar));
}
const hash=createHash('sha256');
for await(const chunk of createReadStream(jar)) hash.update(chunk);
if (hash.digest('hex') !== sha) throw new Error('Emulator checksum mismatch; remove the incomplete build/social-emulator/firestore.jar and retry.');
// Never attach to an already running service and risk clearing its demo data.
const origin='http://127.0.0.1:8185';
const occupied=await fetch(origin,{signal:AbortSignal.timeout(500)}).then(()=>true,()=>false);
if (occupied) throw new Error('Port 8185 is already in use. Stop that emulator before running this isolated suite.');
const java=process.env.JAVA_HOME ? path.join(process.env.JAVA_HOME,'bin',process.platform==='win32'?'java.exe':'java') : 'java';
const emulator=spawn(java,['-jar',jar,'--host','127.0.0.1','--port','8185','--rules',path.join(root,'firestore.rules'),'--project_id','demo-kaizen'],{cwd:root,windowsHide:true,stdio:['ignore','pipe','pipe']});
const log=createWriteStream(path.join(dir,'server.log'));
emulator.stdout.pipe(log);emulator.stderr.pipe(log);
let startupError;
emulator.on('error',error=>startupError=error);
try {
  let ready=false;
  for(let i=0;i<60;i++) {
    if (startupError) throw startupError;
    if (emulator.exitCode !== null) throw new Error('Emulator exited; inspect build/social-emulator/server.log');
    ready=await fetch(origin,{signal:AbortSignal.timeout(500)}).then(()=>true,()=>false);
    if(ready) break;
    await new Promise(resolve=>setTimeout(resolve,500));
  }
  if(!ready) throw new Error('Emulator did not start within 30 seconds');
  const result=await new Promise((resolve,reject)=>{
    const test=spawn(process.execPath,[path.join(root,'tool','test_firestore_rules.mjs')],{cwd:root,windowsHide:true,stdio:'inherit'});
    test.once('error',reject);test.once('exit',code=>resolve(code ?? 1));
  });
  process.exitCode=result;
} finally {
  emulator.kill();
}
