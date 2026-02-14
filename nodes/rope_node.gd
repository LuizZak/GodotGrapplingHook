## A grappling hook/rope node that attaches to a rigid body parent node.
##
## This node serves as a convenience for the lower-level `ChainManager` class.
@icon("res://nodes/rope_node.svg")
class_name RopeNode
extends Node2D

## Called when the rope has attached to the world, against a given body node,
## using a given pin joint.
signal on_attached_to_world(body: Node2D, joint: PinJoint2D)

## Called when the spooling process has begun, either by manually calling `spool()`,
## when the rope has been attached to a body in the world, or when
signal on_spool_started()

## Called when the spooling process has finished.
signal on_spool_ended()

## The head body, or body that the rope will be attached to when launched.
@export_node_path("RigidBody2D")
var head_body: NodePath

## The collision layer for the rope segments.
@export_flags_2d_physics
var collision_layer: int:
    set(value):
        collision_layer = value
        _set_collision_layer(value)

## The collision mask for the rope segments.
@export_flags_2d_physics
var collision_mask: int:
    set(value):
        collision_mask = value
        _set_collision_mask(value)

var chain_manager: ChainManager

func _ready() -> void:
    if _get_head_node() == null:
        push_error("Expected 'head_body' to be a valid path to a RigidBody2D!")

    chain_manager = ChainManager.new(_get_head_node(), self)
    chain_manager.on_attached_to_world.connect(
        func (body, joint):
            on_attached_to_world.emit(body, joint)
    )
    chain_manager.on_spool_started.connect(
        func (): on_spool_started.emit()
    )
    chain_manager.on_spool_ended.connect(
        func (): on_spool_ended.emit()
    )
    _set_collision_layer(collision_layer)
    _set_collision_mask(collision_mask)

func _draw() -> void:
    chain_manager.draw(self, Color.WHITE, 3.0, true)

func _physics_process(delta: float) -> void:
    chain_manager.physics_process(delta)
    queue_redraw()

func _set_collision_layer(layer: int):
    if chain_manager != null:
        chain_manager.collision_layer = layer

func _set_collision_mask(mask: int):
    if chain_manager != null:
        chain_manager.collision_mask = mask

## Launches the rope from the head body with a given velocity.
##
## This destroys any previously created chain.
func launch_rope(velocity: Vector2) -> void:
    chain_manager.shoot_chain(velocity)

## Returns `true` if there's rope segments currently instantiated in the world.
func is_spawned() -> bool:
    return chain_manager.is_spawned()

## Gets the global position of the tail rope segment, i.e. the last segment that
## was created.
##
## If the rope is not instantiated, returns `Vector2.ZERO`, instead.
func tail_position() -> Vector2:
    return chain_manager.tail_position()

## Destroys currently spawned rope.
func destroy_rope() -> void:
    chain_manager.destroy_chain()

## If the rope is currently spanwed, starts spooling it back.
func start_spooling() -> void:
    chain_manager.start_spooling()

func _get_head_node() -> RigidBody2D:
    return get_node(head_body)
