extends Control

const PADDING: float = 30.0
const CELL_SIZE = Vector2(17.0, 20.0)
const FONT_SIZE: int = 13
const AURA_COLOR = Color(0.3, 0.95, 0.85)

var _slot: Control
var _elapsed: float = 0.0
var _font = SystemFont.new()
var _glow = StyleBoxFlat.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	_font.font_names = PackedStringArray(["Consolas", "Courier New"])
	_glow.set_corner_radius_all(12)
	_glow.set_border_width_all(2)
	_glow.shadow_size = 22
	hide()
	set_process(false)

func follow_slot(slot: Control) -> void:
	_slot = slot
	_elapsed = 0.0
	_update_bounds()
	show()
	set_process(true)
	queue_redraw()

func clear() -> void:
	_slot = null
	hide()
	set_process(false)

func _update_bounds() -> void:
	# The aura and slot buttons share a parent; use the actual button size.
	position = _slot.position - Vector2.ONE * PADDING
	size = _slot.size + Vector2.ONE * PADDING * 2.0

func _process(delta: float) -> void:
	if not is_instance_valid(_slot):
		clear()
		return
	_elapsed += delta
	_update_bounds()
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(_slot):
		return
	var slot_rect = Rect2(Vector2.ONE * PADDING, _slot.size)
	var pulse: float = 0.5 + 0.5 * sin(_elapsed * 2.0)
	_glow.bg_color = Color(AURA_COLOR, 0.07)
	_glow.border_color = Color(AURA_COLOR, 0.65 + pulse * 0.2)
	_glow.shadow_color = Color(AURA_COLOR, 0.2 + pulse * 0.1)
	draw_style_box(_glow, slot_rect.grow(5.0))

	# Slow binary streams surround the disk without covering its labels.
	var scroll: float = _elapsed * 11.0
	var row_shift: int = int(floor(scroll / CELL_SIZE.y))
	var columns: int = int(ceil(size.x / CELL_SIZE.x))
	var rows: int = int(ceil(size.y / CELL_SIZE.y)) + 1
	for column in range(columns):
		for row in range(-1, rows):
			var point = Vector2(
				float(column) * CELL_SIZE.x + 5.0,
				float(row) * CELL_SIZE.y + fmod(scroll, CELL_SIZE.y)
			)
			var glyph_rect = Rect2(point, Vector2(10.0, float(FONT_SIZE)))
			if slot_rect.grow(7.0).intersects(glyph_rect):
				continue
			var edge: float = minf(minf(point.x, size.x - point.x - 10.0), minf(point.y, size.y - point.y - FONT_SIZE))
			if edge <= 0.0:
				continue
			var seed: int = absi(column * 73 + (row - row_shift) * 37)
			var digit: String = "1" if ((seed ^ (seed >> 3)) & 1) == 0 else "0"
			var shimmer: float = 0.55 + 0.25 * sin(_elapsed * 1.4 + float(seed))
			var alpha: float = smoothstep(0.0, 10.0, edge) * shimmer
			draw_string(_font, point + Vector2(0.0, float(FONT_SIZE)), digit, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, Color(AURA_COLOR, alpha))
