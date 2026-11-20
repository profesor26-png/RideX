extends SceneTree

func _initialize() -> void:
    var ps = load("res://assets/scene/demo.glb")
    if ps == null:
        print("[scene] LOAD FAIL")
        quit(1)
        return
    var root = ps.instantiate()
    get_root().add_child(root)
    var nodes := 0
    var meshes := 0
    var aabb := AABB()
    var first := true
    var stack: Array = [root]
    while not stack.is_empty():
        var n = stack.pop_back()
        nodes += 1
        if n is MeshInstance3D:
            meshes += 1
            var wb: AABB = n.global_transform * n.get_aabb()
            if first:
                aabb = wb
                first = false
            else:
                aabb = aabb.merge(wb)
        for c in n.get_children():
            stack.append(c)
    print("[scene] nodes=", nodes, " meshes=", meshes)
    if not first:
        print("[scene] aabb center=", aabb.get_center(), " size=", aabb.size)
    root.free()
    quit(0)
