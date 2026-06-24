#!/usr/bin/env bash
# CI 测试脚本：以 headless 模式运行 GUT 测试套件。
#
# 用法：
#   ./scripts/run_tests.sh
#
# 退出码：
#   0 = 全部测试通过
#   非 0 = 存在失败或环境错误
#
# 详见 docs/04_TESTING.md §7

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/../project" && pwd)"

# 定位 Godot 可执行
GODOT_BIN="${GODOT_BIN:-godot}"
if ! command -v "${GODOT_BIN}" >/dev/null 2>&1; then
	# 回退到常见安装路径
	for candidate in /usr/local/bin/godot /opt/godot/godot; do
		if [ -x "${candidate}" ]; then
			GODOT_BIN="${candidate}"
			break
		fi
	done
fi

if ! command -v "${GODOT_BIN}" >/dev/null 2>&1; then
	echo "ERROR: godot executable not found (set GODOT_BIN env)" >&2
	exit 127
fi

echo "Using Godot: ${GODOT_BIN}"
"${GODOT_BIN}" --version

# headless 运行 GUT
# -s 指定 gut 命令行入口
# -gdir 指定测试目录，-ginclude_subdirs 递归子目录
# -gprefix="" -gsuffix=_test.gd 匹配 *_test.gd 命名约定（见 TESTING §3）
# -gexit 测试结束后退出并返回退出码
# -gexit_on_success 仅在全部通过时退出（CI 严格模式：失败时不自动退出以便查看输出）
cd "${PROJECT_DIR}"
exec "${GODOT_BIN}" --headless \
	-s res://addons/gut/gut_cmdln.gd \
	-gdir=res://tests \
	-ginclude_subdirs \
	-gprefix= \
	-gsuffix=_test.gd \
	-gexit
