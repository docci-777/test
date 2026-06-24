## 数据文件加载器。
##
## 负责从 [member Paths] 定义的 JSON 数据文件加载并解析规则数据。
## 属于 Layer 1 核心层，不依赖 Node/场景，可在无 Godot 场景环境下被测试。
##
## 所有规则数据（地形、建筑、发展卡、港口、场景）必须经本类加载，
## 禁止在业务代码中硬编码规则数据（见 ARCHITECTURE §3.4 数据驱动）。
class_name DataLoader extends RefCounted

## 加载并解析 JSON 文件。
## [param path] 资源路径，如 [code]Paths.TERRAINS_FILE[/code]
## [return] [Result]，成功时 [member Result.value] 为解析后的 Dictionary/Array
static func load_json(path: String) -> Result:
	if path.is_empty():
		return Result.failure(Result.ERR_INVALID_ARG, "path is empty")

	if not FileAccess.file_exists(path):
		return Result.failure(Result.ERR_NOT_FOUND, "file not found: %s" % path)

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		var err: int = FileAccess.get_open_error()
		return Result.failure(Result.ERR_UNKNOWN, "cannot open file %s (error %d)" % [path, err])

	var text: String = file.get_as_text()
	file.close()

	if text.is_empty():
		return Result.failure(Result.ERR_PARSE, "file is empty: %s" % path)

	var json := JSON.new()
	var parse_err: int = json.parse(text)
	if parse_err != OK:
		return Result.failure(Result.ERR_PARSE, \
			"parse error in %s at line %d: %s" % [path, json.get_error_line(), json.get_error_message()])

	var data: Variant = json.data
	if data == null:
		return Result.failure(Result.ERR_PARSE, "parsed data is null: %s" % path)

	return Result.success(data)


## 校验数据为 Dictionary 类型并返回。
## [param data] 已解析的数据
## [return] [Result]，成功时 [member Result.value] 为 Dictionary
static func as_dict(data: Variant) -> Result:
	if not data is Dictionary:
		return Result.failure(Result.ERR_PARSE, "expected Dictionary, got %s" % typeof(data))
	return Result.success(data)


## 校验数据为 Array 类型并返回。
## [param data] 已解析的数据
## [return] [Result]，成功时 [member Result.value] 为 Array
static func as_array(data: Variant) -> Result:
	if not data is Array:
		return Result.failure(Result.ERR_PARSE, "expected Array, got %s" % typeof(data))
	return Result.success(data)
