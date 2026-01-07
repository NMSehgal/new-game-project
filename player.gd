extends CharacterBody2D

signal player_moving_signal
signal player_stop_signal
signal player_entering_door_signal
signal player_entered_door_signal

@export var walk_speed = 6.0
@export var jump_speed = 4.0
const TILE_SIZE = 16

@onready var grass_tiles = $Grasses
@onready var anim_tree = $AnimationTree
@onready var anim_state = anim_tree.get("parameters/playback")
@onready var ray = $BlockingRayCast2D
@onready var ledge_ray = $LedgeRayCast2D
@onready var door_ray = $DoorRayCast2D
@onready var shadow = $Shadow
@onready var entering_door := false

var jumping_over_ledge: bool = false

enum PlayerState { IDLE, TURNING, WALKING }
enum FacingDirection { LEFT, RIGHT, UP, DOWN }

var player_state = PlayerState.IDLE
var facing_direction = FacingDirection.DOWN

var initial_position = Vector2.ZERO
var input_direction = Vector2(0,1)
var is_moving = false
var stop_input: bool = false
var percent_moved_to_next_tile = 0.0
var forced_direction := Vector2.ZERO

func _ready():
	add_to_group("Player")  # so SceneManager/Door can find player
	$Sprite2D.visible = true
	$Sprite2D.modulate = Color(1,1,1,1)
	$Sprite2D.scale = Vector2.ONE

	if has_node("Camera2D"):
		$Camera2D.make_current()

	anim_tree.active = true
	initial_position = global_position
	shadow.visible = false
	anim_tree.set("parameters/Idle/blend_position", input_direction)
	anim_tree.set("parameters/Walk/blend_position", input_direction)
	anim_tree.set("parameters/Turn/blend_position", input_direction)

func set_spawn(location: Vector2, direction: Vector2):
	entering_door = false
	is_moving = false
	stop_input = false
	percent_moved_to_next_tile = 0.0
	input_direction = Vector2.ZERO

	anim_tree.set("parameters/Idle/blend_position", direction)
	anim_tree.set("parameters/Walk/blend_position", direction)
	anim_tree.set("parameters/Turn/blend_position", direction)
	position = location

	
func _physics_process(delta):
	if player_state == PlayerState.TURNING or stop_input:
		return
	elif not is_moving:
		process_player_input()
	else:
		anim_state.travel("Walk")
		move(delta)

func process_player_input():
	input_direction = Vector2.ZERO
	if Input.is_action_pressed("ui_right") != Input.is_action_pressed("ui_left"):
		input_direction.x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	if Input.is_action_pressed("ui_down") != Input.is_action_pressed("ui_up"):
		input_direction.y = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))

	if input_direction != Vector2.ZERO:
		anim_tree.set("parameters/Idle/blend_position", input_direction)
		anim_tree.set("parameters/Walk/blend_position", input_direction)
		anim_tree.set("parameters/Turn/blend_position", input_direction)
		
		if need_to_turn():
			player_state = PlayerState.TURNING
			anim_state.travel("Turn")
		else:
			initial_position = position
			is_moving = true
	else:
		anim_state.travel("Idle")

func need_to_turn() -> bool:
	var new_dir: FacingDirection
	if input_direction.x < 0:
		new_dir = FacingDirection.LEFT
	elif input_direction.x > 0:
		new_dir = FacingDirection.RIGHT
	elif input_direction.y < 0:
		new_dir = FacingDirection.UP
	elif input_direction.y > 0:
		new_dir = FacingDirection.DOWN
	else:
		return false

	if new_dir != facing_direction:
		facing_direction = new_dir
		return true
	return false

func finished_turning():
	player_state = PlayerState.IDLE

func move(delta):
	var desired_step: Vector2 = input_direction * TILE_SIZE / 2
	ray.target_position = desired_step
	ray.force_raycast_update()
	ledge_ray.target_position = desired_step
	ledge_ray.force_raycast_update()
	door_ray.target_position = desired_step
	door_ray.force_raycast_update()

	# --- Handle door ---
	if door_ray.is_colliding() and not entering_door:
		if percent_moved_to_next_tile == 0.0:
			entering_door = true
			#stop_input = true # stop player from moving during fade
			forced_direction = input_direction
			emit_signal("player_entering_door_signal")
		percent_moved_to_next_tile += walk_speed * delta
		if percent_moved_to_next_tile >= 1:
			position = initial_position + (input_direction * TILE_SIZE)
			percent_moved_to_next_tile = 0.0
			is_moving = false
			# Finished door movement; emit signal
			emit_signal("player_entered_door_signal")
		else:
			position = initial_position + (input_direction * TILE_SIZE * percent_moved_to_next_tile)
		return

	# --- Handle ledge jump ---
	elif ledge_ray.is_colliding() and input_direction == Vector2(0,1) or jumping_over_ledge:
		percent_moved_to_next_tile += jump_speed * delta
		if percent_moved_to_next_tile >= 2.0:
			position = initial_position + (input_direction * TILE_SIZE * 2)
			percent_moved_to_next_tile = 0.0
			is_moving = false
			stop_input = false
			jumping_over_ledge = false
			shadow.visible = false
		else:
			shadow.visible = true
			jumping_over_ledge = true
			var input = input_direction.y * TILE_SIZE * percent_moved_to_next_tile
			position.y = initial_position.y + (-0.96 - 0.53 * input + 0.05 * pow(input, 2))

	# --- Normal movement ---
	elif not ray.is_colliding():
		if percent_moved_to_next_tile == 0.0:
			emit_signal("player_moving_signal")
		percent_moved_to_next_tile += walk_speed * delta
		if percent_moved_to_next_tile >= 1.0:
			position = initial_position + (input_direction * TILE_SIZE)
			percent_moved_to_next_tile = 0.0
			is_moving = false
			emit_signal("player_stop_signal")
			input_direction = Vector2.ZERO
		else:
			position = initial_position + (input_direction * TILE_SIZE * percent_moved_to_next_tile)
	else:
		is_moving = false
