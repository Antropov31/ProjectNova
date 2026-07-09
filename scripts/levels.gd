extends RefCounted

# Static data for ProjectNova: room-based platformer levels + upgrade defs.
# Coordinates are in world pixels. Each level has a floor and platforms.
# The player starts at spawn, clears/avoids enemies, reaches the exit door.

static func upgrades() -> Array:
	return [
		{"id": "overclock", "name": "Overclock", "desc": "Nova fires 60% faster"},
		{"id": "twin", "name": "Twin Bolts", "desc": "Nova fires an extra bolt"},
		{"id": "pierce", "name": "Piercing Rounds", "desc": "Shots pierce +1 enemy"},
		{"id": "repair", "name": "Repair Field", "desc": "Slowly repairs your suit"},
		{"id": "shock", "name": "Shock Pulse", "desc": "Nova emits an EMP blast"},
		{"id": "doublejump", "name": "Servo Legs", "desc": "Gain a double jump"},
		{"id": "dash", "name": "Kinetic Dash", "desc": "Press Shift to dash"},
	]

static func levels() -> Array:
	var L: Array = []

	# --- Level 1: Maintenance Bay (tutorial) ---
	L.append({
		"name": "Maintenance Bay",
		"bounds": Vector2(1900, 720),
		"spawn": Vector2(110, 600),
		"platforms": [
			Rect2(0, 680, 1900, 40),
			Rect2(340, 560, 200, 24),
			Rect2(660, 460, 200, 24),
			Rect2(1000, 560, 220, 24),
			Rect2(1360, 470, 200, 24),
		],
		"enemies": [
			{"pos": Vector2(760, 420), "kind": "crawler"},
			{"pos": Vector2(1100, 520), "kind": "crawler"},
			{"pos": Vector2(1500, 300), "kind": "flyer"},
		],
		"exit": Vector2(1820, 680),
	})

	# --- Level 2: Assembly Line ---
	L.append({
		"name": "Assembly Line",
		"bounds": Vector2(2200, 760),
		"spawn": Vector2(90, 640),
		"platforms": [
			Rect2(0, 720, 520, 40),
			Rect2(700, 720, 500, 40),
			Rect2(1380, 720, 820, 40),
			Rect2(300, 580, 160, 24),
			Rect2(560, 470, 160, 24),
			Rect2(860, 520, 180, 24),
			Rect2(1180, 430, 180, 24),
			Rect2(1520, 560, 200, 24),
			Rect2(1820, 470, 180, 24),
		],
		"enemies": [
			{"pos": Vector2(360, 540), "kind": "crawler"},
			{"pos": Vector2(900, 480), "kind": "turret"},
			{"pos": Vector2(1250, 250), "kind": "flyer"},
			{"pos": Vector2(1600, 520), "kind": "crawler"},
			{"pos": Vector2(1900, 300), "kind": "flyer"},
		],
		"exit": Vector2(2120, 720),
	})

	# --- Level 3: Server Shaft (vertical) ---
	L.append({
		"name": "Server Shaft",
		"bounds": Vector2(1500, 1200),
		"spawn": Vector2(120, 1080),
		"platforms": [
			Rect2(0, 1160, 1500, 40),
			Rect2(220, 1010, 200, 24),
			Rect2(560, 940, 200, 24),
			Rect2(900, 1010, 200, 24),
			Rect2(1200, 880, 200, 24),
			Rect2(300, 770, 200, 24),
			Rect2(700, 700, 220, 24),
			Rect2(1080, 640, 200, 24),
			Rect2(400, 520, 200, 24),
			Rect2(820, 450, 220, 24),
			Rect2(1150, 360, 250, 24),
		],
		"enemies": [
			{"pos": Vector2(620, 900), "kind": "crawler"},
			{"pos": Vector2(1250, 840), "kind": "turret"},
			{"pos": Vector2(760, 640), "kind": "crawler"},
			{"pos": Vector2(500, 380), "kind": "flyer"},
			{"pos": Vector2(900, 300), "kind": "flyer"},
			{"pos": Vector2(880, 400), "kind": "turret"},
		],
		"exit": Vector2(1300, 360),
	})

	# --- Level 4: Coolant Tunnels ---
	L.append({
		"name": "Coolant Tunnels",
		"bounds": Vector2(2400, 760),
		"spawn": Vector2(90, 640),
		"platforms": [
			Rect2(0, 720, 380, 40),
			Rect2(520, 640, 160, 24),
			Rect2(760, 720, 260, 40),
			Rect2(1120, 560, 180, 24),
			Rect2(1160, 720, 300, 40),
			Rect2(1560, 620, 180, 24),
			Rect2(1560, 720, 840, 40),
			Rect2(1880, 560, 180, 24),
			Rect2(700, 470, 180, 24),
			Rect2(1000, 380, 180, 24),
			Rect2(1340, 420, 180, 24),
		],
		"enemies": [
			{"pos": Vector2(300, 660), "kind": "crawler"},
			{"pos": Vector2(820, 470), "kind": "turret"},
			{"pos": Vector2(1050, 250), "kind": "flyer"},
			{"pos": Vector2(1250, 520), "kind": "crawler"},
			{"pos": Vector2(1620, 300), "kind": "flyer"},
			{"pos": Vector2(1950, 520), "kind": "turret"},
			{"pos": Vector2(1700, 680), "kind": "crawler"},
		],
		"exit": Vector2(2320, 720),
	})

	# --- Level 5: Core Approach ---
	L.append({
		"name": "Core Approach",
		"bounds": Vector2(2200, 820),
		"spawn": Vector2(90, 700),
		"platforms": [
			Rect2(0, 780, 2200, 40),
			Rect2(300, 640, 160, 24),
			Rect2(560, 540, 160, 24),
			Rect2(820, 640, 160, 24),
			Rect2(1080, 520, 180, 24),
			Rect2(1360, 620, 160, 24),
			Rect2(1620, 500, 180, 24),
			Rect2(1900, 620, 160, 24),
			Rect2(700, 380, 200, 24),
			Rect2(1200, 340, 220, 24),
		],
		"enemies": [
			{"pos": Vector2(360, 600), "kind": "crawler"},
			{"pos": Vector2(620, 500), "kind": "turret"},
			{"pos": Vector2(900, 250), "kind": "flyer"},
			{"pos": Vector2(1140, 480), "kind": "turret"},
			{"pos": Vector2(1450, 250), "kind": "flyer"},
			{"pos": Vector2(1680, 460), "kind": "crawler"},
			{"pos": Vector2(1960, 580), "kind": "turret"},
			{"pos": Vector2(1300, 200), "kind": "flyer"},
		],
		"exit": Vector2(2120, 780),
	})

	return L

static func boss_arena() -> Dictionary:
	return {
		"name": "The Main Computer",
		"bounds": Vector2(1400, 760),
		"spawn": Vector2(200, 660),
		"platforms": [
			Rect2(0, 720, 1400, 40),
			Rect2(120, 560, 180, 24),
			Rect2(1100, 560, 180, 24),
			Rect2(560, 470, 280, 24),
		],
		"enemies": [],
		"exit": Vector2(-999, -999),
	}
