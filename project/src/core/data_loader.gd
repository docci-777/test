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


# ---- 强类型加载方法 ----
# 以下方法从对应数据文件加载并构造强类型数据对象字典。
# 校验失败返回 Result.failure(ERR_PARSE)。

## 加载地形定义。
## [return] [Result]，成功时 [member Result.value] 为 Dictionary（id -> TerrainDef）
static func load_terrains() -> Result:
	return load_terrains_from_path(Paths.TERRAINS_FILE)


## 从指定路径加载地形定义（用于测试）。
static func load_terrains_from_path(path: String) -> Result:
	var r := load_json(path)
	if not r.ok:
		return r
	var data: Variant = r.value
	if not data is Dictionary:
		return Result.failure(Result.ERR_PARSE, "terrains root must be Dictionary")
	var root: Dictionary = data
	if not root.has("terrains"):
		return Result.failure(Result.ERR_PARSE, "missing 'terrains' key")
	var terrains_raw: Dictionary = root["terrains"]
	var result: Dictionary = {}
	for id in terrains_raw.keys():
		var entry: Variant = terrains_raw[id]
		if not entry is Dictionary:
			return Result.failure(Result.ERR_PARSE, "terrain '%s' must be Dictionary" % id)
		result[id] = TerrainDef.from_dict(String(id), entry)
	return Result.success(result)


## 加载建筑定义。
## [return] [Result]，成功时 [member Result.value] 为 Dictionary（id -> BuildingDef）
static func load_buildings() -> Result:
	return load_buildings_from_path(Paths.BUILDINGS_FILE)


## 从指定路径加载建筑定义（用于测试）。
static func load_buildings_from_path(path: String) -> Result:
	var r := load_json(path)
	if not r.ok:
		return r
	var data: Variant = r.value
	if not data is Dictionary:
		return Result.failure(Result.ERR_PARSE, "buildings root must be Dictionary")
	var root: Dictionary = data
	if not root.has("buildings"):
		return Result.failure(Result.ERR_PARSE, "missing 'buildings' key")
	var buildings_raw: Dictionary = root["buildings"]
	var result: Dictionary = {}
	for id in buildings_raw.keys():
		var entry: Variant = buildings_raw[id]
		if not entry is Dictionary:
			return Result.failure(Result.ERR_PARSE, "building '%s' must be Dictionary" % id)
		result[id] = BuildingDef.from_dict(String(id), entry)
	return Result.success(result)


## 加载发展卡定义。
## [return] [Result]，成功时 [member Result.value] 为 Dictionary（id -> DevCardDef）
static func load_dev_cards() -> Result:
	return load_dev_cards_from_path(Paths.DEV_CARDS_FILE)


## 从指定路径加载发展卡定义（用于测试）。
static func load_dev_cards_from_path(path: String) -> Result:
	var r := load_json(path)
	if not r.ok:
		return r
	var data: Variant = r.value
	if not data is Dictionary:
		return Result.failure(Result.ERR_PARSE, "dev_cards root must be Dictionary")
	var root: Dictionary = data
	if not root.has("dev_cards"):
		return Result.failure(Result.ERR_PARSE, "missing 'dev_cards' key")
	var cards_raw: Dictionary = root["dev_cards"]
	var result: Dictionary = {}
	for id in cards_raw.keys():
		var entry: Variant = cards_raw[id]
		if not entry is Dictionary:
			return Result.failure(Result.ERR_PARSE, "dev_card '%s' must be Dictionary" % id)
		result[id] = DevCardDef.from_dict(String(id), entry)
	return Result.success(result)


## 加载港口定义。
## [return] [Result]，成功时 [member Result.value] 为 Dictionary（id -> PortDef）
static func load_ports() -> Result:
	return load_ports_from_path(Paths.PORTS_FILE)


## 从指定路径加载港口定义（用于测试）。
static func load_ports_from_path(path: String) -> Result:
	var r := load_json(path)
	if not r.ok:
		return r
	var data: Variant = r.value
	if not data is Dictionary:
		return Result.failure(Result.ERR_PARSE, "ports root must be Dictionary")
	var root: Dictionary = data
	if not root.has("ports"):
		return Result.failure(Result.ERR_PARSE, "missing 'ports' key")
	var ports_raw: Dictionary = root["ports"]
	var result: Dictionary = {}
	for id in ports_raw.keys():
		var entry: Variant = ports_raw[id]
		if not entry is Dictionary:
			return Result.failure(Result.ERR_PARSE, "port '%s' must be Dictionary" % id)
		result[id] = PortDef.from_dict(String(id), entry)
	return Result.success(result)
