class_name PhysicsUtils

## Returns the velocity at a given offset point from a collision object's center
## of mass.
static func get_point_velocity(obj: CollisionObject2D, offset: Vector2) -> Vector2:
    var state := PhysicsServer2D.body_get_direct_state(obj.get_rid())
    if state == null:
        return Vector2.ZERO

    return state.get_velocity_at_local_position(offset)

## Returns the velocity at a given offset point from a collision object's center
## of mass.
static func get_point_velocity_global(obj: CollisionObject2D, global_point: Vector2) -> Vector2:
    return get_point_velocity(obj, obj.to_local(global_point))

## Calculates a spring force, given position, velocity, spring constant, and
## damping factor
static func calculate_spring_force(
    pos_a: Vector2, vel_a: Vector2,
    pos_b: Vector2, vel_b: Vector2,
    distance: float,
    spring_k: float,
    spring_d: float
) -> Vector2:
    var dist := pos_a.distance_to(pos_b)

    if dist <= 0.0000005:
        return Vector2.ZERO

    var b_to_a := (pos_a - pos_b) / dist

    dist = distance - dist

    var rel_vel := vel_a - vel_b
    var total_rel_vel := rel_vel.dot(b_to_a)

    return b_to_a * ((dist * spring_k) - (total_rel_vel * spring_d))
