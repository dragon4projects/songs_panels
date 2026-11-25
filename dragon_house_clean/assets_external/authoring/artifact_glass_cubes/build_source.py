import bpy, math, json
from pathlib import Path
from mathutils import Vector
ROOT=Path('/home/user/artifact_glass_cubes_20261125')
D=ROOT/'drop/dragon_house_clean'
BANK=D/'assets/decor_bank'
SRC=D/'assets_external/authoring/artifact_glass_cubes'
SRC.mkdir(parents=True,exist_ok=True)
specs=[('s',.20,.020,.003,.0035),('m',.35,.030,.004,.005),('l',.50,.040,.005,.007)]
def setup():
 bpy.ops.wm.read_factory_settings(use_empty=True)
 bpy.context.scene.unit_settings.system='METRIC'
 bpy.context.scene.unit_settings.scale_length=1.0
def mat(name,color,metal=0,rough=.3,trans=0):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough;p.inputs['Transmission Weight'].default_value=trans;p.inputs['IOR'].default_value=1.45
 return m
def box(name,loc,size,material,bevel=0):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 o.data.materials.append(material)
 if bevel:
  md=o.modifiers.new('Fine edge chamfer','BEVEL');md.width=bevel;md.segments=1
  bpy.ops.object.modifier_apply(modifier=md.name)
 return o
def build(id,w,b,t,f,x=0):
 metal=mat(id+'_dark_bronze',(.12,.08,.045),.78,.28)
 base=mat(id+'_charcoal_base',(.032,.027,.023),.12,.43)
 glass=mat(id+'_clear_glass',(.96,.99,1.),0,.07,1)
 objs=[]
 def add(n,loc,size,m,bevel=0):
  o=box(id+'_'+n,(x+loc[0],loc[1],loc[2]),size,m,bevel);objs.append(o);return o
 add('plinth',(0,0,b/2),(w,w,b),base,min(.0015,b*.12))
 # All four edge posts, upper and lower rims. Frame lies inside nominal glass cube footprint.
 for i in [-1,1]:
  for j in [-1,1]:
   add('post_%d_%d'%(i,j),(i*(w-f)/2,j*(w-f)/2,b+w/2),(f,f,w),metal,f*.14)
 for level,z in [('lower',b+f/2),('upper',b+w-f/2)]:
  for i in [-1,1]:
   add(level+'_x_'+str(i),(0,i*(w-f)/2,z),(w-2*f,f,f),metal,f*.12)
   add(level+'_y_'+str(i),(i*(w-f)/2,0,z),(f,w-2*f,f),metal,f*.12)
 # five panes, each separate, front is removable without altering other parts.
 span=w-2*f
 h=w-2*f
 add('glass_front_removable',(0,-w/2+t/2,b+w/2),(span,t,h),glass,min(.00025,t*.12))
 add('glass_back',(0,w/2-t/2,b+w/2),(span,t,h),glass,min(.00025,t*.12))
 for i in [-1,1]:
  add('glass_side_'+str(i),(i*(w/2-t/2),0,b+w/2),(t,span,h),glass,min(.00025,t*.12))
 add('glass_top',(0,0,b+w-t/2),(span,span,t),glass,min(.00025,t*.12))
 return objs
for suffix,w,b,t,f in specs:
 setup();id='artifact_glass_cube_'+suffix
 objs=build(id,w,b,t,f)
 bpy.context.scene['design']='Empty display case; front panel independently editable; no artifact.'
 bpy.context.scene['nominal_glass_cube_side_m']=w
 bpy.context.scene['base_height_m']=b
 bpy.context.scene['glass_thickness_m']=t
 bpy.context.scene['frame_width_m']=f
 bpy.ops.wm.save_as_mainfile(filepath=str(SRC/(id+'.blend')),compress=True)
 p=BANK/id;p.mkdir(parents=True,exist_ok=True)
 bpy.ops.export_scene.gltf(filepath=str(p/'model.gltf'),export_format='GLTF_SEPARATE',export_animations=False,export_cameras=False,export_lights=False)
 print('MODEL',id,len(objs),flush=True)
# Render all three actual Blender source constructions together for visual QA.
setup()
for (suffix,w,b,t,f),x in zip(specs,[-.47,-.105,.43]):
 build('artifact_glass_cube_'+suffix,w,b,t,f,x)
ground=mat('studio_ground',(.12,.115,.105),0,.55)
box('preview_floor',(0,0,-.025),(200,200,.05),ground)
sc=bpy.context.scene
sc.render.engine='CYCLES';sc.cycles.samples=24;sc.cycles.use_denoising=True
sc.render.resolution_x=1000;sc.render.resolution_y=620;sc.render.resolution_percentage=100
sc.world=bpy.data.worlds.new('Preview world');sc.world.use_nodes=True;sc.world.node_tree.nodes.get('Background').inputs[0].default_value=(.14,.16,.19,1);sc.world.node_tree.nodes.get('Background').inputs[1].default_value=.45
def point(o,target):o.rotation_euler=(Vector(target)-o.location).to_track_quat('-Z','Y').to_euler()
for n,loc,power,size,col in [('key',(-1.7,-1.7,2.3),180,2,(1,.86,.7)),('fill',(1.6,-.3,1.6),140,1.6,(.8,.91,1)),('rim',(.1,1.7,1.4),250,1.7,(1,.94,.85))]:
 d=bpy.data.lights.new(n,'AREA');d.energy=power;d.shape='RECTANGLE';d.size=size;d.size_y=size*.65;d.color=col
 o=bpy.data.objects.new(n,d);sc.collection.objects.link(o);o.location=loc;point(o,(0,0,.23))
d=bpy.data.cameras.new('PreviewCamera');o=bpy.data.objects.new('PreviewCamera',d);sc.collection.objects.link(o);o.location=(1.3,-3.8,1.9);point(o,(0,0,.25));d.type='ORTHO';d.ortho_scale=1.65;sc.camera=o
sc.view_settings.view_transform='AgX'
sc.render.image_settings.file_format='PNG';sc.render.filepath=str(ROOT/'preview.png')
bpy.ops.render.render(write_still=True)
