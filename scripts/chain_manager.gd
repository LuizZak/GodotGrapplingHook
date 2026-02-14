class_name ChainManager

const LINK_RADIUS := 2.0

var head_body: RigidBody2D
var segments_container: Node2D
## Length of the link segment's capsule shape.
## Note: Only affect future instances of chain segments created.
var link_length: float = 30.0

## Mass for each individual link segment's body.
## Note: Only affect future instances of chain segments created.
var link_mass: float = 0.1

## The maximum number of chain segments to instantiate.
var max_length: int = 25

## The current chain tail segment.
var chain_tail: ChainSegment

## Gets a value specifying whether the chain is attached to the `head_body`.
var is_attached_to_head_body: bool = false

## Gets a value specifying whether the tip of the chain is attached to the world.
var is_attached_to_world: bool = false

## If `true`, negates the relative velocity of the chain links once it gets
## attached to the head body.
var negate_chain_velocity: bool = true

## Note: Only affect future instances of chain segments created.
var collision_layer: int
## Note: Only affect future instances of chain segments created.
var collision_mask: int

## Returns the number of chain link counts currently instantiated.
## Is zero, if the chain is not spawned (see `is_spawned()`).
var current_link_count: int:
    get:
        if chain_tail == null: return 0
        return chain_tail.length

## Stiffness of unspooling/rewinding spring.
var spring_stiffness: float = 6000.0
## Damping of unspooling/rewinding spring.
var spring_damping: float = 600.0

## Called when the rope has attached to the world, against a given body node,
## using a given pin joint.
signal on_attached_to_world(body: Node2D, joint: PinJoint2D)

## Called when the spooling process has begun, either by manually calling `spool()`,
## when the chain has been attached to a body in the world, or when
signal on_spool_started()

## Called when the spooling process has finished.
signal on_spool_ended()

@warning_ignore("shadowed_variable")
func _init(head_body: RigidBody2D, segments_container: Node2D) -> void:
    self.head_body = head_body
    self.segments_container = segments_container

## Gets the global position of the chain segments, useful for drawing purposes.
## If the chain is not spawned, an empty array is returned, instead.
func chain_segment_points() -> PackedVector2Array:
    var points := PackedVector2Array()
    if not is_spawned():
        return points

    points.append(head_body.global_position)

    var bodies := _chain_bodies()
    for body in bodies:
        points.append(body.global_position)

    return points

## Draws the chain as a polyline, with the circle at the end being a filled
## circle with `width + 2.0` radius.
func draw(node: Node2D, color: Color = Color.WHITE, width: float = -1, antialiased: bool = false) -> void:
    if not is_spawned():
        return

    var points := chain_segment_points()
    points = node.global_transform.inverse() * points

    node.draw_circle(points[-1], width + 2.0, color, width, true, antialiased)

    if points.size() >= 2:
        node.draw_polyline(points, color, width, antialiased)

func physics_process(delta: float) -> void:
    if is_attached_to_world or is_attached_to_head_body:
        _manage_spool()
    else:
        _manage_unspool()

    _manage_chain_head_attachment()

    if is_spawned():
        chain_tail.physics_process(delta)

## Returns `true` if there's chain segments currently instantiated in the world.
func is_spawned() -> bool:
    return chain_tail != null

## Gets the position of the tail chain segment, i.e. the last segment that was
## created.
func tail_position() -> Vector2:
    if is_spawned():
        return chain_tail.body.global_position

    return Vector2.ZERO

## Shoots a new chain at a given velocity in world space.
##
## This destroys any previously created chain.
func shoot_chain(velocity: Vector2) -> void:
    if velocity.is_zero_approx():
        return

    destroy_chain()

    var new_tail := _create_segment(head_body.global_position, velocity.angle())

    chain_tail = new_tail
    chain_tail.body.apply_central_impulse(head_body.linear_velocity * chain_tail.body.mass + velocity)
    chain_tail.enable_contact_monitor()

## Instantly destroys current chain.
func destroy_chain() -> void:
    if not is_spawned():
        return

    var current := chain_tail
    while current != null:
        current.destroy()
        current = current.next

    chain_tail = null
    is_attached_to_head_body = false
    is_attached_to_world = false

## Begins the spooling process of the current active chain.
## Prevents new chain segments from spawning, and starts pulling the head body
## towards the chain segments.
func start_spooling() -> void:
    if not is_spawned():
        return
    if is_attached_to_head_body:
        return

    _attach_to_head_body()
    on_spool_started.emit()

## Attaches the tail of the chain to the configured head body.
func _attach_to_head_body() -> void:
    chain_tail.spring_attach_to_head(head_body, spring_stiffness, spring_damping)
    is_attached_to_head_body = true
    if negate_chain_velocity:
        _negate_relative_velocity()

## Detects collisions between the chain head and the world, attaching the chain
## to the first contact point found.
func _manage_chain_head_attachment() -> void:
    if chain_tail == null:
        return
    if is_attached_to_world:
        return

    var head := chain_tail.find_head()
    if head.body.get_contact_count() >= 0:
        var chain_bodies := _chain_bodies()
        var bodies := head.body.get_colliding_bodies()
        for body in bodies:
            if chain_bodies.has(body):
                continue

            var pin_joint := head.attach_to_world(body)
            is_attached_to_world = true
            start_spooling()
            on_attached_to_world.emit(body, pin_joint)
            break

## Manages creation of chain links and unspooling behavior.
func _manage_unspool() -> void:
    if chain_tail == null:
        return
    if not is_attached_to_head_body:
        while chain_tail.distance_to(head_body.global_position) > link_length / 2.0:
            if chain_tail.length >= max_length:
                start_spooling()
                break
            else:
                var pos := chain_tail.position.move_toward(head_body.global_position, link_length / 2.0)
                var new_tail = _create_segment(pos, pos.angle_to_point(chain_tail.position))
                new_tail.next = chain_tail
                new_tail.body.apply_central_impulse(chain_tail.body.linear_velocity)
                chain_tail.attach_to_prev(new_tail)
                chain_tail = new_tail

## Manages spooling behavior, moving the head body through the chain.
func _manage_spool() -> void:
    if chain_tail == null:
        return
    if not (is_attached_to_world or is_attached_to_head_body):
        return

    chain_tail.spring_attach_to_head(head_body, spring_stiffness, spring_damping)
    chain_tail.spring_attach_next_to_head(head_body, spring_stiffness, spring_damping)

    var dist := chain_tail.body.global_position.distance_to(head_body.global_position)
    if dist <= _spool_test_distance():
        var next := chain_tail.next
        if next != null:
            next.detach()
            next.spring_attach_to_head(head_body, spring_stiffness, spring_damping)
            next.spring_attach_next_to_head(head_body, spring_stiffness, spring_damping)

            chain_tail.destroy()
            chain_tail = next
        else:
            destroy_chain()
            on_spool_ended.emit()

## When spooling, checks are made against this distance to detect if a link should
## be destroyed, and the next link attached to the head body in its place.
## In some cases, a higher tolerance distance is desired for the last few links
## as you need to consider the collision shape of the head body butting up against
## the place the rope is attached to.
func _spool_test_distance() -> float:
    if chain_tail.length <= 3:
        return link_length * 2.0
    return link_length

## Negates the relative velocity of all chain segments relative to the head body.
## Used to prevent the velocity of the chain from affecting the head body too
## much once they get attached physically to the head body.
func _negate_relative_velocity() -> void:
    var chain_segment := chain_tail
    while chain_segment != null:
        var rel_velocity := chain_segment.body.linear_velocity - head_body.linear_velocity
        chain_segment.body.apply_central_impulse(-rel_velocity * chain_segment.body.mass)

        chain_segment = chain_segment.next

## Returns an array containing each chain link segment body.
func _chain_bodies() -> Array[Node2D]:
    var result: Array[Node2D] = []
    var current := chain_tail
    while current != null:
        result.append(current.body)
        current = current.next
    return result

func _create_segment(pos: Vector2, rot: float) -> ChainSegment:
    var capsule := CapsuleShape2D.new()
    capsule.height = link_length
    capsule.radius = LINK_RADIUS

    var collision_shape := CollisionShape2D.new()
    collision_shape.shape = capsule

    var body := RigidBody2D.new()
    body.add_child(collision_shape)
    body.collision_layer = collision_layer
    body.collision_mask = collision_mask
    body.position = segments_container.to_local(pos)
    body.continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
    body.mass = link_mass
    body.rotation = -segments_container.global_rotation + rot + PI / 2.0

    var segment := ChainSegment.new()
    segment.body = body

    segments_container.add_child(body)

    return segment

class ChainSegment:
    ## Joint that attaches this chain segment to a previous chain segment, or to
    ## a body.
    var joint_to_prev: Joint2D
    ## Joint that attaches this chain segment to the world.
    var joint_to_world: Joint2D
    ## Spring joint that attaches this chain segment to a body. Used during unspooling
    ## to apply a force between the body and chain segment.
    var spring_joint_to_prev: CustomSpring
    ## The chain segment body.
    var body: RigidBody2D
    ## The next chain segment on the chain, if any.
    var next: ChainSegment
    ## Gets the length of this segment, based on the number of `next` segments
    ## available. Always greater than or equal to `1`.
    var length: int:
        get:
            if next == null:
                return 1
            return next.length + 1
    ## Gets the global position of the chain segment body.
    var position: Vector2:
        get: return body.global_position

    ## Updates the internal physics state of this chain segment, also updating
    ## the physics state of next chain segments in the sequence.
    func physics_process(delta: float) -> void:
        if spring_joint_to_prev != null:
            spring_joint_to_prev.physics_process(delta)
        if next != null:
            next.physics_process(delta)

    ## Destroys this chain segment's node references, invalidating the chain
    ## segment in the process.
    ##
    ## Does not destroy or modify `next`.
    func destroy() -> void:
        if joint_to_prev != null:
            joint_to_prev.queue_free()
            joint_to_prev = null
        if joint_to_world != null:
            joint_to_world.queue_free()
            joint_to_world = null
        if body != null:
            body.queue_free()
            body = null

    ## Recursively searches for the head of the chain, by finding the first chain
    ## segment with a null `next`.
    func find_head() -> ChainSegment:
        if next == null:
            return self
        return next.find_head()

    func distance_to(point: Vector2) -> float:
        return position.distance_to(point)

    func enable_contact_monitor() -> void:
        body.contact_monitor = true
        body.max_contacts_reported = 16

    func is_attached_to_previous() -> bool:
        return joint_to_prev != null

    func is_spring_attached() -> bool:
        return spring_joint_to_prev != null

    func detach() -> void:
        joint_to_prev.queue_free()
        joint_to_prev = null

    func attach_to_prev(segment: ChainSegment):
        var mid_point := (body.global_position + segment.body.global_position) / 2.0

        var pin_joint := PinJoint2D.new()
        pin_joint.node_a = segment.body.get_path()
        pin_joint.node_b = body.get_path()
        pin_joint.position = body.to_local(mid_point)
        body.add_child(pin_joint)
        joint_to_prev = pin_joint

    func attach_to_world(world_node: Node2D) -> PinJoint2D:
        var pin_joint := PinJoint2D.new()
        pin_joint.node_a = world_node.get_path()
        pin_joint.node_b = body.get_path()
        body.add_child(pin_joint)
        joint_to_world = pin_joint
        return pin_joint

    func spring_attach_to_head(head: Node2D, spring_k: float, spring_d: float) -> void:
        var spring := CustomSpring.new(
            body, Transform2D.IDENTITY,
            head, Transform2D.IDENTITY,
            0.0,
            spring_k,
            spring_d
        )
        spring_joint_to_prev = spring

    func spring_attach_next_to_head(head: Node2D, spring_k: float, spring_d: float) -> void:
        if next != null:
            next.spring_attach_to_head(head, spring_k, spring_d)
