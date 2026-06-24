## Result 单元测试。
extends GutTest

# ---- 通用错误码 ----

func test_success_when_no_value_sets_ok_and_null_value():
	var r := Result.success()
	assert_true(r.ok)
	assert_eq(r.value, null)


func test_success_when_value_given_carries_value():
	var r := Result.success(42)
	assert_true(r.ok)
	assert_eq(r.value, 42)


func test_success_when_dict_value_carries_dict():
	var d := {"x": 1}
	var r := Result.success(d)
	assert_true(r.ok)
	assert_eq(r.value, d)


func test_failure_sets_error_code_and_message():
	var r := Result.failure(Result.ERR_NOT_FOUND, "missing")
	assert_false(r.ok)
	assert_eq(r.error_code, Result.ERR_NOT_FOUND)
	assert_eq(r.error_message, "missing")


func test_failure_default_message_is_empty():
	var r := Result.failure(Result.ERR_PARSE)
	assert_false(r.ok)
	assert_eq(r.error_message, "")


func test_assert_ok_when_success_does_not_raise():
	var r := Result.success()
	r.assert_ok()
	pass_test("assert_ok on success did not raise")


# ---- 错误码唯一性 ----

func test_all_error_codes_are_distinct():
	var codes: Array = [
		# 通用
		Result.ERR_UNKNOWN,
		Result.ERR_INVALID_ARG,
		Result.ERR_NOT_FOUND,
		Result.ERR_PARSE,
		Result.ERR_INVALID_STATE,
		# 回合流程
		Result.ERR_NOT_YOUR_TURN,
		Result.ERR_INVALID_PHASE,
		Result.ERR_GAME_OVER,
		# 资源
		Result.ERR_INSUFFICIENT_RESOURCES,
		Result.ERR_BANK_EMPTY,
		# 建造位置
		Result.ERR_INVALID_POSITION,
		Result.ERR_DISTANCE_RULE_VIOLATED,
		Result.ERR_NOT_CONNECTED,
		Result.ERR_POSITION_OCCUPIED,
		Result.ERR_NOT_OWNED,
		# 强盗
		Result.ERR_ROBBER_REQUIRED,
		Result.ERR_ROBBER_SAME_HEX,
		# 发展卡
		Result.ERR_CARD_NOT_USABLE,
		Result.ERR_DEV_CARD_ALREADY_USED,
		Result.ERR_CARD_NOT_FOUND,
		# 交易
		Result.ERR_TRADE_REJECTED,
		Result.ERR_PORT_NOT_OWNED,
	]
	var unique := {}
	for c in codes:
		unique[c] = true
	assert_eq(unique.size(), codes.size(), "all error codes must be distinct")


# ---- 错误码分类查询 ----

func test_is_rule_error_returns_true_for_rule_codes():
	assert_true(Result.is_rule_error(Result.ERR_INSUFFICIENT_RESOURCES))
	assert_true(Result.is_rule_error(Result.ERR_DISTANCE_RULE_VIOLATED))
	assert_true(Result.is_rule_error(Result.ERR_NOT_YOUR_TURN))


func test_is_rule_error_returns_false_for_generic_codes():
	assert_false(Result.is_rule_error(Result.ERR_UNKNOWN))
	assert_false(Result.is_rule_error(Result.ERR_PARSE))
	assert_false(Result.is_rule_error(Result.ERR_NOT_FOUND))


func test_is_rule_error_returns_false_for_zero():
	assert_false(Result.is_rule_error(0))


# ---- 错误码名称查询 ----

func test_error_name_returns_known_name():
	assert_eq(Result.error_name(Result.ERR_NOT_FOUND), "ERR_NOT_FOUND")
	assert_eq(Result.error_name(Result.ERR_INSUFFICIENT_RESOURCES), "ERR_INSUFFICIENT_RESOURCES")


func test_error_name_returns_unknown_for_invalid_code():
	assert_eq(Result.error_name(0), "UNKNOWN")
	assert_eq(Result.error_name(9999), "UNKNOWN")
