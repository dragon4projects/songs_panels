import {writeFileSync} from 'node:fs';
function buildMug(color,name) {
 const TAU=2*Math.PI,N=64;
 const positions=[],normals=[],groups=[[],[],[],[]];
 const profile=[[.0001,0],[.028,0],[.032,.0015],[.035,.004],[.038,.009],[.041,.023],[.044,.044],[.047,.071],[.0488,.095],[.049,.1025],[.0485,.1045],[.0465,.105],[.0445,.104],[.0438,.1015],[.0436,.094],[.0418,.072],[.039,.044],[.036,.022],[.032,.011],[.027,.009],[.0001,.009]];
 function vertex(p,n){const i=positions.length/3;positions.push(...p);normals.push(...n);return i;}
 function norm(v){const l=Math.hypot(...v)||1;return v.map(x=>x/l);}
 for(let i=0;i<profile.length;i++){
   const [r,y]=profile[i],p=profile[Math.max(0,i-1)],q=profile[Math.min(profile.length-1,i+1)];
   const [nr,ny]=norm([q[1]-p[1],-(q[0]-p[0])]);
   for(let j=0;j<N;j++){const t=TAU*j/N,c=Math.cos(t),s=Math.sin(t);vertex([r*c,y,r*s],[nr*c,ny,nr*s]);}
 }
 for(let i=0;i<profile.length-1;i++)for(let j=0;j<N;j++){
  const a=i*N+j,b=i*N+(j+1)%N,c=(i+1)*N+j,d=(i+1)*N+(j+1)%N;
  const g=i>=12?1:0;groups[g].push(a,c,b,b,c,d);
 }
 // close the tiny center rings with exact planar cap triangles.
 let k=vertex([0,0,0],[0,-1,0]);for(let j=0;j<N;j++)groups[0].push(k,j,(j+1)%N);
 k=vertex([0,.009,0],[0,1,0]);const last=(profile.length-1)*N;
 for(let j=0;j<N;j++)groups[1].push(k,last+(j+1)%N,last+j);
 // handle: oval swept tube, vertically rounded black ceramic, embedded ends.
 const H=36,S=12,hs=positions.length/3;
 for(let i=0;i<=H;i++){
  const t=-1.99+3.98*i/H,x=.052+.0315*Math.cos(t),y=.053+.0335*Math.sin(t);
  const [nx,ny]=norm([.0335*Math.cos(t),.0315*Math.sin(t)]);
  const a=.0055,b=.0063;
  for(let j=0;j<S;j++){
   const u=TAU*j/S,cu=Math.cos(u),su=Math.sin(u);
   vertex([x+a*cu*nx,y+a*cu*ny,b*su],norm([cu*nx/a,cu*ny/a,su/b]));
  }
 }
 for(let i=0;i<H;i++)for(let j=0;j<S;j++){
  const a=hs+i*S+j,b=hs+i*S+(j+1)%S,c=hs+(i+1)*S+j,d=hs+(i+1)*S+(j+1)%S;
  groups[2].push(a,c,b,b,c,d);
 }
 for(const i of [0,H]){
  const t=-1.99+3.98*i/H,x=.052+.0315*Math.cos(t),y=.053+.0335*Math.sin(t);
  const nn=norm([-.0315*Math.sin(t),.0335*Math.cos(t),0]).map(v=>v*(i===0?-1:1));
  const center=vertex([x,y,0],nn);
  for(let j=0;j<S;j++){const a=hs+i*S+j,b=hs+i*S+(j+1)%S;groups[2].push(...(i===0?[center,b,a]:[center,a,b]));}
 }
 // Project a drawn wraparound four-stripe capsule and separate four rings onto the curved wall.
 function radius(y){for(let i=3;i<10;i++){const a=profile[i],b=profile[i+1];if(y>=a[1]&&y<=b[1])return a[0]+(b[0]-a[0])*(y-a[1])/(b[1]-a[1]);}return .045;}
 function surface(u,y){const t=u/.044,r=radius(y)+.00012;return vertex([r*Math.cos(t),y,r*Math.sin(t)],norm([Math.cos(t),-.10,Math.sin(t)]));}
 function strip(points,w=.00062){
  const start=positions.length/3,L=points.length;
  for(let i=0;i<L;i++){
   const p=points[i],a=points[(i+L-1)%L],b=points[(i+1)%L],du=b[0]-a[0],dy=b[1]-a[1],l=Math.hypot(du,dy);
   const n=[-dy/l,du/l];surface(p[0]+n[0]*w/2,p[1]+n[1]*w/2);surface(p[0]-n[0]*w/2,p[1]-n[1]*w/2);
  }
  for(let i=0;i<L;i++){const a=start+2*i,b=a+1,c=start+2*((i+1)%L),d=c+1;groups[3].push(a,b,c,b,d,c);}
 }
 for(let i=0;i<4;i++){
  const r=.0128+i*.00165,cy=.055,left=.096,right=.219,points=[];
  for(let j=0;j<=24;j++){const a=Math.PI/2+Math.PI*j/24;points.push([left+r*Math.cos(a),cy+r*Math.sin(a)]);}
  for(let j=1;j<=64;j++)points.push([left+(right-left)*j/64,cy-r]);
  for(let j=1;j<=24;j++){const a=-Math.PI/2+Math.PI*j/24;points.push([right+r*Math.cos(a),cy+r*Math.sin(a)]);}
  for(let j=1;j<64;j++)points.push([right-(right-left)*j/64,cy+r]);
  strip(points);
  const cp=[];for(let j=0;j<64;j++){const a=TAU*j/64;cp.push([.043+r*Math.cos(a),cy+r*Math.sin(a)]);}strip(cp);
 }
 const mats=[
  {name:"Matte black ceramic",pbrMetallicRoughness:{baseColorFactor:[.018,.017,.016,1],metallicFactor:0,roughnessFactor:.77}},
  {name:"Glossy colored glaze",pbrMetallicRoughness:{baseColorFactor:[...color,1],metallicFactor:0,roughnessFactor:.19}},
  {name:"Black ceramic handle",pbrMetallicRoughness:{baseColorFactor:[.018,.017,.016,1],metallicFactor:0,roughnessFactor:.58}},
  {name:"Four-line retro graphic",doubleSided:true,pbrMetallicRoughness:{baseColorFactor:[...color,1],metallicFactor:0,roughnessFactor:.58}}
 ];
 const chunks=[],views=[],acc=[];let offset=0;
 function add(values,kind,target,minmax=false){
  const arr=kind===5126?new Float32Array(values):new Uint16Array(values),bytes=new Uint8Array(arr.buffer),pad=(4-bytes.length%4)%4;
  const vi=views.length;views.push({buffer:0,byteOffset:offset,byteLength:bytes.length,target});chunks.push(bytes,new Uint8Array(pad));offset+=bytes.length+pad;
  const a={bufferView:vi,componentType:kind,count:kind===5126?values.length/3:values.length,type:kind===5126?"VEC3":"SCALAR"};
  if(minmax){a.min=[0,1,2].map(k=>Math.min(...values.filter((_,i)=>i%3===k)));a.max=[0,1,2].map(k=>Math.max(...values.filter((_,i)=>i%3===k)));}
  acc.push(a);return acc.length-1;
 }
 const pa=add(positions,5126,34962,true),na=add(normals,5126,34962);
 const prim=groups.map((g,i)=>({attributes:{POSITION:pa,NORMAL:na},indices:add(g,5123,34963),material:i,mode:4}));
 const doc={asset:{version:"2.0",generator:"Dragon House procedural mug candidate 1"},scene:0,scenes:[{nodes:[0]}],nodes:[{name,mesh:0,children:[1,2,3]},{name:"PLACEMENT_ANCHOR"},{name:"PICKUP_ANCHOR",translation:[.078,.053,0]},{name:"RIM_CENTER",translation:[0,.105,0]}],meshes:[{name,primitives:prim}],materials:mats,accessors:acc,bufferViews:views,buffers:[{byteLength:offset}]};
 // glTF JSON uses ASCII only.
 const json=JSON.stringify(doc),jl=(json.length+3)&~3,buf=new Uint8Array(12+8+jl+8+offset),dv=new DataView(buf.buffer);
 dv.setUint32(0,0x46546c67,true);dv.setUint32(4,2,true);dv.setUint32(8,buf.length,true);dv.setUint32(12,jl,true);dv.setUint32(16,0x4e4f534a,true);
 buf.fill(32,20,20+jl);for(let i=0;i<json.length;i++)buf[20+i]=json.charCodeAt(i);
 dv.setUint32(20+jl,offset,true);dv.setUint32(24+jl,0x004e4942,true);let p=28+jl;for(const a of chunks){buf.set(a,p);p+=a.length;}
 if(p!==buf.length||positions.length/3>=65536||groups.some(g=>g.some(i=>i>=positions.length/3)))throw Error("bad geometry");
 return {buf,vertices:positions.length/3,triangles:groups.reduce((a,g)=>a+g.length/3,0),bounds:acc[0],binOffset:28+jl};
}
for(const [color,name,file] of [[[.68,.012,.008],"DRAGON_MUG_RED","dragon_mug_red.glb"],[[.008,.19,.72],"GUEST_MUG_BLUE","guest_mug_blue.glb"]])writeFileSync(file,buildMug(color,name).buf);
