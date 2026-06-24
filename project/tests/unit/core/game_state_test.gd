## GameState 单元测试。
extends GutTest


func _make_state_with_players(n: int = 4) -> GameState:
	var colors := ["red", "blue", "white", "orange"]
	var state := GameState.new()
	for i in range(n):
		state.add_player(PlayerState.new(i, colors[i]))
	return state


# ---- 玩家管理 ----

func test_new_state_has_no_players():
	var s := GameState.new()
	assert_eq(s.player_count(), 0)


func test_add_player_increments_count():
	var s := _make_state_with_players(4)
	assert_eq(s.player_count(), 4)


func test_get_player_returns_correct_player():
	var s := _make_state_with_players(4)
	var p := s.get_player(2)
	assert_not_null(p)
	assert_eq(p.player_id, 2)
	assert_eq(p.color, "white")


func test_get_player_invalid_id_returns_null():
	var s := _make_state_with_players(2)
	assert_null(s.get_player(5))


func test_get_all_players_returns_list():
	var s := _make_state_with_players(3)
	var players := s.get_all_players()
	assert_eq(players.size(), 3)


# ---- 回合流程 ----

func test_new_state_current_player_is_zero():
	var s := _make_state_with_players(4)
	assert_eq(s.current_player_id, 0)


func test_advance_turn_moves_to_next_player():
	var s := _make_state_with_players(4)
	s.advance_turn()
	assert_eq(s.current_player_id, 1)
	s.advance_turn()
	assert_eq(s.current_player_id, 2)


func test_advance_turn_wraps_around():
	var s := _make_state_with_players(4)
	s.current_player_id = 3
	s.advance_turn()
	assert_eq(s.current_player_id, 0)


func test_advance_turn_increments_round_number_on_wrap():
	var s := _make_state_with_players(4)
	s.current_player_id = 3
	s.advance_turn()
	assert_eq(s.round_number, 2)


func test_new_state_phase_is_setup():
	var s := _make_state_with_players(4)
	assert_eq(s.phase, GameState.Phase.SETUP)


func test_set_phase_changes_phase():
	var s := _make_state_with_players(4)
	s.set_phase(GameState.Phase.ROLL)
	assert_eq(s.phase, GameState.Phase.ROLL)


# ---- 银行资源池 ----

func test_new_state_bank_has_default_19_per_resource():
	var s := GameState.new()
	s.init_bank()
	assert_eq(s.bank.get_amount(ResType.WOOD), 19)
	assert_eq(s.bank.get_amount(ResType.ORE), 19)
	assert_eq(s.bank.total(), 95)


func test_bank_withdraw_decrements():
	var s := GameState.new()
	s.init_bank()
	s.bank_withdraw(ResType.WOOD, 5)
	assert_eq(s.bank.get_amount(ResType.WOOD), 14)


func test_bank_withdraw_returns_false_when_empty():
	var s := GameState.new()
	s.init_bank()
	s.bank_withdraw(ResType.WOOD, 19)
	var ok := s.bank_withdraw(ResType.WOOD, 1)
	assert_false(ok)
	assert_eq(s.bank.get_amount(ResType.WOOD), 0)


func test_bank_deposit_increments():
	var s := GameState.new()
	s.init_bank()
	s.bank_withdraw(ResType.WOOD, 5)
	s.bank_deposit(ResType.WOOD, 2)
	assert_eq(s.bank.get_amount(ResType.WOOD), 16)


# ---- 发展卡牌堆 ----

func test_new_state_dev_card_deck_empty():
	var s := GameState.new()
	assert_eq(s.dev_card_deck.size(), 0)


func test_init_dev_card_deck_creates_25_cards():
	var s := GameState.new()
	s.init_dev_card_deck()
	assert_eq(s.dev_card_deck.size(), 25)


func test_init_dev_card_deck_has_14_knights():
	var s := GameState.new()
	s.init_dev_card_deck()
	var knight_count: int = 0
	for card in s.dev_card_deck:
		if card == "knight":
			knight_count += 1
	assert_eq(knight_count, 14)


func test_init_dev_card_deck_has_5_victory_points():
	var s := GameState.new()
	s.init_dev_card_deck()
	var vp_count: int = 0
	for card in s.dev_card_deck:
		if card == "victory_point":
			vp_count += 1
	assert_eq(vp_count, 5)


func test_draw_dev_card_removes_from_deck():
	var s := GameState.new()
	s.init_dev_card_deck()
	var initial_size := s.dev_card_deck.size()
	var card := s.draw_dev_card()
	assert_true(card.length() > 0)
	assert_eq(s.dev_card_deck.size(), initial_size - 1)


func test_draw_dev_card_from_empty_returns_empty():
	var s := GameState.new()
	var card := s.draw_dev_card()
	assert_eq(card, "")


# ---- 强盗位置 ----

func test_new_state_robber_position_is_invalid():
	var s := GameState.new()
	assert_eq(s.robber_hex_id, -1)


func test_set_robber_position_updates():
	var s := GameState.new()
	s.set_robber_position(7)
	assert_eq(s.robber_hex_id, 7)


# ---- 胜利判定 ----

func test_check_winner_returns_null_when_no_one_reaches_threshold():
	var s := _make_state_with_players(2)
	s.set_victory_threshold(10)
	s.get_player(0).add_building("settlement")  # 1 vp
	assert_null(s.check_winner())


func test_check_winner_returns_player_at_threshold():
	var s := _make_state_with_players(2)
	s.set_victory_threshold(10)
	var p := s.get_player(0)
	# 10 个定居点 = 10 vp（测试用，实际不能建这么多）
	for i in range(10):
		p.add_building("settlement")
	var winner := s.check_winner()
	assert_not_null(winner)
	assert_eq(winner.player_id, 0)


func test_check_winner_uses_total_vp_including_hidden():
	var s := _make_state_with_players(2)
	s.set_victory_threshold(10)
	var p := s.get_player(0)
	for i in range(9):
		p.add_building("settlement")  # 9 vp
	p.hidden_victory_points = 1  # +1 隐藏 = 10
	var winner := s.check_winner()
	assert_not_null(winner)


func test_set_victory_threshold_changes_threshold():
	var s := GameState.new()
	s.set_victory_threshold(13)
	assert_eq(s.victory_threshold, 13)


# ---- 游戏结束 ----

func test_new_state_not_over():
	var s := _make_state_with_players(2)
	assert_false(s.is_game_over)


func test_end_game_sets_over_and_winner():
	var s := _make_state_with_players(2)
	var p := s.get_player(0)
	s.end_game(p)
	assert_true(s.is_game_over)
	assert_eq(s.winner.player_id, 0)


# ---- clone ----

func test_clone_returns_independent_copy():
	var s := _make_state_with_players(2)
	s.init_bank()
	s.init_dev_card_deck()
	s.current_player_id = 1
	s.get_player(0).add_resource(ResType.WOOD, 3)
	var c := s.clone()
	c.current_player_id = 0
	c.get_player(0).add_resource(ResType.WOOD, 1)
	assert_eq(s.current_player_id, 1)
	assert_eq(s.get_player(0).resources.get_amount(ResType.WOOD), 3)
	assert_eq(c.get_player(0).resources.get_amount(ResType.WOOD), 4)
