"""Slims the developer's AI-made models (Python 3 + Pillow: "pip install pillow").

Every model from Meshy comes with three 2048 x 2048 pictures: its colors, a
"metal and roughness" map and a "bumps" (normal) map. A PS1-style game
renders at a tiny resolution with flat, matte shading, so it uses none of
that detail: it just makes the project huge and eats graphics memory.

For each .glb in art/models/ and assets/characters/, this:
  - keeps only the color picture (and a glow picture, if it has one),
    shrunk to SIZE pixels (BIG_SIZE for the few models you see up close),
  - drops the metal/roughness, bump and shadow maps, and makes the
    material plain and matte (not metal: without its map a "metal" model
    would look dark and shiny),
  - rewrites the file in place. Running it again on a slim file is a no-op.

Afterwards, delete the old unpacked pictures next to each model
(<name>_0.jpg, _1.jpg, _2.jpg and their .import files) and let Godot
reimport: it unpacks the new, small color picture.

Run it from the project folder:
    python3 tools/slim_models.py            # slim everything
    python3 tools/slim_models.py --check    # just list what would change
"""
import glob
import io
import json
import os
import struct
import sys

from PIL import Image

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FOLDERS = [os.path.join(HERE, "art", "models"), os.path.join(HERE, "assets", "characters")]
## The color picture's biggest side, in pixels.
SIZE = 512
## ...and for the models you see big and close (whole stations filling the
## window, Jacki's room).
BIG_SIZE = 1024
BIG = {"jacki_room", "truck_stop_station", "nebula_jackpot_casino", "gas_n_go_station"}
JPEG_QUALITY = 88


def read_glb(path):
    data = open(path, "rb").read()
    magic, version, _length = struct.unpack("<III", data[:12])
    if magic != 0x46546C67:
        raise ValueError("not a .glb")
    offset = 12
    doc, binary = None, b""
    while offset < len(data):
        size, kind = struct.unpack("<II", data[offset:offset + 8])
        chunk = data[offset + 8:offset + 8 + size]
        if kind == 0x4E4F534A:
            doc = json.loads(chunk.decode("utf-8"))
        elif kind == 0x004E4942:
            binary = chunk
        offset += 8 + size
    return doc, binary


def write_glb(path, doc, binary):
    text = json.dumps(doc, separators=(",", ":")).encode("utf-8")
    text += b" " * (-len(text) % 4)
    binary += b"\0" * (-len(binary) % 4)
    total = 12 + 8 + len(text) + 8 + len(binary)
    with open(path, "wb") as out:
        out.write(struct.pack("<III", 0x46546C67, 2, total))
        out.write(struct.pack("<II", len(text), 0x4E4F534A))
        out.write(text)
        out.write(struct.pack("<II", len(binary), 0x004E4942))
        out.write(binary)


def view_bytes(doc, binary, index):
    view = doc["bufferViews"][index]
    start = view.get("byteOffset", 0)
    return binary[start:start + view["byteLength"]]


def slim(path, check_only):
    name = os.path.splitext(os.path.basename(path))[0]
    folder = os.path.basename(os.path.dirname(path))
    limit = BIG_SIZE if name in BIG or folder in BIG else SIZE
    doc, binary = read_glb(path)
    images = doc.get("images", [])
    textures = doc.get("textures", [])
    # 1. Matte materials with only color (and glow) pictures.
    keep_textures = set()
    changed = False
    for material in doc.get("materials", []):
        for key in ("normalTexture", "occlusionTexture"):
            if key in material:
                del material[key]
                changed = True
        pbr = material.setdefault("pbrMetallicRoughness", {})
        if "metallicRoughnessTexture" in pbr:
            del pbr["metallicRoughnessTexture"]
            changed = True
        if pbr.get("metallicFactor", 1.0) != 0.0 or pbr.get("roughnessFactor", 1.0) != 1.0:
            pbr["metallicFactor"] = 0.0
            pbr["roughnessFactor"] = 1.0
            changed = True
        for holder, key in ((pbr, "baseColorTexture"), (material, "emissiveTexture")):
            if key in holder:
                keep_textures.add(holder[key]["index"])
    # 2. Shrink the pictures still in use.
    keep_images = sorted({textures[t]["source"] for t in keep_textures if "source" in textures[t]})
    new_pictures = {}
    for index in keep_images:
        image = images[index]
        raw = view_bytes(doc, binary, image["bufferView"])
        picture = Image.open(io.BytesIO(raw))
        if max(picture.size) <= limit and len(keep_images) == len(images):
            continue
        if max(picture.size) > limit:
            scale = limit / max(picture.size)
            picture = picture.resize((max(1, round(picture.width * scale)), max(1, round(picture.height * scale))), Image.LANCZOS)
        out = io.BytesIO()
        if picture.mode in ("RGBA", "LA", "P") and image.get("mimeType") == "image/png":
            picture.save(out, "PNG", optimize=True)
            new_pictures[index] = (out.getvalue(), "image/png")
        else:
            picture.convert("RGB").save(out, "JPEG", quality=JPEG_QUALITY, optimize=True)
            new_pictures[index] = (out.getvalue(), "image/jpeg")
        changed = True
    if len(keep_images) != len(images):
        changed = True
    if not changed:
        return 0, 0
    before = os.path.getsize(path)
    if check_only:
        return before, -1
    # 3. Rebuild: the kept images (renumbered), their textures, and a new
    # binary chunk without the dropped pictures' bytes.
    image_map = {old: new for new, old in enumerate(keep_images)}
    texture_map = {}
    new_textures = []
    for old, texture in enumerate(textures):
        if old in keep_textures and texture.get("source") in image_map:
            texture = dict(texture, source=image_map[texture["source"]])
            texture_map[old] = len(new_textures)
            new_textures.append(texture)
    for material in doc.get("materials", []):
        pbr = material.get("pbrMetallicRoughness", {})
        for holder, key in ((pbr, "baseColorTexture"), (material, "emissiveTexture")):
            if key in holder:
                holder[key]["index"] = texture_map[holder[key]["index"]]
    dropped_views = {images[i]["bufferView"] for i in range(len(images)) if i not in image_map}
    replaced = {images[i]["bufferView"]: new_pictures[i] for i in new_pictures}
    view_map = {}
    new_views = []
    chunk = bytearray()
    for old, view in enumerate(doc.get("bufferViews", [])):
        if old in dropped_views:
            continue
        payload = replaced[old][0] if old in replaced else view_bytes(doc, binary, old)
        chunk += b"\0" * (-len(chunk) % 4)
        view = dict(view, byteOffset=len(chunk), byteLength=len(payload))
        chunk += payload
        view_map[old] = len(new_views)
        new_views.append(view)
    for accessor in doc.get("accessors", []):
        if "bufferView" in accessor:
            accessor["bufferView"] = view_map[accessor["bufferView"]]
        sparse = accessor.get("sparse")
        if sparse:
            sparse["indices"]["bufferView"] = view_map[sparse["indices"]["bufferView"]]
            sparse["values"]["bufferView"] = view_map[sparse["values"]["bufferView"]]
    new_images = []
    for old in keep_images:
        image = dict(images[old], bufferView=view_map[images[old]["bufferView"]])
        if old in new_pictures:
            image["mimeType"] = new_pictures[old][1]
        new_images.append(image)
    doc["images"] = new_images
    doc["textures"] = new_textures
    doc["bufferViews"] = new_views
    doc["buffers"] = [{"byteLength": len(chunk)}]
    write_glb(path, doc, bytes(chunk))
    return before, os.path.getsize(path)


def main():
    check_only = "--check" in sys.argv
    paths = []
    for folder in FOLDERS:
        paths += glob.glob(os.path.join(folder, "**", "*.glb"), recursive=True)
    total_before = total_after = 0
    for path in sorted(paths):
        before, after = slim(path, check_only)
        if before:
            total_before += before
            total_after += max(after, 0)
            note = "would slim" if after < 0 else "%.1f MB -> %.1f MB" % (before / 1048576, after / 1048576)
            print("%-50s %s" % (os.path.relpath(path, HERE), note))
    if total_before and not check_only:
        print("Total: %.0f MB -> %.0f MB" % (total_before / 1048576, total_after / 1048576))
    elif not total_before:
        print("Everything's already slim.")


if __name__ == "__main__":
    main()
