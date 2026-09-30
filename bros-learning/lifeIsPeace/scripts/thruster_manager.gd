class_name ThrusterManager
extends Node


@export_category("Ship")

@export var ship: RigidBody3D


@export_category("Allocator")

## Number of optimization passes performed every physics frame.
##
## More iterations = better allocation but slightly more CPU usage.
@export_range(1, 20, 1)
var solver_iterations: int = 6


## How much translation matters relative to rotation.
@export var translation_weight: float = 1.0


## How much rotation matters relative to translation.
@export var rotation_weight: float = 1.0


## Prevents tiny thrusters from constantly flickering.
@export_range(0.0, 0.1, 0.001)
var minimum_throttle: float = 0.01


var thrusters: Array[Thruster] = []


func _ready() -> void:

	if ship == null:
		ship = get_parent() as RigidBody3D

	refresh_thrusters()


func refresh_thrusters() -> void:

	thrusters.clear()

	var nodes := find_children(
		"*",
		"Thruster",
		true,
		false
	)

	for node in nodes:
		if node is Thruster:
			thrusters.append(node as Thruster)


func get_thruster_count() -> int:
	return thrusters.size()


# MAIN API
## Requests a force and torque from the thruster system.
##
## Both vectors are expressed in WORLD coordinates.
##
## The manager automatically determines which thrusters should fire.
func request_wrench(
	desired_force: Vector3,
	desired_torque: Vector3
) -> void:

	if ship == null:
		return

	if thrusters.is_empty():
		return

	var solution := solve_thrusters(
		desired_force,
		desired_torque
	)

	for i in range(thrusters.size()):

		var thruster := thrusters[i]

		if not thruster.enabled:
			thruster.set_throttle(0.0)
			continue

		var value := solution[i]

		if value < minimum_throttle:
			value = 0.0

		thruster.set_throttle(value)

		apply_thruster_force(thruster)


func apply_thruster_force(
	thruster: Thruster
) -> void:

	var force := thruster.get_force()

	if force.length_squared() < 0.000001:
		return

	var relative_position := (
		thruster.global_position -
		ship.global_position
	)

	ship.apply_force(
		force,
		relative_position
	)


# THRUSTER SOLVER
## Calculates the throttle of every thruster required to approximate
## the requested six-dimensional force/torque vector.
##
## This is a small constrained iterative solver:
##
##  force X
##  force Y
##  force Z
##  torque X
##  torque Y
##  torque Z
##
## Each thruster can only produce positive thrust from 0 -> 1.
func solve_thrusters(
	desired_force: Vector3,
	desired_torque: Vector3
) -> Array[float]:

	var count := thrusters.size()

	var result: Array[float] = []

	for i in range(count):
		result.append(0.0)


	# Calculate scaling values.
	var max_force := 0.0
	var max_torque := 0.0

	for thruster in thrusters:

		if not thruster.enabled:
			continue

		max_force += thruster.max_force

		var radius := (
			thruster.global_position -
			ship.global_position
		).length()

		max_torque += thruster.max_force * radius

	max_force = max(max_force, 1.0)
	max_torque = max(max_torque, 1.0)


	# ------------------------
	# Normalize requested wrench.
	#
	# This prevents force and torque units from fighting
	# each other numerically.
	# -----------------------

	var target := PackedFloat64Array([
		desired_force.x / max_force,
		desired_force.y / max_force,
		desired_force.z / max_force,

		desired_torque.x / max_torque,
		desired_torque.y / max_torque,
		desired_torque.z / max_torque
	])

	# Build normalized contribution for every thruster.
	var contributions: Array[PackedFloat64Array] = []

	for thruster in thrusters:

		var force := thruster.get_thrust_direction() * \
		(thruster.max_force / max_force)

		var radius := (
			thruster.global_position -
			ship.global_position
		)

		var torque := radius.cross(
			thruster.get_thrust_direction() *
			thruster.max_force
		) / max_torque


		var contribution := PackedFloat64Array([
			force.x,
			force.y,
			force.z,

			torque.x,
			torque.y,
			torque.z
		])

		contributions.append(contribution)


	# Weight force vs torque.
	for i in range(3):
		target[i] *= translation_weight

	for i in range(3, 6):
		target[i] *= rotation_weight

	for contribution in contributions:

		for i in range(3):
			contribution[i] *= translation_weight

		for i in range(3, 6):
			contribution[i] *= rotation_weight


	# Iterative coordinate-descent solver.
	for iteration in range(solver_iterations):

		for i in range(count):

			var thruster := thrusters[i]

			if not thruster.enabled:
				continue

			var contribution := contributions[i]

			# Calculate current reconstructed wrench.
			var current := PackedFloat64Array([
				0.0,
				0.0,
				0.0,
				0.0,
				0.0,
				0.0
			])

			for j in range(count):

				var throttle := result[j]

				if throttle <= 0.0:
					continue

				for k in range(6):
					current[k] += (
						contributions[j][k] *
						throttle
					)


			# Residual error.
			var residual := PackedFloat64Array([
				target[0] - current[0],
				target[1] - current[1],
				target[2] - current[2],
				target[3] - current[3],
				target[4] - current[4],
				target[5] - current[5]
			])


			# Find how much this thruster contributes
			# to reducing the residual.
			var numerator := 0.0
			var denominator := 0.0

			for k in range(6):

				numerator += (
					residual[k] *
					contribution[k]
				)

				denominator += (
					contribution[k] *
					contribution[k]
				)


			if denominator <= 0.0000001:
				continue


			var delta := numerator / denominator

			result[i] = clamp(
				result[i] + delta,
				0.0,
				1.0
			)


	# Final cleanup.
	for i in range(result.size()):

		if not thrusters[i].enabled:
			result[i] = 0.0

		result[i] = clamp(
			result[i],
			0.0,
			1.0
		)

	return result
