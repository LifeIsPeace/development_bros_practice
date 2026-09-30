## This is for planets' local gravity.
class_name GravitySource
extends Node3D

@export_category("Gravity")

@export var gravity_strength: float = 9.81

@export var influence_radius: float = 1000.0

@export var falloff_enabled: bool = true


func get_gravity_at(
	position: Vector3
) -> Vector3:

	var offset := global_position - position

	var distance := offset.length()

	if distance <= 0.001:
		return Vector3.ZERO

	if distance > influence_radius:
		return Vector3.ZERO

	var direction := offset.normalized()

	var radius_ratio := (
		influence_radius / distance
	)

	var strength := gravity_strength * (
		radius_ratio * radius_ratio
	)

	return direction * strength
	
