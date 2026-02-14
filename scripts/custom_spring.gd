class_name CustomSpring

var body_a: Node2D
var transform_a: Transform2D
var body_b: Node2D
var transform_b: Transform2D

var rest_length: float
var stiffness: float
var damping: float

@warning_ignore("shadowed_variable")
func _init(
    body_a: Node2D,
    transform_a: Transform2D,
    body_b: Node2D,
    transform_b: Transform2D,
    rest_length: float,
    stiffness: float,
    damping: float,
) -> void:
    self.body_a = body_a
    self.transform_a = transform_a
    self.body_b = body_b
    self.transform_b = transform_b
    self.rest_length = rest_length
    self.stiffness = stiffness
    self.damping = damping

func is_valid() -> bool:
    return is_instance_valid(body_a) and is_instance_valid(body_b)

func draw(node: Node2D) -> void:
    if not is_valid():
        return

    var local_a := node.to_local(attachment_a())
    var local_b := node.to_local(attachment_b())

    node.draw_line(local_a, local_b, Color.GREEN_YELLOW, 1.0, true)

func physics_process(delta: float) -> void:
    if not is_valid():
        return

    var force := PhysicsUtils.calculate_spring_force(
        attachment_a(), velocity_a(),
        attachment_b(), velocity_b(),
        rest_length,
        stiffness,
        damping,
    )

    apply_force_a(force * delta)
    apply_force_b(-force * delta)

func attachment_a() -> Vector2:
    return (body_a.global_transform * transform_a).origin

func velocity_a() -> Vector2:
    if body_a is RigidBody2D or body_a is AnimatableBody2D:
        return PhysicsUtils.get_point_velocity(body_a, transform_a.origin)
    return Vector2.ZERO

func apply_force_a(force: Vector2) -> void:
    if body_a is RigidBody2D:
        body_a.apply_force(force, body_a.to_local(attachment_a()))

func attachment_b() -> Vector2:
    return (body_b.global_transform * transform_b).origin

func velocity_b() -> Vector2:
    if body_b is RigidBody2D or body_b is AnimatableBody2D:
        return PhysicsUtils.get_point_velocity(body_b, transform_b.origin)
    return Vector2.ZERO

func apply_force_b(force: Vector2) -> void:
    if body_b is RigidBody2D:
        body_b.apply_force(force, body_b.to_local(attachment_b()))
