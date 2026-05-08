extends Area2D

var _velocity: Vector2 = Vector2.ZERO
var _speed: float = 400.0
var _damage: int = 25
var _is_active: bool = true

# Таймер игнорирования стен (чтобы пролетать сквозь внешние стены карты при спавне)
var _wall_ignore_timer: float = 1.2

func init(pos: Vector2, dir: Vector2, damage: int):
	global_position = pos
	_velocity = dir.normalized()
	_damage = damage
	rotation = _velocity.angle() + PI/2

func _ready():
	# Настройка коллизий: маска 3 (слои 1 - стены, 2 - игроки)
	collision_layer = 0
	collision_mask = 3

	# Поднимаем снаряд выше всего на поле боя
	z_index = 100
	z_as_relative = false

	body_entered.connect(_on_body_entered)

	# Визуал: яркая плазменная искра
	var sprite = Sprite2D.new()
	sprite.texture = load("res://assets/future_tanks/PNG/Effects/Plasma.png")
	sprite.modulate = Color(3.5, 0.8, 0.2)
	sprite.scale = Vector2(1.1, 1.1)
	add_child(sprite)

	# Создаем коллизию программно
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 26.0
	collision.shape = shape
	add_child(collision)

func _physics_process(delta):
	if not _is_active: return
	position += _velocity * _speed * delta

	if _wall_ignore_timer > 0:
		_wall_ignore_timer -= delta

	# Удаление при вылете далеко за пределы
	if global_position.distance_to(Vector2.ZERO) > 10000:
		queue_free()

func _on_body_entered(body):
	if not _is_active: return

	# Если попали в игрока - всегда наносим урон
	if body is Player or body.is_in_group("players"):
		if body.has_method("take_damage"):
			body.take_damage(_damage, true)
		if body.has_method("apply_burn"):
			body.apply_burn(1.5)
		_destroy()
		return

	# Если это стена (слой 1), уничтожаемся только если вышли из фазы игнорирования
	if _wall_ignore_timer <= 0:
		_destroy()

func _destroy():
	if not _is_active: return
	_is_active = false
	queue_free()
