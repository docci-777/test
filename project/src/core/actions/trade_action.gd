## 交易动作。
##
## 支持银行 4:1、港口 3:1/2:1、玩家间交易。
## 见 GAME_RULES §6。
class_name TradeAction extends Action

# ---- 交易类型 ----
## 银行 4:1
const TRADE_BANK: int = 0
## 港口 3:1/2:1
const TRADE_PORT: int = 1
## 玩家间
const TRADE_PLAYER: int = 2

## 交易类型
var trade_type: int = TRADE_BANK
## 给出的资源集合（银行/港口为单一资源，玩家间可混合）
var give: ResourceSet
## 想要接收的资源类型（银行/港口用，玩家间用 receive_set）
var receive_type: int = ResType.INVALID
## 港口顶点 ID（仅 TRADE_PORT 用）
var port_vertex_id: int = -1
## 目标玩家 ID（仅 TRADE_PLAYER 用）
var target_player_id: int = -1
## 想要接收的资源集合（仅 TRADE_PLAYER 用）
var receive_set: ResourceSet


func _init(pid: int = -1) -> void:
	super._init(Action.TYPE_TRADE, pid)
	give = ResourceSet.new()
	receive_set = ResourceSet.new()


## 创建银行 4:1 交易。
static func new_bank_trade(pid: int, give_set: ResourceSet, recv_type: int) -> TradeAction:
	var a := TradeAction.new(pid)
	a.trade_type = TRADE_BANK
	a.give = give_set
	a.receive_type = recv_type
	return a


## 创建港口交易。
static func new_port_trade(pid: int, give_set: ResourceSet, recv_type: int, port_vid: int) -> TradeAction:
	var a := TradeAction.new(pid)
	a.trade_type = TRADE_PORT
	a.give = give_set
	a.receive_type = recv_type
	a.port_vertex_id = port_vid
	return a


## 创建玩家间交易。
static func new_player_trade(pid: int, target_pid: int, give_set: ResourceSet, recv_set: ResourceSet) -> TradeAction:
	var a := TradeAction.new(pid)
	a.trade_type = TRADE_PLAYER
	a.give = give_set
	a.target_player_id = target_pid
	a.receive_set = recv_set
	return a
