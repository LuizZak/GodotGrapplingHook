class_name RenderingCollisionShape2D
extends CollisionShape2D

func _draw() -> void:
    # CapsuleShape2D
    if shape is CapsuleShape2D:
        var top: float = -shape.mid_height / 2.0
        var bottom: float = shape.mid_height / 2.0
        var rect := Rect2(-shape.radius, top, shape.radius * 2, bottom - top)

        draw_circle(Vector2(0.0, top), shape.radius, Color.WHITE, true)
        draw_rect(rect, Color.WHITE, true)
        draw_circle(Vector2(0.0, bottom), shape.radius, Color.WHITE, true)
    # CircleShape2D
    elif shape is CircleShape2D:
        draw_circle(Vector2.ZERO, shape.radius, Color.WHITE, true)
        draw_line(Vector2.ZERO, Vector2(shape.radius, 0.0), Color.LIGHT_GRAY, 2, true)
    else:
        # ConcavePolygonShape2D
        # ConvexPolygonShape2D
        # RectangleShape2D
        # SegmentShape2D
        # SeparationRayShape2D
        # WorldBoundaryShape2D
        shape.draw(self.get_canvas_item(), Color.WHITE)
