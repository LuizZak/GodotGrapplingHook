extends Node2D

const LAUNCH_FORCE := 10000.0

@onready
var rigid_body_2d: RigidBody2D = $RigidBody2D

@onready
var rope_node: RopeNode = %RopeNode

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
        var direction := get_global_mouse_position() - rigid_body_2d.global_position

        rope_node.launch_rope(direction.normalized() * LAUNCH_FORCE)
