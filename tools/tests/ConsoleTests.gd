extends "res://tools/tests/TestSuite.gd"
## Checks for the games on Jacki's TV console (scenes/ui/console/): each one
## starts, plays and ends, and the scores add up.

const STEP: float = 1.0 / 60.0


func test_carrot_catch_scores_and_ends() -> void:
	var game := CarrotCatch.new()
	game.start()
	# Drop a carrot straight into the basket.
	game.things.append({"x": game.basket_x, "y": CarrotCatch.BASKET_Y - 1.0, "kind": "carrot"})
	check(game.step(STEP, 0.0) == "catch" and game.score == 1, "catching a carrot scores a point")
	for i in CarrotCatch.LIVES:
		game.things.append({"x": game.basket_x, "y": CarrotCatch.BASKET_Y - 1.0, "kind": "junk"})
		game.step(STEP, 0.0)
	check(game.state == CarrotCatch.State.OVER, "three bits of junk and it's game over")
	game.start()
	game.step(1.0, 1.0)
	check(game.basket_x > CarrotCatch.WIDTH * 0.5, "sliding right moves the basket right")


func test_comet_tail_grows_and_crashes() -> void:
	var game := CometTail.new()
	game.start()
	game.star = game.body[0] + Vector2i.RIGHT
	check(game.step(CometTail.START_STEP) == "star" and game.body.size() == 4 and game.score == 1, "eating a star grows the tail")
	game.turn(Vector2i.LEFT)
	game.step(CometTail.START_STEP)
	check(game.state == CometTail.State.PLAYING, "it can't turn straight back on itself")
	for i in CometTail.COLUMNS:
		game.step(CometTail.START_STEP)
	check(game.state == CometTail.State.OVER, "flying into the edge ends it")


func test_paddle_pods_points_and_winner() -> void:
	var game := PaddlePods.new()
	game.start()
	# Chang Ma misses one.
	game.ball = Vector2(PaddlePods.WIDTH + 3.0, 10.0)
	game.ball_velocity = Vector2(80.0, 0.0)
	game.cpu_y = PaddlePods.HEIGHT - PaddlePods.PADDLE_HALF
	check(game.step(STEP, 0.0) == "point" and game.you == 1 and game.score == 1, "the pod past Chang Ma is your point")
	game.you = PaddlePods.WIN_POINTS - 1
	game.ball = Vector2(PaddlePods.WIDTH + 3.0, 10.0)
	game.ball_velocity = Vector2(80.0, 0.0)
	game.step(STEP, 0.0)
	check(game.state == PaddlePods.State.OVER and game.you_won, "first to 5 wins")


func test_console_scores_are_saved() -> void:
	var before := GameState.to_save_data()
	GameState.console_scores = {"comet_tail": 12}
	var saved := JSON.parse_string(JSON.stringify(GameState.to_save_data())) as Dictionary
	GameState.new_game()
	GameState.apply_save_data(saved)
	check(int(GameState.console_scores.get("comet_tail", 0)) == 12, "the console's best scores are saved")
	GameState.apply_save_data(before)
