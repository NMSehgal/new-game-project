extends Node2D

var next_scene: String = ""
var player_location = Vector2(0,0)
var player_direction = Vector2(0,0)

@onready var color_rect = $ScreenTransition/ColorRect
@onready var anim_player = $ScreenTransition/AnimationPlayer
@onready var current_scene_node = $CurrentScene

func _ready():
	color_rect.modulate.a = 0
	color_rect.visible = true
	anim_player.stop()

func transition_to_scene(new_scene: String, spawn_direction, spawn_location):
	next_scene = new_scene
	player_location = spawn_location
	player_direction = spawn_direction
	color_rect.modulate.a = 1
	anim_player.play("FadetoBlack")  # fade out

# Called at the end of FadetoBlack animation (via Call Method track)
func finished_fading():
	# Remove current scene
	if current_scene_node.get_child_count() > 0:
		current_scene_node.get_child(0).queue_free()
	print("FINISHED_FADING CALLED. next_scene =", next_scene)


	# Load and instantiate next scene
	var scene_res = load(next_scene) as PackedScene
	if not scene_res:
		push_error("Failed to load scene: " + next_scene)
		return
	var scene_instance = scene_res.instantiate()
	current_scene_node.add_child(scene_instance)
	
	var player = $CurrentScene.get_tree().get_first_node_in_group("Player")
	player.set_spawn(player_location, player_direction)
	# Make Player camera current if exists
	var player_cam = scene_instance.get_node_or_null("Player/Camera2D")
	if player_cam:
		player_cam.make_current()

	# Fade back in
	anim_player.play("FadetoNormal")
