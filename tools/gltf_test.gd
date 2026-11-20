extends SceneTree

func _initialize() -> void:
    var path := "C:/Users/User/Desktop/ios moto crck/unity_primary/Assets/SceneHierarchyObject/Demo Scene.glb"
    var t0 := Time.get_ticks_msec()
    var doc := GLTFDocument.new()
    var state := GLTFState.new()
    var err := doc.append_from_file(path, state)
    var t1 := Time.get_ticks_msec()
    print("[gltf] append err=", err, " ms=", t1 - t0)
    if err == OK:
        var scene := doc.generate_scene(state)
        var t2 := Time.get_ticks_msec()
        print("[gltf] scene=", scene, " children=", scene.get_child_count() if scene else -1, " ms=", t2 - t1, " total=", t2 - t0)
    quit(0)
