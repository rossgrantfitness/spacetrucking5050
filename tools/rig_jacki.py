"""Rigs and animates Jacki (Blender, Python).

Takes the developer's Jacki model (art/models/jacki_rocket_cap.glb: one
mesh, no skeleton, standing in an A-pose) and a free skeleton with
animations (art/source/quaternius_casual_female.blend, from Quaternius's
"Ultimate Animated Character Pack", CC0 - public domain), and makes
art/models/jacki_rigged.glb: Jacki with a skeleton and all the pack's
animations (Idle, Walk, Run, SitDown, PickUp, Victory, Jump...).

How:
  1. Moves the skeleton's bones to Jacki's joints (she's chibi: short legs,
     big head), keeping each bone pointing the way it did, so the
     animations still fit.
  2. Swings the arm bones down from the skeleton's T-pose to her A-pose,
     makes that the new rest pose, and corrects every animation's arm
     keys by the same turn (so the arms still move as animated).
  3. Binds her mesh to the bones with Blender's automatic weights, then
     makes the head (and the long lop ears hanging beside it) follow only
     the head bone, so the ears never get dragged by an arm.

Needs Blender's Python module ("pip install bpy==4.2.0", Python 3.11). Run:
    python tools/rig_jacki.py
from the project folder. Then open Godot (or run --import) to reimport.
"""
import math
import os
import sys

import bpy
from mathutils import Matrix, Quaternion, Vector

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DONOR = os.path.join(HERE, "art", "source", "quaternius_casual_female.blend")
JACKI = os.path.join(HERE, "art", "models", "jacki_rocket_cap.glb")
OUTPUT = os.path.join(HERE, "art", "models", "jacki_rigged.glb")

# Jacki's joints, in her model's own units (she's 0.952 tall), standing on
# the ground (z = 0), facing -Y, her left at +X. Measured from front and
# side views of the model.
HIP_Z = 0.335
KNEE_Z = 0.165
ANKLE_Z = 0.07
LEG_X = 0.086
TOE_Y = -0.10
SPINE = [0.30, 0.335, 0.40, 0.47, 0.585, 0.62, 0.95]  # root, hips, abdomen, torso, neck, head, head top
CLAVICLE = (0.035, 0.53)  # Where the shoulder bone starts (x, z)...
SHOULDER = (0.125, 0.56)  # ...and the arm hangs from.
ELBOW = (0.20, 0.403)
WRIST = (0.20, 0.308)
FIST_END = (0.19, 0.206)
NECK_Z = 0.585
# The ears: anything this far out to the side and this high is ear, and
# goes with the head.
EAR_SIDE_X = 0.205
EAR_LOW_Z = 0.42


def log(*words):
    print("rig_jacki:", *words, flush=True)


def main():
    bpy.ops.wm.open_mainfile(filepath=DONOR)
    arm = bpy.data.objects["CharacterArmature"]
    for ob in list(bpy.data.objects):
        if ob != arm:
            bpy.data.objects.remove(ob, do_unlink=True)
    for mesh in list(bpy.data.meshes):
        bpy.data.meshes.remove(mesh)
    arm.animation_data.action = None

    # --- Jacki's mesh, feet on the ground ---------------------------------
    bpy.ops.import_scene.gltf(filepath=JACKI)
    body = [ob for ob in bpy.context.selected_objects if ob.type == "MESH"][0]
    body.name = "Jacki"
    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    bpy.context.view_layer.objects.active = body
    body.parent = None
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    low = min((body.matrix_world @ v.co).z for v in body.data.vertices)
    body.location.z -= low
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    for ob in list(bpy.data.objects):
        if ob not in (arm, body):
            bpy.data.objects.remove(ob, do_unlink=True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.remove_doubles(threshold=0.0005)  # (Helps the automatic weights.)
    bpy.ops.object.mode_set(mode="OBJECT")
    height = max(v.co.z for v in body.data.vertices)
    log("Jacki is", round(height, 3), "tall,", len(body.data.vertices), "corners")

    # --- 1. Bones to her joints (T-pose arms for now) ---------------------
    bpy.ops.object.select_all(action="DESELECT")
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    bones = arm.data.edit_bones
    upper = math.dist(SHOULDER, ELBOW)
    lower = math.dist(ELBOW, WRIST)
    fist = math.dist(WRIST, FIST_END)

    def put(name, head, tail):
        bone = bones[name]
        roll = bone.roll
        bone.head = Vector(head)
        bone.tail = Vector(tail)
        bone.roll = roll

    put("Bone", (0, 0, 0), (0, 0, 0.04))
    put("Body", (0, 0, SPINE[0]), (0, 0, SPINE[0] + 0.04))
    put("Hips", (0, 0, SPINE[1] - 0.02), (0, 0, SPINE[2]))
    put("Abdomen", (0, 0, SPINE[2]), (0, 0, SPINE[3]))
    put("Torso", (0, 0, SPINE[3]), (0, 0, SPINE[4]))
    put("Neck", (0, 0, SPINE[4]), (0, 0, SPINE[5]))
    put("Head", (0, 0, SPINE[5]), (0, 0, SPINE[6]))
    for side, sign in (("L", 1.0), ("R", -1.0)):
        sx = SHOULDER[0] * sign
        put("Shoulder." + side, (CLAVICLE[0] * sign, 0, CLAVICLE[1]), (sx, 0, SHOULDER[1]))
        put("UpperArm." + side, (sx, 0, SHOULDER[1]), (sx + upper * sign, 0, SHOULDER[1]))
        put("LowerArm." + side, (sx + upper * sign, 0, SHOULDER[1]), (sx + (upper + lower) * sign, 0, SHOULDER[1]))
        put("Fist." + side, (sx + (upper + lower) * sign, 0, SHOULDER[1]), (sx + (upper + lower + fist) * sign, 0, SHOULDER[1]))
        lx = LEG_X * sign
        put("UpperLeg." + side, (lx, 0, HIP_Z), (lx, -0.005, KNEE_Z))
        put("LowerLeg." + side, (lx, -0.005, KNEE_Z), (lx, 0, ANKLE_Z))
        put("Foot." + side, (lx, 0, ANKLE_Z * 0.5), (lx, TOE_Y, ANKLE_Z * 0.5))
        put("PoleTarget." + side, (lx, -0.35, KNEE_Z + 0.08), (lx, -0.35, KNEE_Z + 0.16))
    bpy.ops.object.mode_set(mode="OBJECT")

    # --- 2. Arms down into her A-pose, as the new rest pose ---------------
    drop = math.atan2(SHOULDER[1] - WRIST[1], WRIST[0] - SHOULDER[0])
    turns = {}
    bpy.ops.object.mode_set(mode="POSE")
    for side, sign in (("L", 1.0), ("R", -1.0)):
        name = "UpperArm." + side
        bone = arm.data.bones[name]
        head = bone.head_local.copy()
        turn = Matrix.Rotation(drop * sign, 4, "Y")  # Down, toward -Z.
        rest_old = bone.matrix_local.copy()
        pose = arm.pose.bones[name]
        pose.matrix = Matrix.Translation(head) @ turn @ Matrix.Translation(-head) @ rest_old
        bpy.context.view_layer.update()
        # The same turn, seen from inside the bone (for its animation keys).
        inside = rest_old.to_3x3().inverted() @ turn.to_3x3().inverted() @ rest_old.to_3x3()
        turns[name] = inside.to_quaternion()
    bpy.ops.pose.armature_apply(selected=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    log("arms down", round(math.degrees(drop)), "degrees")

    # Every animation's arm keys, turned to match the new rest.
    for action in bpy.data.actions:
        for name, d in turns.items():
            path = 'pose.bones["%s"].rotation_quaternion' % name
            curves = [action.fcurves.find(path, index=i) for i in range(4)]
            if any(c is None for c in curves):
                continue
            frames = sorted({k.co.x for c in curves for k in c.keyframe_points})
            values = []
            for f in frames:
                q = Quaternion([c.evaluate(f) for c in curves])
                values.append(d @ q)
            for f, q in zip(frames, values):
                for i, c in enumerate(curves):
                    c.keyframe_points.insert(f, q[i], options={"REPLACE", "FAST"})
            for c in curves:
                c.update()

    # --- 3. Bind her to the bones -----------------------------------------
    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")
    # The head and ears follow the head bone only.
    groups = {g.name: g for g in body.vertex_groups}
    head_group = groups.get("Head") or body.vertex_groups.new(name="Head")
    moved = 0
    for v in body.data.vertices:
        co = v.co
        is_head = co.z > NECK_Z + 0.01 or (abs(co.x) > EAR_SIDE_X and co.z > EAR_LOW_Z)
        if is_head:
            for g in v.groups:
                body.vertex_groups[g.group].remove([v.index])
            head_group.add([v.index], 1.0, "REPLACE")
            moved += 1
    unweighted = sum(1 for v in body.data.vertices if not v.groups)
    log("head and ears:", moved, "corners; unweighted:", unweighted)
    if unweighted:
        # Anything the automatic weights missed goes with the nearest bone.
        for v in body.data.vertices:
            if v.groups:
                continue
            best, best_d = None, 1e9
            for bone in arm.data.bones:
                if not bone.use_deform or bone.name.startswith("PoleTarget") or bone.name == "Bone":
                    continue
                a, b = bone.head_local, bone.tail_local
                ab = b - a
                t = max(0.0, min(1.0, (v.co - a).dot(ab) / max(ab.length_squared, 1e-9)))
                d = (v.co - (a + ab * t)).length
                if d < best_d:
                    best, best_d = bone.name, d
            (groups.get(best) or body.vertex_groups.new(name=best)).add([v.index], 1.0, "REPLACE")
            groups = {g.name: g for g in body.vertex_groups}

    # --- Out ----------------------------------------------------------------
    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    arm.select_set(True)
    bpy.ops.export_scene.gltf(
        filepath=OUTPUT, export_format="GLB", use_selection=True,
        export_animations=True, export_animation_mode="ACTIONS", export_force_sampling=True,
        export_apply=False, export_skins=True, export_yup=True)
    log("saved", OUTPUT, "with", len(bpy.data.actions), "animations")


if __name__ == "__main__":
    main()
