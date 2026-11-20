extends Camera3D
## Motosikleti takip eden kamera.

var target: Node3D
var dist := 7.0
var height := 3.0


func _process(delta: float) -> void:
    if target == null:
        return
    var back := target.global_transform.basis.z.normalized() * dist
    var desired := target.global_position + back + Vector3.UP * height
    global_position = global_position.lerp(desired, 1.0 - exp(-6.0 * delta))
    look_at(target.global_position + Vector3.UP, Vector3.UP)
