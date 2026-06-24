## Result 单元测试。
extends GutTest

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
	# 若失败会触发 assert 中断测试
	r.assert_ok()
	pass_test("assert_ok on success did not raise")


func test_error_code_constants_are_distinct():
	var codes: Array = [
		Result.ERR_UNKNOWN,
		Result.ERR_INVALID_ARG,
		Result.ERR_NOT_FOUND,
		Result.ERR_PARSE,
		Result.ERR_INVALID_STATE,
	]
	var unique := {}
	for c in codes:
		unique[c] = true
	assert_eq(unique.size(), codes.size(), "error codes must be distinct")
