## GUT 框架冒烟测试（P0-2）。
##
## 验证测试框架本身可正常运行。此文件不测业务逻辑，
## 仅确认 GUT 能被发现并执行断言。
extends GutTest

func test_gut_assert_true_works():
	assert_true(true)

func test_gut_assert_eq_works():
	assert_eq(1 + 1, 2)

func test_gut_assert_ne_works():
	assert_ne("a", "b")

func test_gut_before_hook_runs():
	# before_each 在下方定义，若执行则 _counter 已 +1
	assert_true(_counter >= 1)


var _counter: int = 0

func before_each():
	_counter += 1
