extends SceneTree
## Headless harita kurma testi.
## godot --headless --path RideX -s res://tools/build_map.gd

func _initialize() -> void:
    var script = load("res://scripts/world/map_importer.gd")
    if script == null:
        print("[build_map] importer yuklenemedi")
        quit(1)
        return
    var imp = script.new()
    imp.base_path = OS.get_environment("MAP_BASE") if OS.has_environment("MAP_BASE") else "res://assets/projeto/"
    var m := 50
    if OS.has_environment("MAP_MAX"):
        m = int(OS.get_environment("MAP_MAX"))
    imp.max_objects = m
    imp.verbose = true
    imp.collision = OS.has_environment("MAP_COLLISION")

    var t0 := Time.get_ticks_msec()
    var st = imp.build()
    var dt := Time.get_ticks_msec() - t0
    print("[build_map] limit=", m, " stats=", st, " ms=", dt)
    imp.free()
    quit(0)
