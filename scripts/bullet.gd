extends Node2D

# A projectile. Dies on walls or after its lifetime. team is player or enemy.

var game
var vel: Vector2 = Vector2.ZERO
var dmg: float = 8.0
var team: String = "player"
var radius: float = 2.5
var life: float = 3.0
var pierce: int = 0
var burn: bool = false
var freeze: bool = false
var bounce: int = 0
var col: Color = Color(0.5, 0.95, 1.0)
var t: float = 0.0

func _process(delta: float) -> void:
	if game == null or not game.is_active():
		return
	t += delta
	if game.has_method("core_gravity"):
		vel.y += game.core_gravity() * delta
	position += vel * delta
	life -= delta
	if life <= 0.0:
		game.remove_bullet(self)
		return
	var TILE: int = game.TILE
	var tx: int = int(floor(position.x / TILE))
	var ty: int = int(floor(position.y / TILE))
	# player shots can break barrels / hit targets; hit_tile applies that
	if team == "player":
		if game.hit_tile(tx, ty):
			if bounce > 0:
				bounce -= 1
				_bounce_off(tx, ty)
			else:
				game.remove_bullet(self)
				return
	else:
		if game.is_solid(tx, ty):
			game.remove_bullet(self)
			return
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius + 1.5, Color(col.r, col.g, col.b, 0.28))
	draw_circle(Vector2.ZERO, radius, col)
	draw_circle(Vector2.ZERO, radius * 0.5, Color(1, 1, 1, 0.8))


func _bounce_off(tx: int, ty: int) -> void:
	var TILE: int = game.TILE
	var cxp: int = int(floor((position.x - vel.x * 0.02) / TILE))
	if cxp != tx:
		vel.x = -vel.x
	else:
		vel.y = -vel.y
	position += vel * 0.03
	if game.audio: game.audio.sfx("ehit")
