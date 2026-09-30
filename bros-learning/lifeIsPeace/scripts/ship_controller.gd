class_name ShipController
extends Node


@export var ship: Ship

@export_category("Flight")

## Forward acceleration in m/s².
@export var forward_acceleration: float = 20.0

## Maximum acceleration while braking.
@export var braking_acceleration: float = 15.0


@export_category("Rotation")

## Desired angular acceleration.
@export var pitch_torque: float = 5000.0
@export var yaw_torque: float = 5000.0
@export var roll_torque: float = 5000.0


@export_category("Input")

@export var input_smoothing: float = 5.0


var throttle: float = 0.0
var brake: float = 0.0

var pitch: float = 0.0
var yaw: float = 0.0
var roll: float = 0.0


func _ready() -> void:

	if ship == null:
		ship = get_parent() as Ship


func _physics_process(delta: float) -> void:

	if ship == null:
		return

	read_input(delta)

	ship.set_flight_input(
		throttle,
		brake,
		pitch,
		yaw,
		roll
	)


func read_input(delta: float) -> void:

	var target_throttle := Input.get_action_strength(
		"throttle"
	)

	var target_brake := Input.get_action_strength(
		"brake"
	)


	var target_pitch := Input.get_axis(
		"pitch_down",
		"pitch_up"
	)

	var target_yaw := Input.get_axis(
		"yaw_left",
		"yaw_right"
	)

	var target_roll := Input.get_axis(
		"roll_left",
		"roll_right"
	)


	throttle = move_toward(
		throttle,
		target_throttle,
		input_smoothing * delta
	)

	brake = move_toward(
		brake,
		target_brake,
		input_smoothing * delta
	)

	pitch = move_toward(
		pitch,
		target_pitch,
		input_smoothing * delta
	)

	yaw = move_toward(
		yaw,
		target_yaw,
		input_smoothing * delta
	)

	roll = move_toward(
		roll,
		target_roll,
		input_smoothing * delta
	)
