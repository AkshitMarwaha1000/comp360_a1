extends Node3D

# ============ Tunables (edit in Inspector) ============
@export var img_size: int = 128
@export var rows: int = 16
@export var cols: int = 16
@export var grid_w: float = 20.0
@export var grid_h: float = 20.0
@export var height_scale: float = 12.0

# Noise
@export var seed: int = 1337
@export var frequency: float = 0.02
@export var octaves: int = 4
@export var randomize_seed_on_regen: bool = false

# ============ State ============
var height_img: Image
var height_tex: ImageTexture
@onready var landscape: MeshInstance3D = null

# HUD
var hud_layer: CanvasLayer
var hud_label: Label
var hud_button: Button
var hud_preview: TextureRect

# ============ Lifecycle ============
func _ready() -> void:
	# ensure mesh instance
	landscape = get_node_or_null("Landscape") as MeshInstance3D
	if landscape == null:
		landscape = MeshInstance3D.new()
		landscape.name = "Landscape"
		add_child(landscape)

	_build_hud()
	_rebuild_all()
	_update_hud()
	print("terrain ready")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		_regenerate()

# ============ HUD ============
func _build_hud() -> void:
	hud_layer = CanvasLayer.new()
	add_child(hud_layer)

	var root := MarginContainer.new()
	root.add_theme_constant_override("margin_left", 8)
	root.add_theme_constant_override("margin_top", 8)
	root.add_theme_constant_override("margin_right", 8)
	root.add_theme_constant_override("margin_bottom", 8)
	hud_layer.add_child(root)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	root.add_child(vbox)

	hud_label = Label.new()
	hud_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(hud_label)

	var hbox := HBoxContainer.new()
	vbox.add_child(hbox)

	hud_button = Button.new()
	hud_button.text = "Regenerate (R)"
	hud_button.pressed.connect(_regenerate)
	hbox.add_child(hud_button)

	hud_preview = TextureRect.new()
	hud_preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	hud_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hud_preview.custom_minimum_size = Vector2(160, 160)   # <-- fixed name
	hud_preview.modulate = Color(1, 1, 1, 0.9)
	vbox.add_child(hud_preview)

func _update_hud() -> void:
	hud_label.text = "seed: %d   freq: %.3f   octaves: %d\nimg: %d   grid: %dx%d   scale: %.1f" % [
		seed, frequency, octaves, img_size, cols, rows, height_scale
	]
	if height_tex:
		hud_preview.texture = height_tex

func _regenerate() -> void:
	if randomize_seed_on_regen:
		seed = randi()
	_rebuild_all()
	_update_hud()
	print("terrain regenerated")

# ============ Build pipeline ============
func _rebuild_all() -> void:
	_build_heightmap()
	_build_grid_mesh()

	var mat := StandardMaterial3D.new()
	mat.albedo_texture = height_tex
	mat.roughness = 1.0
	landscape.material_override = mat

# Create grayscale heightmap with FastNoiseLite
func _build_heightmap() -> void:
	var fnl := FastNoiseLite.new()
	fnl.seed = seed
	fnl.noise_type = FastNoiseLite.TYPE_CELLULAR
	fnl.frequency = frequency
	fnl.fractal_type = FastNoiseLite.FRACTAL_FBM
	fnl.fractal_octaves = octaves

	height_img = Image.create(img_size, img_size, false, Image.FORMAT_RGBA8)

	for y in range(img_size):
		for x in range(img_size):
			var n: float = fnl.get_noise_2d(x, y)              # -1..1
			var g: float = clamp((n + 1.0) * 0.5, 0.0, 1.0)    # 0..1
			var u8: int = int(g * 255.0)
			height_img.set_pixel(x, y, Color8(u8, u8, u8, 255))

	height_tex = ImageTexture.create_from_image(height_img)

# Sample height at UV
func _sample_height(u: float, v: float) -> float:
	var px: int = clamp(int(round(u * (img_size - 1))), 0, img_size - 1)
	var py: int = clamp(int(round(v * (img_size - 1))), 0, img_size - 1)
	var g: float = height_img.get_pixel(px, py).r
	return g * height_scale

# Build mesh from heightmap
func _build_grid_mesh() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for r in range(rows):
		for c in range(cols):
			var u0: float = float(c)   / float(cols)
			var v0: float = float(r)   / float(rows)
			var u1: float = float(c + 1) / float(cols)
			var v1: float = float(r + 1) / float(rows)

			var x0: float = lerp(-grid_w * 0.5, grid_w * 0.5, u0)
			var x1: float = lerp(-grid_w * 0.5, grid_w * 0.5, u1)
			var z0: float = lerp(-grid_h * 0.5, grid_h * 0.5, v0)
			var z1: float = lerp(-grid_h * 0.5, grid_h * 0.5, v1)

			var h00: float = _sample_height(u0, v0)
			var h10: float = _sample_height(u1, v0)
			var h01: float = _sample_height(u0, v1)
			var h11: float = _sample_height(u1, v1)

			var p00 := Vector3(x0, h00, z0)
			var p10 := Vector3(x1, h10, z0)
			var p01 := Vector3(x0, h01, z1)
			var p11 := Vector3(x1, h11, z1)

			# tri 1
			st.set_uv(Vector2(u0, v0)); st.add_vertex(p00)
			st.set_uv(Vector2(u1, v0)); st.add_vertex(p10)
			st.set_uv(Vector2(u1, v1)); st.add_vertex(p11)
			# tri 2
			st.set_uv(Vector2(u0, v0)); st.add_vertex(p00)
			st.set_uv(Vector2(u1, v1)); st.add_vertex(p11)
			st.set_uv(Vector2(u0, v1)); st.add_vertex(p01)

	var mesh: ArrayMesh = st.commit()
	landscape.mesh = mesh
