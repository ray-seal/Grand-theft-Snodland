extends Node3D

const SAVE_PATH := "user://snodland_save.cfg"
const STATION_START := Vector3(0, 0.1, 13)
const RENTAL_POSITION := Vector3(0, 0, -20)
const FLAT_POSITION := Vector3(0, 0, -25)
const STARTING_MONEY := 500
const RENT_PRICE := 450

var player: SnodlandPlayer
var camera: Camera3D
var rental_marker: Node3D
var hud: Label
var ui_root: Control
var objective: Label
var money_label: Label
var dialogue_panel: PanelContainer
var mission_started := false
var rented := false
var saved_once := false
var money := 0
var key_e_was_down := false
var materials: Dictionary = {}

func _ready() -> void:
	_make_materials()
	_make_blockout_world()
	_make_player()
	_make_camera()
	_make_ui()
	if not _load_saved_game():
		_show_opening_message()

func _process(delta: float) -> void:
	if player == null: return
	_update_camera(delta)
	_update_hud()
	if rental_marker and not rented:
		rental_marker.rotate_y(delta)
		rental_marker.position.y = 0.2 + sin(Time.get_ticks_msec() * 0.003) * 0.12
	_check_interaction()

func _material(color: Color, transparent := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.9
	if transparent:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

func _make_materials() -> void:
	materials = {
		"grass": _material(Color("#71966a")),
		"road": _material(Color("#34383d")),
		"pavement": _material(Color("#aaa99f")),
		"brick": _material(Color("#985e4c")),
		"building": _material(Color("#c7b9a2")),
		"roof": _material(Color("#55565b")),
		"glass": _material(Color("#547d9a")),
		"tree": _material(Color("#426f4b")),
		"player": _material(Color("#e6b34f")),
		"npc": _material(Color("#4d82a6")),
		"red": _material(Color("#a9433d")),
		"blue": _material(Color("#416d9a")),
		"white": _material(Color("#e8e5d9")),
		"marker": _material(Color(1.0, 0.78, 0.12, 0.82), true)
	}

func _box(parent: Node3D, label: String, pos: Vector3, size: Vector3, mat: Material, collision := false) -> MeshInstance3D:
	var body := StaticBody3D.new()
	body.name = label
	body.position = pos
	parent.add_child(body)
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.material_override = mat
	body.add_child(visual)
	if collision:
		var shape_node := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		shape_node.shape = shape
		body.add_child(shape_node)
	return visual

func _building(pos: Vector3, size: Vector3, mat: Material) -> void:
	_box(self, "Building", pos, size, mat)
	_box(self, "Roof", pos + Vector3(0, size.y * 0.52, 0), Vector3(size.x + 0.35, 0.3, size.z + 0.35), materials.roof)

func _make_blockout_world() -> void:
	_box(self, "Ground", Vector3(0, -0.3, -4), Vector3(70, 0.6, 82), materials.grass, true)
	_box(self, "Station forecourt", Vector3(0, 0.02, 13), Vector3(22, 0.12, 18), materials.pavement, true)
	_box(self, "Road to High Street", Vector3(0, 0.02, -4), Vector3(8, 0.14, 42), materials.road, true)
	_box(self, "High Street road", Vector3(0, 0.02, -20), Vector3(28, 0.16, 12), materials.road, true)
	_box(self, "North pavement", Vector3(0, 0.08, -14), Vector3(30, 0.2, 4), materials.pavement, true)
	_box(self, "South pavement", Vector3(0, 0.08, -26), Vector3(30, 0.2, 4), materials.pavement, true)
	_building(Vector3(-14, 1.5, 13), Vector3(5, 3, 9), materials.building)
	_box(self, "Station platform", Vector3(-9, 0.25, 13), Vector3(3, 0.5, 15), materials.white, true)
	_building(Vector3(0, 1.8, -29), Vector3(10, 3.6, 7), materials.brick)
	_box(self, "Shop frontage", Vector3(0, 0.85, -25.35), Vector3(8.8, 1.7, 0.18), materials.white)
	_box(self, "Flat windows", Vector3(0, 2.65, -25.25), Vector3(5.8, 1.0, 0.15), materials.glass)
	for i in range(4):
		var z := -8.0 - float(i) * 9.0
		_building(Vector3(-18, 1.4, z), Vector3(7, 2.8, 6), materials.building)
		_building(Vector3(18, 1.6, z - 3), Vector3(8, 3.2, 7), materials.brick)
	_add_tree(Vector3(-7, 0, 2))
	_add_tree(Vector3(8, 0, 5))
	_add_tree(Vector3(-12, 0, -10))
	_add_tree(Vector3(12, 0, -17))
	_add_car(Vector3(-5, 0, 12), materials.blue)
	_add_car(Vector3(6, 0, -13), materials.red)
	_add_npc(Vector3(3, 0, 10))
	_add_npc(Vector3(-5, 0, -12))
	_add_npc(Vector3(8, 0, -23))
	_make_rental_marker()

func _add_tree(pos: Vector3) -> void:
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.16
	trunk_mesh.bottom_radius = 0.22
	trunk_mesh.height = 1.4
	trunk.mesh = trunk_mesh
	trunk.material_override = materials.brick
	trunk.position = pos + Vector3(0, 0.7, 0)
	add_child(trunk)
	var crown := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.9
	sphere.height = 1.8
	crown.mesh = sphere
	crown.material_override = materials.tree
	crown.position = pos + Vector3(0, 2.0, 0)
	add_child(crown)

func _add_car(pos: Vector3, mat: Material) -> void:
	var car := Node3D.new()
	car.name = "Parked placeholder car"
	car.position = pos
	add_child(car)
	_box(car, "Car body", Vector3(0, 0.65, 0), Vector3(1.8, 0.8, 3.4), mat)
	_box(car, "Car cabin", Vector3(0, 1.25, -0.1), Vector3(1.45, 0.55, 1.8), materials.white)

func _add_npc(pos: Vector3) -> void:
	var npc := Node3D.new()
	npc.name = "Placeholder resident"
	npc.position = pos
	add_child(npc)
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.34
	capsule.height = 1.65
	body.mesh = capsule
	body.material_override = materials.npc
	body.position.y = 0.83
	npc.add_child(body)

func _make_rental_marker() -> void:
	rental_marker = Node3D.new()
	rental_marker.name = "Starter flat rental marker"
	rental_marker.position = RENTAL_POSITION + Vector3(0, 0.2, 3)
	add_child(rental_marker)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.75
	torus.outer_radius = 1.0
	ring.mesh = torus
	ring.material_override = materials.marker
	rental_marker.add_child(ring)
	var beacon := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.08
	cylinder.bottom_radius = 0.38
	cylinder.height = 1.8
	beacon.mesh = cylinder
	beacon.material_override = materials.marker
	beacon.position.y = 0.9
	rental_marker.add_child(beacon)

func _make_player() -> void:
	player = SnodlandPlayer.new()
	player.name = "Player"
	player.position = STATION_START
	var collider := CollisionShape3D.new()
	var capsule_shape := CapsuleShape3D.new()
	capsule_shape.radius = 0.36
	capsule_shape.height = 1.7
	collider.shape = capsule_shape
	collider.position.y = 0.85
	player.add_child(collider)
	var visual := MeshInstance3D.new()
	var capsule_mesh := CapsuleMesh.new()
	capsule_mesh.radius = 0.36
	capsule_mesh.height = 1.7
	visual.mesh = capsule_mesh
	visual.material_override = materials.player
	visual.position.y = 0.85
	player.add_child(visual)
	add_child(player)

func _make_camera() -> void:
	camera = Camera3D.new()
	camera.name = "Elevated top-down camera"
	camera.current = true
	camera.fov = 52
	camera.position = player.position + Vector3(0, 19, 15)
	add_child(camera)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -25, 0)
	sun.light_energy = 1.1
	add_child(sun)
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#a9bac8")
	env.ambient_light_energy = 0.65
	world.environment = env
	add_child(world)

func _make_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)
	ui_root = root
	objective = Label.new()
	objective.position = Vector2(22, 18)
	objective.add_theme_font_size_override("font_size", 22)
	objective.add_theme_color_override("font_color", Color.WHITE)
	root.add_child(objective)
	money_label = Label.new()
	money_label.position = Vector2(22, 52)
	money_label.add_theme_font_size_override("font_size", 19)
	money_label.add_theme_color_override("font_color", Color("#f1d66b"))
	root.add_child(money_label)
	hud = Label.new()
	hud.anchor_left = 0.5
	hud.anchor_right = 0.5
	hud.anchor_top = 1.0
	hud.anchor_bottom = 1.0
	hud.offset_left = -330
	hud.offset_right = 330
	hud.offset_top = -58
	hud.offset_bottom = -18
	hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_theme_font_size_override("font_size", 18)
	hud.add_theme_color_override("font_color", Color.WHITE)
	root.add_child(hud)
	_update_hud()

func _show_opening_message() -> void:
	player.controls_enabled = false
	dialogue_panel = PanelContainer.new()
	dialogue_panel.anchor_left = 0.5
	dialogue_panel.anchor_right = 0.5
	dialogue_panel.anchor_top = 1.0
	dialogue_panel.anchor_bottom = 1.0
	dialogue_panel.offset_left = -390
	dialogue_panel.offset_right = 390
	dialogue_panel.offset_top = -235
	dialogue_panel.offset_bottom = -30
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.075, 0.09, 0.97)
	style.border_color = Color("#d7bd65")
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(22)
	dialogue_panel.add_theme_stylebox_override("panel", style)
	ui_root.add_child(dialogue_panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	dialogue_panel.add_child(content)
	var heading := Label.new()
	heading.text = "INCOMING MESSAGE"
	heading.add_theme_font_size_override("font_size", 16)
	heading.add_theme_color_override("font_color", Color("#f1d66b"))
	content.add_child(heading)
	var message := Label.new()
	message.text = "bruv you’re gonna love this town, I’ve sent you some money there’s a flat to rent down the high street, gimme a bell when you’ve got it"
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size", 21)
	content.add_child(message)
	var button := Button.new()
	button.text = "Put phone away  •  Let's go"
	button.custom_minimum_size.y = 48
	button.pressed.connect(_begin_mission)
	content.add_child(button)

func _begin_mission() -> void:
	mission_started = true
	money = STARTING_MONEY
	player.controls_enabled = true
	dialogue_panel.queue_free()
	_update_hud()

func _update_camera(delta: float) -> void:
	var target := player.global_position + Vector3(0, 19, 15)
	camera.global_position = camera.global_position.lerp(target, minf(1.0, delta * 5.0))
	camera.look_at(player.global_position + Vector3(0, 0.5, 0), Vector3.UP)

func _update_hud() -> void:
	if objective == null: return
	if not mission_started:
		objective.text = "MISSION 001  •  A NEW START"
	elif not rented:
		objective.text = "A NEW START  •  Find the flat on the High Street"
	elif not saved_once:
		objective.text = "A NEW START  •  Head home and save your game"
	else:
		objective.text = "SNODLAND  •  Game saved. You're home."
	if money_label:
		money_label.text = "£%04d" % money
		if mission_started and not rented:
			money_label.text += "  •  £%d reserved for rent" % RENT_PRICE
	if hud:
		if not mission_started:
			hud.text = "Read your message to get started"
		elif not rented and player.global_position.distance_to(RENTAL_POSITION) < 5.0:
			hud.text = "Press E to rent the starter flat  •  £%d" % RENT_PRICE
		elif rented and player.global_position.distance_to(FLAT_POSITION) < 5.0:
			hud.text = "Press E to save your game"
		elif not rented:
			hud.text = "Follow the route to the High Street  •  WASD / arrows to move"
		else:
			hud.text = "Your flat is your save point  •  WASD / arrows to move"

func _check_interaction() -> void:
	var down := Input.is_key_pressed(KEY_E)
	if down and not key_e_was_down and mission_started:
		if not rented and player.global_position.distance_to(RENTAL_POSITION) < 4.0:
			_rent_flat()
		elif rented and player.global_position.distance_to(FLAT_POSITION) < 4.0:
			_save_game()
	key_e_was_down = down

func _rent_flat() -> void:
	if money < RENT_PRICE:
		hud.text = "You haven't got enough money for the rent."
		return
	money -= RENT_PRICE
	rented = true
	if is_instance_valid(rental_marker):
		rental_marker.queue_free()
	_add_home_marker()
	_update_hud()
	hud.text = "MISSION PASSED  •  Flat rented! Head inside and save."

func _add_home_marker() -> void:
	var home := MeshInstance3D.new()
	home.name = "Flat entrance and save point"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.5, 0.12, 1.5)
	home.mesh = mesh
	home.material_override = materials.marker
	home.position = FLAT_POSITION + Vector3(0, 0.12, 0)
	add_child(home)

func _save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "rented", rented)
	cfg.set_value("progress", "money", money)
	cfg.set_value("player", "x", player.global_position.x)
	cfg.set_value("player", "z", player.global_position.z)
	var result := cfg.save(SAVE_PATH)
	if result == OK:
		saved_once = true
		_update_hud()
		hud.text = "GAME SAVED  •  Welcome home."
	else:
		hud.text = "Save failed. Check available storage."

func _load_saved_game() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return false
	if not bool(cfg.get_value("progress", "rented", false)):
		return false
	rented = true
	mission_started = true
	money = int(cfg.get_value("progress", "money", 0))
	player.global_position = Vector3(
		float(cfg.get_value("player", "x", FLAT_POSITION.x)),
		0.1,
		float(cfg.get_value("player", "z", FLAT_POSITION.z))
	)
	player.controls_enabled = true
	_add_home_marker()
	_update_hud()
	return true
