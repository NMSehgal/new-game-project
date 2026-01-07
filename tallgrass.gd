extends Node2D

@onready var anim_player = $AnimationPlayer
const grass_overlay_texture = preload("res://Assets/Grass/stepped_tall_grass.png")
var grass_overlay: Sprite2D = null

var player_inside: bool = false


func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		player_inside = true
		print("Player entered grass")
	if anim_player:
		anim_player.play("stepped")

func _on_area_2d_body_exited(body):
	player_inside = false
	pass # Replace with function body.

func _ready():
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.player_moving_signal.connect(Callable(self, "player_exiting_grass"))
		player.player_stop_signal.connect(Callable(self, "player_in_grass"))
		anim_player.active = true
	
func player_exiting_grass():
	player_inside = false
	if is_instance_valid(grass_overlay):
		grass_overlay.queue_free()
func player_in_grass():
	if player_inside == true:
		
		grass_overlay = Sprite2D.new()
		grass_overlay.texture = grass_overlay_texture
		grass_overlay.position = position
		get_tree().add_child(grass_overlay) #make created overlay visisble
