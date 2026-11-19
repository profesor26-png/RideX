import json, os, sys, math

BASE = r"C:\Users\User\Desktop\RideX\assets\projeto"
MD = os.path.join(BASE, "assets", "meshes")
TD = os.path.join(BASE, "assets", "textures")

def main():
    mp = os.path.join(BASE, "map_manifest.json")
    matp = os.path.join(BASE, "materials.json")
    if not os.path.exists(mp):
        print("FATAL: map_manifest.json yok"); return 1
    man = json.load(open(mp, encoding="utf-8"))
    mats = json.load(open(matp, encoding="utf-8")) if os.path.exists(matp) else {}
    objs = man.get("objects", [])
    if not objs:
        print("FATAL: manifest bos"); return 1

    enabled = [o for o in objs if o.get("enabled", True) and o.get("mesh")]
    mesh_missing = 0
    mat_missing = 0
    tex_missing = 0
    checked_mats = set()
    combined = 0
    scaled_out = 0
    for o in enabled:
        mf = o["mesh"]
        if mf.startswith("Combined_Mesh"):
            combined += 1
        if not os.path.exists(os.path.join(MD, mf)):
            mesh_missing += 1
        for mn in o.get("materials", []):
            if not mn or mn in checked_mats:
                continue
            checked_mats.add(mn)
            d = mats.get(mn)
            if not d:
                mat_missing += 1
                continue
            t = d.get("tex")
            if t and not os.path.exists(os.path.join(TD, t)):
                tex_missing += 1
        m = o.get("m")
        if m and len(m) >= 16:
            sx = math.sqrt(m[0] ** 2 + m[4] ** 2 + m[8] ** 2)
            sy = math.sqrt(m[1] ** 2 + m[5] ** 2 + m[9] ** 2)
            sz = math.sqrt(m[2] ** 2 + m[6] ** 2 + m[10] ** 2)
            if max(sx, sy, sz) > 10.0:
                scaled_out += 1

    total_mats = len(checked_mats)
    matched = total_mats - mat_missing
    print("=== HARITA DOGRULAMA ===")
    print(f"obje           : {len(objs)}  (aktif+mesh: {len(enabled)})")
    print(f"combined        : {combined}")
    print(f"mesh eksik      : {mesh_missing}")
    print(f"materyal        : {total_mats}  eslesen: {matched}  eksik: {mat_missing}")
    print(f"texture eksik   : {tex_missing}")
    print(f"scale>10 (atlanir): {scaled_out}")

    ok = True
    if mesh_missing > 0:
        print("HATA: eksik mesh dosyalari var"); ok = False
    if total_mats > 0 and (matched / total_mats) < 0.8:
        print("HATA: materyal eslesmesi %80 altinda"); ok = False
    if tex_missing > max(5, total_mats // 10):
        print("UYARI: cok fazla eksik texture")
    print("SONUC:", "GECTI" if ok else "KALDI")
    return 0 if ok else 1

sys.exit(main())
