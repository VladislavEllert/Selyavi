extends Node2D

var _damage: int = 4
var _duration: float = 2.5
var _tick_timer: float = 0.0
const TICK_INTERVAL: float = 0.4

func _ready():
	# Визуальные эффекты огня через частицы
	var particles = CPUParticles2D.new()
	add_child(particles)
	particles.amount = 25
	particles.lifetime = 0.7
	particles.texture = load("res://assets/future_tanks/PNG/Effects/Explosion_C.png")
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 12.0
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.gravity = Vector2(0, 0)
	particles.initial_velocity_min = 5.0
	particles.initial_velocity_max = 20.0
	particles.scale_amount_min = 0.04
	particles.scale_amount_max = 0.12

	var gradient = Gradient.new()
	gradient.set_color(0, Color(1, 0.9, 0.3, 1)) # Желтое ядро
	gradient.add_point(0.4, Color(1, 0.4, 0, 0.8)) # Оранжевый
	gradient.add_point(1.0, Color(0.4, 0.1, 0, 0)) # Затухание
	particles.color_ramp = gradient

	# Область урона
	var area = Area2D.new()
	area.name = "DamageArea"
	add_child(area)
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 20.0
	shape.shape = circle
	area.add_child(shape)
	area.collision_mask = 2 # Маска игрока

	# Плавное исчезновение
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, _duration).set_delay(_duration * 0.5)
	tween.finished.connect(queue_free)

func _process(delta):
	_tick_timer += delta
	if _tick_timer >= TICK_INTERVAL:
		_tick_timer = 0.0
		_check_damage()

func _check_damage():
	var area = get_node("DamageArea")
	for body in area.get_overlapping_bodies():
		if body is Player:
			body.take_damage(_damage, true) # Игнорируем неуязвимость, так как это огонь
			if body.has_method("apply_burn"):
				body.apply_burn(0.8)
