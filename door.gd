extends Area2D

@export_file var next_scene_path = ""
@export var is_invisible := false
@export var spawn_location := Vector2.ZERO
@export var spawn_direction := Vector2.ZERO

@onready var anim_player = $AnimationPlayer

var player_entered = false

func _ready():
	if is_invisible:
		$Sprite2D.texture = null

	await get_tree().process_frame

	var player = get_tree().get_first_node_in_group("Player")

	player.player_entering_door_signal.connect(enter_door)
	player.player_entered_door_signal.connect(close_door)

func enter_door():
	if player_entered:
		anim_player.play("opendoor")

func close_door():
	if player_entered:
		anim_player.play("closed_door")

# Called from AnimationPlayer (Call Method track)
func door_closed():
	if player_entered:
		get_node("/root/SceneManager").transition_to_scene(next_scene_path, spawn_direction, spawn_location)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		player_entered = true

func _on_body_exited(body):
	if body.is_in_group("Player"):
		player_entered = false
