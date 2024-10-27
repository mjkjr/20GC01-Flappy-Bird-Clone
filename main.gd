extends Node2D

enum GameState { OPENING, PLAYING, PAUSED, GAMEOVER, RESTARTING }

const OBSTACLE = preload("res://obstacle.tscn")

var game_state: GameState = GameState.OPENING

var score: int = 0
var high_score: int = 0


func _ready() -> void:
	game_state = GameState.OPENING
	$Player.process_mode = PROCESS_MODE_DISABLED
	load_high_score()


func _process(delta: float) -> void:
	if game_state == GameState.PLAYING:
		$Boundaries/Bottom/CollisionShape2D.set_deferred("disabled", false)
	
	if Input.is_action_just_pressed("Start"):
		if game_state == GameState.OPENING:
			start()
		elif game_state == GameState.PAUSED:
			unpause()
		elif game_state == GameState.GAMEOVER:
			restart()
	
	elif Input.is_action_just_pressed("Quit"):
		if game_state == GameState.PLAYING:
			pause()
		elif (
				game_state == GameState.PAUSED
				or game_state == GameState.GAMEOVER
		):
			get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
			
	if game_state == GameState.PLAYING:
		$Background/ForegroundMountains.scroll_offset.x -= delta * 200
		$Background/MidgroundMountains.scroll_offset.x -= delta * 150
		$Background/FargroundMountains.scroll_offset.x -= delta * 120
		$Background/MidgroundClouds.scroll_offset.x -= delta * 85
		$Background/FargroundClouds.scroll_offset.x -= delta * 60


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()


func save_high_score() -> void:
	if score == high_score:
		var file = FileAccess.open("user://hiscore", FileAccess.WRITE)
		if file != null:
			file.store_string(str(high_score))


func load_high_score() -> void:
	var file = FileAccess.open("user://hiscore", FileAccess.READ)
	if file != null:
		set_high_score(int(file.get_as_text()))


func restart() -> void:
	game_state = GameState.RESTARTING
	set_score(0)
	$UI/GameOverScreen.visible = false
	get_tree().call_group("obstacles", "free")
	$Player.set_position(Vector2(1920/2.0, 1080/2.0))
	$Player.set_velocity(Vector2(0,0))
	$Timer.wait_time = 3
	start()


func start() -> void:
	game_state = GameState.PLAYING
	$UI/StartScreen.visible = false
	$Player.visible = true
	$Player.process_mode = PROCESS_MODE_INHERIT
	$Timer.start()
	$Timer2.start()


func game_over() -> void:
	game_state = GameState.GAMEOVER
	$Timer.stop()
	$UI/GameOverScreen.visible = true
	$Player.process_mode = PROCESS_MODE_DISABLED
	(func(): get_tree().set_group("obstacles", "process_mode", PROCESS_MODE_DISABLED)).call_deferred()
	$Boundaries/Bottom/CollisionShape2D.set_deferred("disabled", true)
	save_high_score()


func pause() -> void:
	game_state = GameState.PAUSED
	$Timer.paused = true
	$Timer2.paused = true
	$UI/PauseScreen.visible = true
	$Player.visible = false
	$Player.process_mode = PROCESS_MODE_DISABLED
	get_tree().set_group("obstacles", "process_mode", PROCESS_MODE_DISABLED)


func unpause() -> void:
	game_state = GameState.PLAYING
	$UI/PauseScreen.visible = false
	$Player.visible = true
	$Player.process_mode = PROCESS_MODE_INHERIT
	get_tree().set_group("obstacles", "process_mode", PROCESS_MODE_INHERIT)
	$Timer.paused = false
	$Timer2.paused = false


func set_score(num: int) -> void:
	score = num
	$UI/GridContainer/Score.text = str(score)


func increment_score(amount: int = 1) -> void:
	score += amount
	$UI/GridContainer/Score.text = str(score)


func set_high_score(num: int) -> void:
	high_score = num
	$UI/GridContainer/HighScore.text = str(high_score)


func _on_score(_body: Node2D) -> void:
	increment_score(100)
	if score > high_score:
		set_high_score(score)


func _on_collision(_body: Node2D) -> void:
	if game_state == GameState.PLAYING:
		game_over()


func _on_timer_timeout() -> void:
	var obstacle: Node2D = OBSTACLE.instantiate()
	obstacle.position.x = get_viewport_rect().size.x + (96*.5)
	
	obstacle.get_node("Upper/Sprite2D").frame = randi_range(0,1)
	obstacle.get_node("Lower/Sprite2D").frame = randi_range(0,1)
	var py = randf_range(-350, 350)
	obstacle.get_node("Upper").position.y = py
	obstacle.get_node("Lower").position.y = py + 1080
	add_child(obstacle)
	obstacle.get_node("Upper").body_entered.connect(_on_collision)
	obstacle.get_node("Lower").body_entered.connect(_on_collision)
	obstacle.get_node("Threshold").body_entered.connect(_on_score)


func _on_timer_2_timeout() -> void:
	$Timer.wait_time -= 0.5
