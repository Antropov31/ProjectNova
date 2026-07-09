extends SceneTree

func _neighbors(occ: Dictionary, c: Vector2i) -> Array:
	var out: Array = []
	for d in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
		if occ.has(c + d):
			out.append(c + d)
	return out

# BFS from SPAWN, optionally blocking a cell, returns set of reachable cells
func _reach(occ: Dictionary, block) -> Dictionary:
	var seen: Dictionary = {}
	var start := Vector2i(0,0)
	if block != null and block == start:
		return seen
	seen[start] = true
	var q: Array = [start]
	var h := 0
	while h < q.size():
		var cur = q[h]; h += 1
		for nb in _neighbors(occ, cur):
			if block != null and nb == block:
				continue
			if not seen.has(nb):
				seen[nb] = true
				q.append(nb)
	return seen

func _initialize() -> void:
	var fails := 0
	var total := 0
	for seedv in range(1, 61):
		total += 1
		var m: Dictionary = RoomData.chapter_map(1, seedv)
		var occ: Dictionary = {}
		for k in m.keys():
			occ[k] = true
		var nova := Vector2i(2,0)
		var spawn := Vector2i(0,0)
		var enemy := Vector2i(1,0)
		# find boss cell
		var boss = null
		for k in m.keys():
			if bool(m[k].get("descent", false)):
				boss = k
		var problems: Array = []
		if not m.has(spawn) or not bool(m[spawn].get("hub", false)):
			problems.append("no spawn/hub")
		if not m.has(enemy) or not bool(m[enemy].get("combat_intro", false)):
			problems.append("no enemy room")
		if not m.has(nova) or not bool(m[nova].get("meet_nova", false)):
			problems.append("no nova room")
		if boss == null:
			problems.append("no boss/descent")
		# no random cell should sit at x<=1 except spawn/enemy
		for k in m.keys():
			if k.x <= 1 and k != spawn and k != enemy:
				problems.append("cell at x<=1: %s" % str(k))
		# boss reachable normally
		var r_all := _reach(occ, null)
		if boss != null and not r_all.has(boss):
			problems.append("boss unreachable")
		# boss NOT reachable if Nova is blocked  -> proves gating
		var r_noNova := _reach(occ, nova)
		if boss != null and r_noNova.has(boss):
			problems.append("BOSS REACHABLE WITHOUT NOVA")
		if problems.size() > 0:
			fails += 1
			print("seed %d FAIL: %s (rooms=%d, boss=%s)" % [seedv, str(problems), m.size(), str(boss)])
	print("=== %d/%d seeds passed ===" % [total - fails, total])
	quit()
