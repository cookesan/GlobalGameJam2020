extends Node2D

signal end_game(score)

var preloaded_item = preload("res://Scenes/Item.tscn")
var window_size = OS.window_size
var item_initial_offset = Vector2(-150, 150)
var flash_progress = 0.0
var screen_default = Color.black
var flash_fail = Color.red
var flash_good = Color.greenyellow
var flash_target = screen_default
var flash_speed = 1.0

onready var conveyor = get_node("Conveyor")

# Called when the node enters the scene tree for the first time.
func _ready():
	start_a_game()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_tick_flash(delta)

func _input(event):
	if $GameState.current_state != $GameState.State.GAME:
		return
	var current_item = conveyor._current();
	if current_item == null:
		_next()
		return

	if event.is_action_pressed("approve_item"):
		$Stamp.start_fading()
		if current_item.condition != current_item.ShieldCondition.CORRECT:
			$ResultLabel.text = "Miss"
			$GameState.add_point($GameState.Point.WRONG)
			get_tree().get_root().get_node("Main")._flash_error()
			current_item.break_item()
		else:
			$ResultLabel.text = "Good"
			$GameState.add_point($GameState.Point.RIGHT)
		_next()
	elif event.is_action_pressed("clean_rust"):
		$Polish.start_fading()
		if current_item.condition != current_item.ShieldCondition.RUST:
			$ResultLabel.text = "Miss"
			$GameState.add_point($GameState.Point.WRONG)
			get_tree().get_root().get_node("Main")._flash_error()
			current_item.break_item()
		else:
			$ResultLabel.text = "Good"
			$GameState.add_point($GameState.Point.RIGHT)
			current_item.clean_rust()
		_next()
	elif event.is_action_pressed("fix_crack"):
		$Hammer.start_fading()
		if current_item.condition != current_item.ShieldCondition.CRACK:
			$ResultLabel.text = "Miss"
			$GameState.add_point($GameState.Point.WRONG)
			get_tree().get_root().get_node("Main")._flash_error()
			current_item.break_item()
		else:
			$ResultLabel.text = "Good"
			$GameState.add_point($GameState.Point.RIGHT)
			current_item.fix_crack()
		_next()

func _push_into_conveyor():
	var new_item = preloaded_item.instance()
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var my_random_number = rng.randi_range(0, 100)
	if my_random_number < 20:
		new_item.condition = new_item.ShieldCondition.RUST
	elif my_random_number < 40:
		new_item.condition = new_item.ShieldCondition.CRACK
	else:
		new_item.condition = new_item.ShieldCondition.CORRECT
	
	_set_initial_position(new_item)
	add_child(new_item)
	conveyor._add(new_item)

func _next():
	_push_into_conveyor()

func _set_initial_position(item):
	var position = window_size
	var sprite_size = item.get_rect().size
	position.x -= sprite_size.x/2 + item_initial_offset.x
	position.y -= sprite_size.y/2 + item_initial_offset.y
	item.set_position(position)

func _screen_flash(color, duration):
	flash_progress = duration
	flash_target = color

func _tick_flash(delta):
	if flash_progress == 0.0:
		VisualServer.set_default_clear_color(screen_default)
		return

	var target_color = screen_default.linear_interpolate(flash_target, flash_progress)
	VisualServer.set_default_clear_color(target_color)
	flash_progress -= delta
	flash_progress = clamp(flash_progress, 0.0, 1.0)

func start_a_game():
	$GameState.start_game()
	for i in range(4):
		_push_into_conveyor()

func _on_GameState_game_ended(score):
	emit_signal("end_game", score)
