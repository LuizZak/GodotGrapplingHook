# Godot Grappling Hook

A simple grappling hook implementation in native Godot physics engine.

### Usage

There's two ways to create a grappling hook: Either using the `ChainManager` class or a `RopeNode` that wraps that in a more convenient manner.

If using the `RopeNode`, add it to a scene, and connect an appropriate `RigidBody2D` to serve as the head body of the chain, and use `rope_node.launch_rope(velocity)` to launch the grappling hook around.
