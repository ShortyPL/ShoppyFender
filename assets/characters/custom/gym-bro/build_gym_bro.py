"""Higher-quality stylized gym-bro. Lofted topology, no voxel blobs. Units: meters."""
import math
import bpy
import bmesh
from mathutils import Vector, Matrix

OUT = "/Volumes/TimeData/Cursor/ShoppyFender/assets/characters/custom/gym-bro"
SEGS = 24


def purge():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.cameras,
                 bpy.data.lights, bpy.data.curves, bpy.data.images):
        for item in list(coll):
            if item.users == 0:
                coll.remove(item)


def set_in(bsdf, keys, value):
    for k in keys:
        if k in bsdf.inputs:
            try:
                bsdf.inputs[k].default_value = value
                return
            except Exception:
                continue


def mat(name, color, roughness=0.45, metallic=0.0, spec=0.5,
        sss=0.0, transmission=0.0, alpha=1.0, ior=1.45, sheen=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    set_in(bsdf, ["Base Color"], (*color, 1.0))
    set_in(bsdf, ["Roughness"], roughness)
    set_in(bsdf, ["Metallic"], metallic)
    set_in(bsdf, ["Specular IOR Level", "Specular"], spec)
    set_in(bsdf, ["Subsurface Weight", "Subsurface"], sss)
    if "Subsurface Radius" in bsdf.inputs:
        try:
            bsdf.inputs["Subsurface Radius"].default_value = (1.0, 0.4, 0.2)
        except Exception:
            pass
    set_in(bsdf, ["Transmission Weight", "Transmission"], transmission)
    set_in(bsdf, ["Alpha"], alpha)
    set_in(bsdf, ["IOR"], ior)
    if sheen:
        set_in(bsdf, ["Sheen Weight"], sheen)
        set_in(bsdf, ["Sheen Roughness"], 0.4)
    if alpha < 0.999 and hasattr(m, "blend_method"):
        try:
            m.blend_method = "BLEND"
        except TypeError:
            pass
    return m


def active(obj):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    return obj


def finish(obj, levels=2):
    active(obj)
    mesh = obj.data
    mesh.validate()
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    bpy.ops.object.shade_smooth()
    if levels:
        sub = obj.modifiers.new("Subsurf", "SUBSURF")
        sub.levels = levels
        sub.render_levels = max(levels, 2)
        sub.quality = 3
    ang = obj.modifiers.new("SmoothAngle", "WEIGHTED_NORMAL") if False else None
    try:
        sm = obj.modifiers.new("ByAngle", "SMOOTH_BY_ANGLE")
        sm.angle = math.radians(40)
    except Exception:
        pass
    return obj


def mesh_from(name, verts, faces, levels=2):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata([tuple(v) for v in verts], [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    return finish(obj, levels)


def loft_profiles(name, profiles, segs=SEGS, cap=True, levels=2):
    """profiles: [(z, rx, ry, ox, oy), ...]  +Y is back, -Y is front."""
    verts, faces, rings = [], [], []
    for z, rx, ry, ox, oy in profiles:
        ring = []
        for j in range(segs):
            a = 2 * math.pi * j / segs
            verts.append((ox + rx * math.cos(a), oy + ry * math.sin(a), z))
            ring.append(len(verts) - 1)
        rings.append(ring)
    for i in range(len(rings) - 1):
        for j in range(segs):
            a, b = rings[i][j], rings[i][(j + 1) % segs]
            c, d = rings[i + 1][(j + 1) % segs], rings[i + 1][j]
            faces.append((a, b, c, d))
    if cap:
        faces.append(list(reversed(rings[0])))
        faces.append(list(rings[-1]))
    return mesh_from(name, verts, faces, levels)


def _frame(tangent, up_hint=Vector((0, 0, 1))):
    t = tangent.normalized()
    up = Vector(up_hint)
    if abs(t.dot(up)) > 0.92:
        up = Vector((0, 1, 0))
    b = t.cross(up)
    if b.length < 1e-6:
        b = t.cross(Vector((1, 0, 0)))
    b.normalize()
    n = b.cross(t).normalized()
    return n, b


def loft_path(name, points, radii, segs=16, levels=2):
    """points: Vectors; radii: float or (rx, ry) per point."""
    pts = [Vector(p) for p in points]
    verts, faces, rings = [], [], []
    prev_n = Vector((1, 0, 0))
    for i, p in enumerate(pts):
        if i == 0:
            tang = pts[1] - pts[0]
        elif i == len(pts) - 1:
            tang = pts[-1] - pts[-2]
        else:
            tang = pts[i + 1] - pts[i - 1]
        n, b = _frame(tang, prev_n)
        prev_n = n
        r = radii[i]
        rx, ry = (r, r) if isinstance(r, (int, float)) else r
        ring = []
        for j in range(segs):
            a = 2 * math.pi * j / segs
            offset = n * (rx * math.cos(a)) + b * (ry * math.sin(a))
            verts.append(p + offset)
            ring.append(len(verts) - 1)
        rings.append(ring)
    for i in range(len(rings) - 1):
        for j in range(segs):
            a, c0 = rings[i][j], rings[i][(j + 1) % segs]
            c1, d = rings[i + 1][(j + 1) % segs], rings[i + 1][j]
            faces.append((a, c0, c1, d))
    faces.append(list(reversed(rings[0])))
    faces.append(list(rings[-1]))
    return mesh_from(name, verts, faces, levels)


def uv_sphere(name, loc, scale, seg=32, rings=16, levels=2):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=rings, radius=1.0, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return finish(obj, levels)


def cylinder(name, loc, radius, depth, rot=(0, 0, 0), verts=24, levels=1):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=radius, depth=depth, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_euler = rot
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return finish(obj, levels)


def cube(name, loc, scale, rot=(0, 0, 0), levels=1):
    bpy.ops.mesh.primitive_cube_add(size=2.0, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_euler = rot
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return finish(obj, levels)


def torus(name, loc, major, minor, rot=(0, 0, 0), levels=1):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_euler = rot
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return finish(obj, levels)


def assign(obj, material):
    obj.data.materials.clear()
    obj.data.materials.append(material)


def join(objs, name):
    objs = [o for o in objs if o is not None]
    active(objs[0])
    for o in objs:
        o.select_set(True)
    bpy.ops.object.join()
    objs[0].name = name
    return objs[0]


def build_mats():
    return {
        "skin": mat("M_Skin", (0.79, 0.55, 0.43), roughness=0.38, spec=0.45, sss=0.35),
        "lip": mat("M_Lip", (0.68, 0.34, 0.33), roughness=0.28, spec=0.55, sss=0.15),
        "hair": mat("M_Hair", (0.055, 0.028, 0.018), roughness=0.22, spec=0.4),
        "brow": mat("M_Brow", (0.035, 0.018, 0.012), roughness=0.35),
        "eye": mat("M_Sclera", (0.97, 0.96, 0.94), roughness=0.08, spec=0.8),
        "iris": mat("M_Iris", (0.32, 0.18, 0.08), roughness=0.14, spec=0.55),
        "pupil": mat("M_Pupil", (0.01, 0.008, 0.006), roughness=0.04),
        "hi": mat("M_Catch", (1, 1, 1), roughness=0.03, spec=1.0),
        "shirt": mat("M_Shirt", (0.13, 0.135, 0.145), roughness=0.52, spec=0.2, sheen=0.45),
        "shorts": mat("M_Shorts", (0.08, 0.082, 0.09), roughness=0.55, spec=0.18, sheen=0.35),
        "shoe": mat("M_Shoe", (0.02, 0.02, 0.025), roughness=0.32),
        "sole": mat("M_Sole", (0.93, 0.93, 0.91), roughness=0.4),
        "logo": mat("M_Logo", (0.82, 0.84, 0.86), roughness=0.22, metallic=0.25),
        "bag": mat("M_Bag", (0.06, 0.06, 0.07), roughness=0.48),
        "bag2": mat("M_BagPanel", (0.04, 0.04, 0.045), roughness=0.45),
        "strap": mat("M_Strap", (0.03, 0.03, 0.035), roughness=0.5),
        "metal": mat("M_Metal", (0.72, 0.62, 0.28), roughness=0.18, metallic=0.8),
        "shaker": mat("M_Shaker", (0.04, 0.04, 0.045), roughness=0.28),
        "lid": mat("M_Lid", (0.50, 0.51, 0.53), roughness=0.3),
        "shake": mat("M_Shake", (0.76, 0.60, 0.38), roughness=0.18),
        "clear": mat("M_Clear", (0.80, 0.84, 0.86), roughness=0.05, transmission=0.88, alpha=0.18, ior=1.4),
        "watch": mat("M_Watch", (0.035, 0.035, 0.04), roughness=0.22, metallic=0.3),
        "wface": mat("M_WFace", (0.12, 0.14, 0.16), roughness=0.06, metallic=0.4),
        "floor": mat("M_Floor", (0.88, 0.89, 0.90), roughness=0.72),
    }


def setup_world(mats):
    scene = bpy.context.scene
    for engine in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
        try:
            scene.render.engine = engine
            break
        except TypeError:
            continue
    if hasattr(scene.eevee, "taa_render_samples"):
        scene.eevee.taa_render_samples = 64
    world = bpy.data.worlds.new("Studio") if "Studio" not in bpy.data.worlds else bpy.data.worlds["Studio"]
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs[0].default_value = (0.62, 0.66, 0.70, 1.0)
    bg.inputs[1].default_value = 0.35

    cam_d = bpy.data.cameras.new("GymCam")
    cam = bpy.data.objects.new("GymCam", cam_d)
    bpy.context.collection.objects.link(cam)
    cam.location = (1.05, -3.15, 1.05)
    cam_d.lens = 85
    cam_d.dof.use_dof = False
    target = Vector((0.02, -0.05, 0.92))
    cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam

    def area(name, loc, rot, energy, size, color=(1.0, 0.97, 0.93)):
        light = bpy.data.lights.new(name, "AREA")
        light.energy = energy
        light.size = size
        light.color = color
        ob = bpy.data.objects.new(name, light)
        bpy.context.collection.objects.link(ob)
        ob.location = loc
        ob.rotation_euler = rot

    area("Key", (1.5, -1.9, 2.35), (math.radians(58), 0, math.radians(36)), 650, 1.6)
    area("Fill", (-1.8, -1.4, 1.45), (math.radians(72), 0, math.radians(-50)), 180, 2.0, (0.80, 0.88, 1.0))
    area("Rim", (-0.2, 2.1, 2.05), (math.radians(122), 0, math.radians(180)), 320, 1.2, (1.0, 0.96, 0.90))
    area("Kick", (0.3, -0.8, 0.15), (0, 0, 0), 55, 2.4, (0.95, 0.92, 0.88))

    cyc = cube("Cyclorama", (0, 1.4, 1.1), (2.4, 0.08, 1.6), levels=0)
    assign(cyc, mats["floor"])
    floor = cube("StudioFloor", (0, 0, -0.025), (2.2, 2.4, 0.025), levels=0)
    assign(floor, mats["floor"])


def build_torso(mats):
    # Front is -Y. Broad chest, athletic waist, hips.
    torso = loft_profiles("SM_Char_Torso", [
        (0.90, 0.155, 0.105, 0.0, -0.01),
        (1.00, 0.135, 0.095, 0.0, -0.01),
        (1.10, 0.125, 0.090, 0.0, -0.02),
        (1.20, 0.175, 0.120, 0.0, -0.04),
        (1.28, 0.195, 0.135, 0.0, -0.05),
        (1.36, 0.185, 0.115, 0.0, -0.03),
        (1.43, 0.080, 0.070, 0.0, -0.01),
        (1.50, 0.058, 0.055, 0.0,  0.00),
        (1.55, 0.062, 0.058, 0.0,  0.00),
    ], segs=28, levels=2)
    assign(torso, mats["skin"])

    shirt = loft_profiles("SM_Char_Shirt", [
        (1.005, 0.145, 0.108, 0.0, -0.01),
        (1.10, 0.140, 0.105, 0.0, -0.02),
        (1.20, 0.188, 0.132, 0.0, -0.04),
        (1.28, 0.208, 0.148, 0.0, -0.05),
        (1.36, 0.198, 0.128, 0.0, -0.03),
        (1.42, 0.095, 0.085, 0.0, -0.01),
        (1.455, 0.078, 0.072, 0.0,  0.00),
    ], segs=28, levels=2)
    assign(shirt, mats["shirt"])

    shorts = loft_profiles("SM_Char_Shorts", [
        (0.905, 0.168, 0.118, 0.0, -0.01),
        (0.86, 0.165, 0.115, 0.0, 0.00),
        (0.78, 0.155, 0.110, 0.0, 0.00),
        (0.70, 0.145, 0.100, 0.0, 0.00),
        (0.655, 0.138, 0.095, 0.0, 0.00),
    ], segs=28, levels=2)
    assign(shorts, mats["shorts"])
    return torso, shirt, shorts


def build_limbs(mats):
    objs = []
    # His right arm = -X, bent, bottle at chest. Front = -Y.
    arm_r = loft_path("ArmR", [
        (-0.20, -0.02, 1.36),
        (-0.30, -0.04, 1.28),
        (-0.36, -0.06, 1.18),
        (-0.32, -0.10, 1.08),
        (-0.18, -0.14, 1.14),
        (-0.06, -0.16, 1.22),
        (0.00, -0.17, 1.27),
    ], [0.095, 0.100, 0.092, 0.062, 0.055, 0.048, 0.042], segs=16)
    assign(arm_r, mats["skin"])
    objs.append(arm_r)

    sleeve_r = loft_path("SleeveR", [
        (-0.20, -0.02, 1.36),
        (-0.30, -0.04, 1.29),
        (-0.34, -0.05, 1.23),
    ], [0.108, 0.102, 0.095], segs=16)
    assign(sleeve_r, mats["shirt"])
    objs.append(sleeve_r)

    arm_l = loft_path("ArmL", [
        (0.20, -0.02, 1.36),
        (0.30, -0.03, 1.24),
        (0.34, -0.04, 1.10),
        (0.33, -0.05, 0.94),
        (0.31, -0.06, 0.80),
        (0.30, -0.07, 0.68),
        (0.30, -0.08, 0.60),
    ], [0.095, 0.098, 0.085, 0.062, 0.050, 0.046, 0.042], segs=16)
    assign(arm_l, mats["skin"])
    objs.append(arm_l)

    sleeve_l = loft_path("SleeveL", [
        (0.20, -0.02, 1.36),
        (0.29, -0.03, 1.28),
        (0.32, -0.03, 1.22),
    ], [0.108, 0.100, 0.094], segs=16)
    assign(sleeve_l, mats["shirt"])
    objs.append(sleeve_l)

    for side, x in (("L", 0.11), ("R", -0.11)):
        leg = loft_path(f"Leg{side}", [
            (x, 0.00, 0.90),
            (x * 1.08, 0.01, 0.72),
            (x * 1.10, 0.00, 0.55),
            (x * 1.05, 0.01, 0.46),
            (x * 1.05, 0.03, 0.32),
            (x * 1.00, 0.02, 0.18),
            (x * 0.98, 0.01, 0.09),
        ], [0.095, 0.100, 0.085, 0.068, 0.090, 0.055, 0.042], segs=16)
        assign(leg, mats["skin"])
        objs.append(leg)
        thigh = loft_path(f"ShortLeg{side}", [
            (x, 0.00, 0.90),
            (x * 1.08, 0.01, 0.78),
            (x * 1.10, 0.01, 0.68),
        ], [0.108, 0.112, 0.108], segs=16)
        assign(thigh, mats["shorts"])
        objs.append(thigh)
    return objs


def build_hands(mats):
    # Mitten + thumb, posed to hold bottles.
    def hand(name, loc, rot, mirror=False):
        palm = uv_sphere(name + "Palm", loc, (0.045, 0.032, 0.055), 20, 12, 2)
        assign(palm, mats["skin"])
        th = uv_sphere(name + "Thumb", (
            loc[0] + (-0.035 if not mirror else 0.035),
            loc[1] - 0.01,
            loc[2] + 0.01,
        ), (0.016, 0.014, 0.028), 12, 8, 1)
        assign(th, mats["skin"])
        fingers = cylinder(name + "Fing", (
            loc[0], loc[1] - 0.01, loc[2] - (0.04 if loc[2] < 1.0 else -0.04)
        ), 0.028, 0.055, rot=rot, verts=12, levels=1)
        assign(fingers, mats["skin"])
        return join([palm, th, fingers], name)

    hr = hand("HandR", (0.00, -0.18, 1.28), (math.radians(70), 0, 0), mirror=False)
    hl = hand("HandL", (0.30, -0.09, 0.58), (math.radians(8), 0, 0), mirror=True)
    return hr, hl


def build_head(mats):
    parts = []
    head = uv_sphere("Head", (0.0, -0.02, 1.62), (0.128, 0.118, 0.142), 40, 24, 2)
    assign(head, mats["skin"])
    # Jaw / chin pull: edit vertices toward camera (-Y) and down.
    for v in head.data.vertices:
        x, y, z = v.co
        lz = z - 1.62
        ly = y + 0.02
        if lz < -0.04 and ly < 0.02:
            v.co.y -= 0.025
            v.co.z -= 0.018
        if abs(x) > 0.06 and lz < 0.02 and ly < 0:
            v.co.x *= 1.06
    parts.append(head)

    jaw = uv_sphere("Jaw", (0.0, -0.04, 1.50), (0.095, 0.080, 0.070), 28, 16, 2)
    assign(jaw, mats["skin"])
    parts.append(jaw)
    chin = uv_sphere("Chin", (0.0, -0.10, 1.445), (0.040, 0.032, 0.030), 16, 10, 1)
    assign(chin, mats["skin"])
    parts.append(chin)
    neck = loft_profiles("NeckVis", [
        (1.48, 0.055, 0.050, 0.0, 0.0),
        (1.54, 0.058, 0.052, 0.0, -0.01),
        (1.58, 0.070, 0.060, 0.0, -0.02),
    ], segs=20, levels=2)
    assign(neck, mats["skin"])
    parts.append(neck)

    nose = uv_sphere("Nose", (0.0, -0.145, 1.575), (0.020, 0.036, 0.026), 20, 12, 2)
    assign(nose, mats["skin"])
    parts.append(nose)

    for side, x in (("L", 0.10), ("R", -0.10)):
        ear = uv_sphere(f"Ear{side}", (x, 0.02, 1.60), (0.026, 0.016, 0.045), 16, 12, 1)
        assign(ear, mats["skin"])
        parts.append(ear)

    smile = uv_sphere("Lips", (0.0, -0.132, 1.488), (0.040, 0.012, 0.011), 20, 10, 1)
    assign(smile, mats["lip"])
    parts.append(smile)

    for side, x in (("L", 0.044), ("R", -0.044)):
        eye = uv_sphere(f"Eye{side}", (x, -0.125, 1.605), (0.040, 0.024, 0.032), 24, 16, 2)
        assign(eye, mats["eye"])
        parts.append(eye)
        iris = uv_sphere(f"Iris{side}", (x, -0.145, 1.605), (0.020, 0.008, 0.020), 20, 12, 1)
        assign(iris, mats["iris"])
        parts.append(iris)
        pupil = uv_sphere(f"Pupil{side}", (x, -0.152, 1.605), (0.009, 0.004, 0.009), 16, 10, 0)
        assign(pupil, mats["pupil"])
        parts.append(pupil)
        hi = uv_sphere(f"Hi{side}", (x + 0.012, -0.155, 1.616), (0.007, 0.003, 0.006), 12, 8, 0)
        assign(hi, mats["hi"])
        parts.append(hi)
        lidu = uv_sphere(f"LidU{side}", (x, -0.118, 1.630), (0.042, 0.018, 0.012), 16, 10, 1)
        assign(lidu, mats["skin"])
        parts.append(lidu)
        lidd = uv_sphere(f"LidD{side}", (x, -0.118, 1.580), (0.038, 0.016, 0.010), 16, 10, 1)
        assign(lidd, mats["skin"])
        parts.append(lidd)
        brow = loft_path(f"Brow{side}", [
            (x - 0.032 * (1 if x > 0 else -1), -0.110, 1.642),
            (x, -0.118, 1.650),
            (x + 0.028 * (1 if x > 0 else -1), -0.108, 1.640),
        ], [0.011, 0.013, 0.010], segs=10, levels=1)
        assign(brow, mats["brow"])
        parts.append(brow)
    return join(parts, "SM_Char_Head")


def build_hair(mats):
    cap = loft_profiles("HairCap", [
        (1.58, 0.125, 0.115, 0.02, 0.00),
        (1.64, 0.130, 0.120, 0.03, -0.02),
        (1.70, 0.118, 0.110, 0.04, -0.04),
        (1.76, 0.085, 0.080, 0.04, -0.05),
        (1.80, 0.040, 0.038, 0.03, -0.04),
    ], segs=24, levels=2)
    assign(cap, mats["hair"])
    quiff = loft_path("Quiff", [
        (0.02, -0.08, 1.68),
        (0.05, -0.12, 1.74),
        (0.06, -0.10, 1.78),
        (0.04, -0.04, 1.76),
    ], [0.055, 0.048, 0.035, 0.028], segs=14, levels=2)
    assign(quiff, mats["hair"])
    sides = []
    for x in (0.11, -0.11):
        s = uv_sphere(f"HairS{x}", (x, 0.02, 1.60), (0.045, 0.055, 0.070), 16, 10, 1)
        assign(s, mats["hair"])
        sides.append(s)
    back = uv_sphere("HairBack", (0.02, 0.08, 1.62), (0.110, 0.055, 0.080), 20, 12, 1)
    assign(back, mats["hair"])
    return join([cap, quiff, back] + sides, "SM_Char_Hair")


def build_beard(mats):
    beard = loft_path("Beard", [
        (0.07, -0.06, 1.54),
        (0.05, -0.11, 1.47),
        (0.00, -0.12, 1.43),
        (-0.05, -0.11, 1.47),
        (-0.07, -0.06, 1.54),
    ], [0.022, 0.028, 0.030, 0.028, 0.022], segs=10, levels=2)
    assign(beard, mats["hair"])
    stache = loft_path("Stache", [
        (0.028, -0.128, 1.505),
        (0.00, -0.135, 1.500),
        (-0.028, -0.128, 1.505),
    ], [0.010, 0.012, 0.010], segs=8, levels=1)
    assign(stache, mats["hair"])
    return join([beard, stache], "SM_Char_Beard")


def build_shoes(mats):
    parts = []
    for side, x in (("L", 0.11), ("R", -0.11)):
        body = loft_path(f"Shoe{side}", [
            (x, -0.04, 0.055),
            (x, 0.04, 0.050),
            (x, 0.12, 0.045),
            (x, 0.16, 0.055),
        ], [(0.055, 0.042), (0.058, 0.040), (0.050, 0.038), (0.042, 0.032)], segs=14, levels=2)
        assign(body, mats["shoe"])
        parts.append(body)
        sole = cube(f"Sole{side}", (x, 0.06, 0.012), (0.055, 0.13, 0.012), levels=1)
        assign(sole, mats["sole"])
        parts.append(sole)
        heel = cube(f"Heel{side}", (x, -0.04, 0.028), (0.050, 0.040, 0.022), levels=1)
        assign(heel, mats["sole"])
        parts.append(heel)
        logo = cube(f"Logo{side}", (x + (0.055 if x > 0 else -0.055), 0.05, 0.055),
                    (0.006, 0.040, 0.014),
                    rot=(0, 0, math.radians(18 if x > 0 else -18)), levels=0)
        assign(logo, mats["logo"])
        parts.append(logo)
    return join(parts, "SM_Char_Shoes")


def build_bag(mats):
    bag = cube("Bag", (-0.30, 0.06, 0.88), (0.13, 0.10, 0.19), levels=2)
    bev = bag.modifiers.new("Bevel", "BEVEL")
    bev.width = 0.045
    bev.segments = 5
    active(bag)
    bpy.ops.object.modifier_apply(modifier="Bevel")
    assign(bag, mats["bag"])
    panel = cube("BagFace", (-0.30, -0.04, 0.88), (0.10, 0.016, 0.13), levels=1)
    assign(panel, mats["bag2"])
    strap = loft_path("Strap", [
        (-0.22, -0.02, 1.36),
        (-0.18, 0.04, 1.18),
        (-0.24, 0.08, 1.00),
        (-0.30, 0.06, 0.88),
    ], [0.016, 0.016, 0.018, 0.018], segs=10, levels=1)
    assign(strap, mats["strap"])
    buckle = cube("Buckle", (-0.20, 0.02, 1.20), (0.025, 0.012, 0.018), levels=0)
    assign(buckle, mats["metal"])
    handle = torus("Handle", (-0.30, 0.02, 1.08), 0.05, 0.01, rot=(math.radians(90), 0, 0), levels=1)
    assign(handle, mats["strap"])
    return join([bag, panel, strap, buckle, handle], "SM_Prop_Bag")


def build_shakers(mats):
    def bottle(name, loc, body_mat, lid_mat, liquid=False):
        parts = []
        body = cylinder(name + "B", loc, 0.034, 0.15, verts=28, levels=1)
        assign(body, body_mat)
        parts.append(body)
        lid = cylinder(name + "L", (loc[0], loc[1], loc[2] + 0.085), 0.032, 0.032, verts=24, levels=1)
        assign(lid, lid_mat)
        parts.append(lid)
        cap = uv_sphere(name + "C", (loc[0], loc[1], loc[2] + 0.108), (0.024, 0.024, 0.016), 16, 10, 1)
        assign(cap, lid_mat)
        parts.append(cap)
        ring = torus(name + "R", (loc[0], loc[1], loc[2] + 0.068), 0.035, 0.005, levels=0)
        assign(ring, lid_mat)
        parts.append(ring)
        if liquid:
            liq = cylinder(name + "Q", (loc[0], loc[1], loc[2] - 0.02), 0.029, 0.10, verts=24, levels=0)
            assign(liq, mats["shake"])
            parts.append(liq)
        return parts

    parts = bottle("Blk", (0.00, -0.22, 1.30), mats["shaker"], mats["shaker"], False)
    parts += bottle("Clr", (0.30, -0.14, 0.48), mats["clear"], mats["lid"], True)
    return join(parts, "SM_Prop_Shakers")


def build_watch(mats):
    band = torus("Band", (0.31, -0.06, 0.78), 0.034, 0.006, rot=(0, math.radians(90), 0), levels=1)
    assign(band, mats["watch"])
    face = cylinder("WFace", (0.345, -0.06, 0.78), 0.018, 0.010, rot=(0, math.radians(90), 0), verts=20, levels=1)
    assign(face, mats["watch"])
    glass = cylinder("WGlass", (0.352, -0.06, 0.78), 0.014, 0.004, rot=(0, math.radians(90), 0), verts=20, levels=0)
    assign(glass, mats["wface"])
    return join([band, face, glass], "SM_Prop_Watch")


def parent_root():
    empty = bpy.data.objects.new("GymBro_Root", None)
    bpy.context.collection.objects.link(empty)
    empty.empty_display_type = "ARROWS"
    empty.empty_display_size = 0.12
    skip = {"CAMERA", "LIGHT", "EMPTY"}
    skipn = {"GymBro_Root", "GymCam", "Key", "Fill", "Rim", "Kick", "StudioFloor", "Cyclorama"}
    for obj in list(bpy.context.scene.objects):
        if obj == empty or obj.type in skip or obj.name in skipn:
            continue
        obj.parent = empty
    empty.rotation_euler.z = math.radians(18)
    return empty


def save_and_render(root):
    blend = f"{OUT}/gym_bro.blend"
    glb = f"{OUT}/gym_bro.glb"
    bpy.ops.wm.save_as_mainfile(filepath=blend)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in bpy.context.scene.objects:
        if obj.parent == root or obj == root:
            obj.select_set(True)
    bpy.context.view_layer.objects.active = root
    try:
        bpy.ops.export_scene.gltf(filepath=glb, export_format="GLB", use_selection=True)
    except TypeError:
        bpy.ops.export_scene.gltf(filepath=glb, use_selection=True)
    scene = bpy.context.scene
    scene.render.resolution_x = 900
    scene.render.resolution_y = 1400
    scene.render.filepath = f"{OUT}/preview.png"
    scene.render.image_settings.file_format = "PNG"
    bpy.ops.render.render(write_still=True)
    return blend, glb


def main():
    purge()
    mats = build_mats()
    setup_world(mats)
    build_torso(mats)
    build_limbs(mats)
    build_hands(mats)
    build_head(mats)
    build_hair(mats)
    build_beard(mats)
    build_shoes(mats)
    build_bag(mats)
    build_shakers(mats)
    build_watch(mats)
    root = parent_root()
    return save_and_render(root)
