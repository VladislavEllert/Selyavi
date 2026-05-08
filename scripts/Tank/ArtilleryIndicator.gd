extends Node2D

var _radius: float = 130.0
var _damage: int = 45
var _timer: float = 0.0
var _duration: float = 2.5 # Время до удара
var _shell_texture: Texture2D
var _is_inferno_phase2: bool = false # Флаг для второй фазы Инферно

const FIRE_PATCH_SCRIPT = preload("res://scripts/FirePatch.gd")

func _ready():
	_shell_texture = load("res://assets/future_tanks/PNG/Effects/Heavy_Shell.png")
	queue_redraw()
	_play_incoming_sound()

func _process(delta):
	_timer += delta
	queue_redraw()
	if _timer >= _duration:
		_explode()
		queue_free()

func _draw():
	# Рисуем контур (у Инферно он более "злой")
	var color = Color(1, 0.2, 0, 0.8) if _is_inferno_phase2 else Color(1, 0, 0, 0.6)
	draw_arc(Vector2.ZERO, _radius, 0, TAU, 64, color, 3.0 + (1.0 if _is_inferno_phase2 else 0.0))

	# Рисуем заполняющийся круг
	var fill_ratio = _timer / _duration
	draw_circle(Vector2.ZERO, _radius * fill_ratio, Color(1, 0.1, 0, 0.45) if _is_inferno_phase2 else Color(1, 0, 0, 0.35))

	if _shell_texture:
		var fill_inv = 1.0 - fill_ratio
		var shell_pos = Vector2(0, -600 * fill_inv)
		var shell_scale = 0.4 + 0.6 * fill_inv
		draw_set_transform(shell_pos, PI, Vector2(shell_scale, shell_scale))
		draw_texture(_shell_texture, -_shell_texture.get_size() / 2.0)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

func _explode():
	_spawn_explosion_effects()

	var space_state = get_world_2d().direct_space_state
	var shape = CircleShape2D.new()
	shape.radius = _radius

	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = global_transform
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var results = space_state.intersect_shape(query)
	var targets_to_damage = {}

	for result in results:
		var collider = result.collider
		if not is_instance_valid(collider): continue
		var final_target = collider
		if not final_target.has_method("take_damage"):
			if final_target.get_parent() and final_target.get_parent().has_method("take_damage"):
				final_target = final_target.get_parent()

		if final_target.has_method("take_damage"):
			targets_to_damage[final_target.get_instance_id()] = final_target

	for target_id in targets_to_damage:
		var target = targets_to_damage[target_id]
		if target.is_in_group("players") or target.is_in_group("bases") or target.has_method("destroyable"):
			var final_dmg = _damage
			# Спец-эффекты для Инферно
			if _is_inferno_phase2 and target.is_in_group("players"):
				final_dmg += 10
				if target.has_method("apply_burn"):
					target.apply_burn(2.5) # Мощный поджог

			if target.is_in_group("players"):
				target.take_damage(final_dmg, _is_inferno_phase2) # Фаза 2 игнорирует инвул
			else:
				target.take_damage(final_dmg)

	# Оставляем "раскаленную зону" после взрыва
	if _is_inferno_phase2:
		_spawn_fire_zone()

func _spawn_fire_zone():
	# Создаем группу огней в месте взрыва
	for i in range(4):
		var patch = Node2D.new()
		patch.set_script(FIRE_PATCH_SCRIPT)
		# Разбрасываем огонь внутри радиуса взрыва
		var offset = Vector2(randf_range(-_radius*0.6, _radius*0.6), randf_range(-_radius*0.6, _radius*0.6))
		patch.global_position = global_position + offset
		get_parent().add_child(patch)

func _spawn_explosion_effects():
	if AudioManager:
		AudioManager.play_bullet_sound(1, global_position)

func _play_incoming_sound():
	pass
