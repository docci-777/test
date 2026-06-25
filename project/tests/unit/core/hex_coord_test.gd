## HexCoord 单元测试。
extends GutTest


func test_hex_coord_creation():
	var c := HexCoord.new(1, 2)
	assert_eq(c.q, 1)
	assert_eq(c.r, 2)


func test_hex_coord_s():
	var c := HexCoord.new(1, 2)
	assert_eq(c.s(), -3)


func test_hex_coord_equals():
	var c1 := HexCoord.new(1, 2)
	var c2 := HexCoord.new(1, 2)
	var c3 := HexCoord.new(2, 1)
	assert_true(c1.equals(c2))
	assert_false(c1.equals(c3))


func test_hex_coord_to_key():
	var c := HexCoord.new(3, -1)
	assert_eq(c.to_key(), "3,-1")


func test_hex_coord_clone():
	var c1 := HexCoord.new(1, 2)
	var c2 := c1.clone()
	assert_true(c1.equals(c2))
	c2.q = 5
	assert_eq(c1.q, 1)


func test_hex_coord_distance_to():
	var c1 := HexCoord.new(0, 0)
	var c2 := HexCoord.new(1, 0)
	assert_eq(c1.distance_to(c2), 1)
	var c3 := HexCoord.new(2, -1)
	assert_eq(c1.distance_to(c3), 2)


func test_hex_coord_directions_count():
	assert_eq(HexCoord.DIRECTIONS.size(), 6)


func test_hex_coord_to_pixel():
	var c := HexCoord.new(0, 0)
	var p := c.to_pixel()
	assert_almost_eq(p.x, 0.0, 0.001)
	assert_almost_eq(p.y, 0.0, 0.001)
