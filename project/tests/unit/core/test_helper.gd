## 测试辅助工具。
##
## 提供创建标准游戏状态的工厂方法，供各测试复用。
class_name TestHelper extends RefCounted


## 创建标准 4 人游戏状态（含棋盘、数据）。
static func make_standard_state() -> GameState:
	var state := GameState.new()
	# 加载数据
	var terrains_r := DataLoader.load_terrains()
	var buildings_r := DataLoader.load_buildings()
	var dev_cards_r := DataLoader.load_dev_cards()
	var ports_r := DataLoader.load_ports()
	assert(terrains_r.ok, "failed to load terrains")
	assert(buildings_r.ok, "failed to load buildings")
	assert(dev_cards_r.ok, "failed to load dev_cards")
	assert(ports_r.ok, "failed to load ports")
	state.terrains = terrains_r.value
	state.buildings = buildings_r.value
	state.dev_cards = dev_cards_r.value
	state.ports = ports_r.value
	# 生成棋盘
	var board_r := BoardGenerator.generate_full_base_board(42, state.terrains, state.ports)
	assert(board_r.ok, "failed to generate board")
	state.board = board_r.value
	# 放置强盗到沙漠
	for hex_data in state.board.all_hexes():
		if hex_data.terrain_id == "desert":
			state.robber_hex_id = hex_data.id
			break
	# 初始化银行和牌堆
	state.init_bank()
	state.init_dev_card_deck()
	# 添加 4 个玩家
	var colors := ["red", "blue", "white", "orange"]
	for i in range(4):
		state.add_player(PlayerState.new(i, colors[i]))
	return state


## 创建简单状态（无棋盘，用于纯逻辑测试）。
static func make_simple_state(player_count: int = 4) -> GameState:
	var state := GameState.new()
	state.init_bank()
	state.init_dev_card_deck()
	var colors := ["red", "blue", "white", "orange"]
	for i in range(player_count):
		state.add_player(PlayerState.new(i, colors[i]))
	return state


## 给玩家添加资源（用于测试）。
static func give_resources(player: PlayerState, wood: int = 0, brick: int = 0, sheep: int = 0, wheat: int = 0, ore: int = 0) -> void:
	if wood > 0:
		player.add_resource(ResType.WOOD, wood)
	if brick > 0:
		player.add_resource(ResType.BRICK, brick)
	if sheep > 0:
		player.add_resource(ResType.SHEEP, sheep)
	if wheat > 0:
		player.add_resource(ResType.WHEAT, wheat)
	if ore > 0:
		player.add_resource(ResType.ORE, ore)
