import bpy
import math
import os
from mathutils import Vector


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUTPUT_DIR = os.path.join(ROOT, "assets", "models")
BLEND_PATH = os.path.join(OUTPUT_DIR, "kaizen_arm_prototype.blend")
GLB_PATH = os.path.join(OUTPUT_DIR, "kaizen_arm_prototype.glb")
PREVIEW_PATH = os.path.join(OUTPUT_DIR, "kaizen_arm_prototype_preview.png")


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
        pass


def material(name, color, metallic=0.0, roughness=0.48):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    return mat


def make_spindle(name, start, end, width, depth, mat, display_name, rings=14, segments=20):
    start = Vector(start)
    end = Vector(end)
    axis = end - start
    direction = axis.normalized()
    helper = Vector((0, 1, 0))
    if abs(direction.dot(helper)) > 0.92:
        helper = Vector((1, 0, 0))
    side = direction.cross(helper).normalized()
    front = side.cross(direction).normalized()

    verts = []
    for i in range(rings + 1):
        t = i / rings
        center = start.lerp(end, t)
        # Tapered anatomical belly with small, flat tendon ends.
        profile = 0.18 + 0.82 * (math.sin(math.pi * t) ** 0.62)
        for j in range(segments):
            angle = 2.0 * math.pi * j / segments
            offset = side * (math.cos(angle) * width * profile)
            offset += front * (math.sin(angle) * depth * profile)
            verts.append(tuple(center + offset))

    faces = []
    for i in range(rings):
        for j in range(segments):
            a = i * segments + j
            b = i * segments + (j + 1) % segments
            c = (i + 1) * segments + (j + 1) % segments
            d = (i + 1) * segments + j
            faces.append((a, b, c, d))
    faces.append(tuple(range(segments - 1, -1, -1)))
    last = rings * segments
    faces.append(tuple(last + j for j in range(segments)))

    mesh = bpy.data.meshes.new(f"{name}_mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    obj["muscle_id"] = name
    obj["display_name_de"] = display_name
    obj["clickable"] = True
    obj["kaizen_category"] = "muscle"
    for polygon in mesh.polygons:
        polygon.use_smooth = True
    bevel = obj.modifiers.new("Soft anatomical edges", "BEVEL")
    bevel.width = 0.018
    bevel.segments = 2
    return obj


def add_uv_sphere(name, location, scale, mat, category="joint"):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=20, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    obj["clickable"] = False
    obj["kaizen_category"] = category
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    return obj


def add_cylinder_between(name, start, end, radius, mat):
    start = Vector(start)
    end = Vector(end)
    midpoint = (start + end) / 2
    direction = end - start
    bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=radius, depth=direction.length, location=midpoint)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = direction.to_track_quat("Z", "Y")
    obj.data.materials.append(mat)
    obj["clickable"] = False
    obj["kaizen_category"] = "bone"
    bevel = obj.modifiers.new("Rounded bone", "BEVEL")
    bevel.width = radius * 0.22
    bevel.segments = 3
    return obj


def look_at(obj, point):
    direction = Vector(point) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


clear_scene()
os.makedirs(OUTPUT_DIR, exist_ok=True)

muscle_red = material("Muscle_Red", (0.46, 0.055, 0.035), roughness=0.42)
muscle_light = material("Muscle_Light", (0.67, 0.12, 0.075), roughness=0.4)
muscle_dark = material("Muscle_Dark", (0.29, 0.025, 0.02), roughness=0.5)
tendon = material("Tendon", (0.72, 0.58, 0.43), roughness=0.65)
bone = material("Bone", (0.68, 0.61, 0.48), roughness=0.62)
joint = material("Joint_Cartilage", (0.18, 0.35, 0.58), metallic=0.05, roughness=0.34)

# Upper arm: shoulder and hand are deliberately omitted. Negative Y is the front.
make_spindle("muscle_biceps_brachii", (-0.08, -0.18, 2.75), (0.02, -0.23, 0.84), 0.34, 0.25, muscle_light, "Bizeps")
make_spindle("muscle_brachialis", (0.27, -0.02, 2.45), (0.19, -0.12, 0.78), 0.19, 0.18, muscle_red, "Armbeuger")
make_spindle("muscle_triceps_brachii", (-0.06, 0.22, 2.78), (-0.08, 0.18, 0.77), 0.36, 0.25, muscle_dark, "Trizeps")

# Elbow and simplified internal bones provide recognizable anatomy.
add_cylinder_between("bone_humerus", (0.0, 0.02, 2.88), (0.0, 0.02, 0.68), 0.105, bone)
add_uv_sphere("joint_elbow", (0.03, 0.0, 0.61), (0.24, 0.22, 0.22), joint)

# Slightly angled forearm, ending cleanly at the wrist (no hand).
make_spindle("muscle_brachioradialis", (-0.14, -0.16, 0.55), (0.38, -0.17, -1.25), 0.22, 0.16, muscle_light, "Oberarmspeichenmuskel")
make_spindle("muscle_flexor_carpi_radialis", (0.10, -0.22, 0.42), (0.49, -0.19, -1.28), 0.145, 0.115, muscle_red, "Radialer Handbeuger")
make_spindle("muscle_flexor_digitorum_superficialis", (-0.04, -0.27, 0.34), (0.30, -0.25, -1.24), 0.19, 0.13, muscle_light, "Oberflächlicher Fingerbeuger")
make_spindle("muscle_pronator_teres", (0.14, -0.20, 0.48), (-0.10, -0.23, -0.20), 0.14, 0.105, muscle_dark, "Runder Einwärtsdreher")
make_spindle("muscle_extensor_digitorum", (0.02, 0.20, 0.40), (0.43, 0.18, -1.27), 0.18, 0.13, muscle_dark, "Fingerstrecker")
make_spindle("muscle_extensor_carpi_ulnaris", (-0.19, 0.10, 0.38), (0.18, 0.10, -1.29), 0.13, 0.105, muscle_red, "Ulnarer Handstrecker")

add_cylinder_between("bone_radius", (0.10, -0.01, 0.52), (0.43, -0.02, -1.36), 0.064, bone)
add_cylinder_between("bone_ulna", (-0.09, 0.06, 0.50), (0.25, 0.06, -1.37), 0.058, bone)

# Tendon collars emphasize the intentional open cuts at upper arm and wrist.
bpy.ops.mesh.primitive_torus_add(major_radius=0.25, minor_radius=0.035, major_segments=32, minor_segments=10, location=(-0.02, 0.0, 2.83))
bpy.context.object.name = "proximal_cut_tendon"
bpy.context.object.data.materials.append(tendon)
bpy.ops.mesh.primitive_torus_add(major_radius=0.17, minor_radius=0.026, major_segments=32, minor_segments=10, location=(0.34, 0.0, -1.34))
wrist = bpy.context.object
wrist.name = "distal_cut_tendon"
wrist.data.materials.append(tendon)
wrist.rotation_euler[1] = math.radians(-15)

# Neutral world and studio presentation.
bpy.context.scene.world.color = (0.008, 0.012, 0.018)
bpy.ops.object.camera_add(location=(5.8, -8.5, 2.8))
camera = bpy.context.object
camera.name = "Preview_Camera"
look_at(camera, (0.05, 0.0, 0.75))
camera.data.lens = 58
bpy.context.scene.camera = camera

for name, loc, energy, size, color in [
    ("Key", (-3.5, -4.0, 5.0), 1100, 4.0, (1.0, 0.72, 0.58)),
    ("Fill", (4.0, -2.0, 2.5), 850, 3.0, (0.46, 0.64, 1.0)),
    ("Rim", (0.0, 3.0, 3.8), 1250, 2.5, (0.75, 0.86, 1.0)),
]:
    bpy.ops.object.light_add(type="AREA", location=loc)
    lamp = bpy.context.object
    lamp.name = name
    lamp.data.energy = energy
    lamp.data.shape = "DISK"
    lamp.data.size = size
    lamp.data.color = color
    look_at(lamp, (0.05, 0.0, 0.7))

scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x = 720
scene.render.resolution_y = 900
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.render.film_transparent = True
scene.render.filepath = PREVIEW_PATH
scene.view_settings.look = "AgX - Medium High Contrast"

# Save the editable source first, render a preview, then export only model meshes.
bpy.ops.wm.save_as_mainfile(filepath=BLEND_PATH)
bpy.ops.render.render(write_still=True)

bpy.ops.object.select_all(action="DESELECT")
for obj in bpy.context.scene.objects:
    if obj.type == "MESH":
        obj.select_set(True)
bpy.context.view_layer.objects.active = next(obj for obj in bpy.context.selected_objects if obj.type == "MESH")
bpy.ops.export_scene.gltf(
    filepath=GLB_PATH,
    export_format="GLB",
    use_selection=True,
    export_extras=True,
    export_cameras=False,
    export_lights=False,
    export_apply=True,
)

print(f"BLEND={BLEND_PATH}")
print(f"GLB={GLB_PATH}")
print(f"PREVIEW={PREVIEW_PATH}")
