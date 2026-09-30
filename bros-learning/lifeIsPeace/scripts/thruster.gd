## Thruster nodes are not physical objects. They are logical attachment points.
##
class_name Thruster
extends Node3D


@export_category("Thruster")

## Maximum physical thrust in Newtons.
@export var max_force: float = 1000.0

## The direction the THRUST force travels.
##
## By default this is -Z, Godot's forward direction.
##
## IMPORTANT:
## This is the direction the ship is PUSHED.
## It is NOT the direction the exhaust travels.
@export var local_thrust_direction: Vector3 = Vector3.FORWARD

## Allows temporarily disabling a thruster.
@export var enabled: bool = true


var throttle: float = 0.0


func get_thrust_direction() -> Vector3:
	var direction := global_transform.basis * local_thrust_direction

	if direction.length_squared() < 0.000001:
		return Vector3.ZERO

	return direction.normalized()


func get_force() -> Vector3:
	if not enabled:
		return Vector3.ZERO

	return get_thrust_direction() * max_force * throttle


func set_throttle(value: float) -> void:
	throttle = clamp(value, 0.0, 1.0)
