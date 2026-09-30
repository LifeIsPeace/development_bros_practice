class_name Ship
extends RigidBody3D


@export_category("Systems")

@export var thruster_manager: ThrusterManager


@export_category("Flight")

@export var flight_assist: bool = true

@export var angular_stabilization: float = 3.0

@export var lateral_stabilization: float = 1.0


@export_category("Flight Performance")

@export var forward_acceleration: float = 20.0
@export var braking_acceleration: float = 15.0

@export var pitch_torque: float = 5000.0
@export var yaw_torque: float = 5000.0
@export var roll_torque: float = 5000.0


@export_category("Gravity")

## Zero means true zero-G.
@export var gravity: Vector3 = Vector3.ZERO


var throttle_input: float = 0.0
var brake_input: float = 0.0

var pitch_input: float = 0.0
var yaw_input: float = 0.0
var roll_input: float = 0.0


func _ready() -> void:

	# We control gravity ourselves.
	gravity_scale = 0.0

	if thruster_manager == null:

		for child in get_children():

			if child is ThrusterManager:
				thruster_manager = child

				break


func set_flight_input(
	throttle: float,
	brake: float,
	pitch: float,
	yaw: float,
	roll: float
) -> void:

	throttle_input = clamp(throttle, 0.0, 1.0)
	brake_input = clamp(brake, 0.0, 1.0)

	pitch_input = clamp(pitch, -1.0, 1.0)
	yaw_input = clamp(yaw, -1.0, 1.0)
	roll_input = clamp(roll, -1.0, 1.0)


func _physics_process(_delta: float) -> void:

	if thruster_manager == null:
		return

	apply_flight_controls()

	apply_gravity()

	if flight_assist:
		apply_flight_assist()


func apply_flight_controls() -> void:

	# Convert desired acceleration into force.
	var desired_force := Vector3.ZERO

	# Godot forward = -Z.
	var forward := -global_transform.basis.z

	var right := global_transform.basis.x
	var up := global_transform.basis.y


	# Main engine.
	desired_force += (
		forward *
		throttle_input *
		mass *
		forward_acceleration
	)


	# -------------------------------------------------------
	# Braking.
	#
	# This is velocity-based rather than simply firing
	# arbitrary reverse engines.
	#
	# This means S actually opposes the ship's current
	# movement.
	# -------------------------------------------------------

	if brake_input > 0.0:

		var velocity := linear_velocity

		if velocity.length_squared() > 0.001:

			var braking_force := (
				-velocity.normalized() *
				mass *
				braking_acceleration *
				brake_input
			)

			desired_force += braking_force


	# Rotation.
	var desired_torque := Vector3.ZERO


	# Pitch rotates around local X.
	desired_torque += (
		right *
		pitch_input *
		pitch_torque
	)


	# Yaw rotates around local Y.
	desired_torque += (
		up *
		yaw_input *
		yaw_torque
	)


	# Roll rotates around local Z.
	desired_torque += (
		forward *
		roll_input *
		roll_torque
	)


	thruster_manager.request_wrench(
		desired_force,
		desired_torque
	)


func apply_gravity() -> void:

	if gravity.length_squared() < 0.000001:
		return

	apply_central_force(
		gravity * mass
	)


func apply_flight_assist() -> void:

	# Rotational stabilization.
	if angular_velocity.length_squared() > 0.000001:

		var stabilization := (
			-angular_velocity *
			angular_stabilization *
			mass
		)

		apply_torque(stabilization)


	# -------------------------------------------------------
	# Lateral velocity stabilization.
	#
	# This does NOT stop forward movement.
	# -------------------------------------------------------

	var local_velocity := (
		global_transform.basis.inverse() *
		linear_velocity
	)


	var lateral := Vector3(
		local_velocity.x,
		local_velocity.y,
		0.0
	)


	if lateral.length_squared() > 0.000001:

		var world_lateral := (
			global_transform.basis *
			lateral
		)

		apply_central_force(
			-world_lateral *
			lateral_stabilization *
			mass
		)
		
