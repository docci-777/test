## DataLoader 单元测试。
##
## 覆盖正向、负向、边界用例（见 TESTING §4.1）。
extends GutTest

const FIXTURES: String = "res://tests/fixtures/"


# ---- 正向用例 ----

func test_load_json_when_valid_dict_file_returns_dict():
	var r := DataLoader.load_json(FIXTURES + "valid_dict.json")
	assert_true(r.ok, "should succeed")
	assert_true(r.value is Dictionary, "value should be Dictionary")
	assert_eq(r.value.get("type", ""), "mountains")


func test_load_json_when_valid_array_file_returns_array():
	var r := DataLoader.load_json(FIXTURES + "valid_array.json")
	assert_true(r.ok, "should succeed")
	assert_true(r.value is Array, "value should be Array")
	assert_eq(r.value.size(), 2)


# ---- 负向用例 ----

func test_load_json_when_path_empty_returns_invalid_arg():
	var r := DataLoader.load_json("")
	assert_false(r.ok, "should fail")
	assert_eq(r.error_code, Result.ERR_INVALID_ARG)


func test_load_json_when_file_missing_returns_not_found():
	var r := DataLoader.load_json(FIXTURES + "nonexistent.json")
	assert_false(r.ok, "should fail")
	assert_eq(r.error_code, Result.ERR_NOT_FOUND)


func test_load_json_when_file_empty_returns_parse_error():
	var r := DataLoader.load_json(FIXTURES + "empty.json")
	assert_false(r.ok, "should fail")
	assert_eq(r.error_code, Result.ERR_PARSE)


func test_load_json_when_file_invalid_json_returns_parse_error():
	var r := DataLoader.load_json(FIXTURES + "invalid.json")
	assert_false(r.ok, "should fail")
	assert_eq(r.error_code, Result.ERR_PARSE)
	assert_true(r.error_message.contains("parse error"), "msg: %s" % r.error_message)


# ---- 边界用例：类型校验 ----

func test_as_dict_when_dict_returns_success():
	var r := DataLoader.as_dict({"a": 1})
	assert_true(r.ok)
	assert_true(r.value is Dictionary)


func test_as_dict_when_array_returns_parse_error():
	var r := DataLoader.as_dict([1, 2, 3])
	assert_false(r.ok)
	assert_eq(r.error_code, Result.ERR_PARSE)


func test_as_array_when_array_returns_success():
	var r := DataLoader.as_array([1, 2, 3])
	assert_true(r.ok)
	assert_true(r.value is Array)


func test_as_array_when_dict_returns_parse_error():
	var r := DataLoader.as_array({"a": 1})
	assert_false(r.ok)
	assert_eq(r.error_code, Result.ERR_PARSE)
