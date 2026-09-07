"""T01规划数据验证，不实现游戏；仅Python标准库。根目录运行本文件。"""
import heapq
import json
from collections import Counter, deque
from pathlib import Path

data = json.loads(Path(__file__).with_name('map-v1.json').read_text())
rows = data['rows']
assert data['width'] == data['height'] == 15
assert len(rows) == 15 and all(len(row) == 15 for row in rows)
assert set(''.join(rows)) == set('PFM')
bases = {k: tuple(v) for k, v in data['bases'].items()}
points = [tuple(v['pos']) for v in data['outposts']]
units = data['units']
unit_pos = [tuple(u['pos']) for u in units]
assert len(bases) == len(set(bases.values())) == 3
assert len(points) == len(set(points)) == 3
assert len(units) == len(set(unit_pos)) == 12
assert not set(unit_pos) & (set(bases.values()) | set(points))
assert not set(points) & set(bases.values())
for pos in list(bases.values()) + points + unit_pos:
    x, y = pos
    assert 0 <= x < 15 and 0 <= y < 15
    assert rows[y][x] == 'P'
for p in 'ABC':
    assert Counter(u['kind'] for u in units if u['owner'] == p) == {
        'infantry': 2, 'cavalry': 1, 'archer': 1}

def neighbors(pos):
    x, y = pos
    return [(a, b) for a, b in ((x-1,y),(x+1,y),(x,y-1),(x,y+1))
            if 0 <= a < 15 and 0 <= b < 15]

def distances(start, cavalry=False):
    # 基地起点仅供距离比较；实战不可从基地格移动。
    dist, queue = {start: 0}, [(0, start)]
    while queue:
        cost, pos = heapq.heappop(queue)
        if cost != dist[pos]:
            continue
        for nxt in neighbors(pos):
            if nxt in bases.values() and nxt != start:
                continue
            terrain = rows[nxt[1]][nxt[0]]
            if cavalry and terrain == 'M':
                continue
            new = cost + (1 if terrain == 'P' else 2)
            if new < dist.get(nxt, 10**9):
                dist[nxt] = new
                heapq.heappush(queue, (new, nxt))
    return dist

print('PASS: 225格、三种地形、设施/12单位无重叠及初始兵种')
print('地形数量:', dict(Counter(''.join(rows))))
for cavalry in (False, True):
    start = (7, 7)
    reached = distances(start, cavalry)
    expected = {(x,y) for y in range(15) for x in range(15)
                if (x,y) not in bases.values()
                and not (cavalry and rows[y][x] == 'M')}
    assert set(reached) == expected
    print(f'PASS: {"骑兵" if cavalry else "步兵/弓兵"}全部可通行格连通: {len(expected)}')

# 显式两条仅共享基地和中心端点的路线，核验而非假设。
routes = {
    'A': [[(7,1)] + [(6,y) for y in range(1,8)] + [(7,7)],
          [(7,1)] + [(8,y) for y in range(1,8)] + [(7,7)]],
    'B': [[(2,8)] + [(x,7) for x in range(2,8)],
          [(2,8)] + [(x,9) for x in range(2,8)] + [(7,8),(7,7)]],
    'C': [[(12,8)] + [(x,7) for x in range(12,6,-1)],
          [(12,8)] + [(x,9) for x in range(12,6,-1)] + [(7,8),(7,7)]]}
for p in 'ABC':
    pair = routes[p]
    assert set(pair[0][1:-1]).isdisjoint(pair[1][1:-1])
    for route in pair:
        assert route[0] == bases[p] and route[-1] == (7,7)
        assert len(route) == len(set(route))
        for a, b in zip(route, route[1:]):
            assert b in neighbors(a)
            assert b not in bases.values()
            assert rows[b[1]][b[0]] != 'M'
    dist = distances(bases[p])
    cav = distances(bases[p], True)
    print(f'PASS: {p}两条内部顶点不相交路线，步数={[len(r)-1 for r in pair]}')
    print(f'{p}: 中心成本={dist[(7,7)]}; 据点成本={[dist[v] for v in points]}; '
          f'骑兵据点成本={[cav[v] for v in points]}')
print('PASS: 地图规划验证完成；未验证动态占格、游戏逻辑或实玩平衡')
