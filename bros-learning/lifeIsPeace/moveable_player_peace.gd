extends CharacterBody3D

# How fast the player moves in meters per second
@export var speed = 30
# Downward acceleration while in air
@export var fall_acceleration = 500

# For camera -----
@onready var _camera := %Camera3D as Camera3D
@onready var _camera_pivot := %CameraPivot as Node3D

@export_range(0.0, 1.0) var mouse_sensitivity = 0.005
@export var tilt_limit = deg_to_rad(75)
# ---------


var target_velocity = Vector3.ZERO

func _ready() -> void:
	print(self.name)
	print(_camera_pivot)
	
func _process(delta: float) -> void:
	pass

# _process runs as fast as possible while _physics_process runs at the
# game's frame rate (I believe)
func _physics_process(delta: float) -> void:
	# Local variable to store input direction. Note that vector3 has 
	# properties x, y, and z
	var direction = Vector3.ZERO
	
	# Check for each move input and update direction accordingly
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_back"):
		direction.z += 1
	if Input.is_action_pressed("move_forward"):
		direction.z -= 1
	if Input.is_action_pressed("move_down"):
		direction.y -= 1
	if Input.is_action_pressed("move_up"):
		direction.y += 1
		
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		
	# Ground Velocity
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed
	target_velocity.y = direction.y * speed
	
	# Vertical Velocity
	if not is_on_floor():
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)
	
	# Moving the character
	velocity = target_velocity
	move_and_slide()
	
func _unhandled_input(event: InputEvent) -> void:
	# Mouselook implemented using `screen_relative` for resolution-independent sensitivity.
	if event is InputEventMouseMotion:
		# Make sure to enable the "Access as unique name" in the "CameraPivot" node
		_camera_pivot.rotation.x -= event.screen_relative.y * mouse_sensitivity
		# Prevent the camera from rotating too far up or down.
		_camera_pivot.rotation.x = clampf(_camera_pivot.rotation.x, -tilt_limit, tilt_limit)
		_camera_pivot.rotation.y += -event.screen_relative.x * mouse_sensitivity
