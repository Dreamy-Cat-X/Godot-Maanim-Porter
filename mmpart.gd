class_name MMPart
extends Sprite2D

const MM_PAR := 0
const MM_SPR := 2
const MM_ZOR := 3
const MM_POSX := 4
const MM_POSY := 5
const MM_PIVX := 6
const MM_PIVY := 7
const MM_SCAX := 8
const MM_SCAY := 9
const MM_ANGL := 10
const MM_OPA := 11
const MM_BLEN := 12
##This is the path that leads to the glow shader file
const GLOW_FILE = "res://maanim/glow.gdshader"

var def_par : int
var def_id : int
var def_spr : int
var def_zor : int
var def_posx : int
var def_posy : int
var def_pivx : int
var def_pivy : int
var def_scax : float
var def_scay : float
var def_angl : float
var def_opa : float
var def_glw : int

var model : MaModel
var spr : int
var mm_z : int
var vsca : float = 1
var rot_scah : bool = false
var rot_scav : bool = false
var rot_h : bool = false
var rot_v : bool = false
var par : MMPart = null
var vset : bool
var set_pos : Vector2
var extV : Vector2

##These are all for Randomized Extend
var spr_ref : int
var rand = false
var rands : Array[int] = []
var randCuts : Array[int] = []

func _init(mamodel: MaModel, sprite : Texture2D, id : int, arr : Array[int], namae : String) -> void:
	model = mamodel
	def_id = id
	def_par = arr[MM_PAR]
	def_spr = arr[MM_SPR]
	def_zor = arr[MM_ZOR]
	def_posx = arr[MM_POSX]
	def_posy = arr[MM_POSY]
	def_pivx = arr[MM_PIVX]
	def_pivy = arr[MM_PIVY]
	def_scax = arr[MM_SCAX]
	def_scay = arr[MM_SCAY]
	def_angl = arr[MM_ANGL]
	def_opa = arr[MM_OPA]
	def_glw = arr[MM_BLEN]
	set_pos = Vector2(def_posx, def_posy)
	
	spr_ref = def_spr
	texture = sprite
	centered = false
	region_enabled = true
	if def_glw != 0 && def_glw <= 1:
		var mat = CanvasItemMaterial.new()
		material = mat
		if def_glw == 1:
			mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		else:
			mat.blend_mode = CanvasItemMaterial.BLEND_MODE_SUB
	elif def_glw >= 2 && def_glw <= 3:
		var mat = ShaderMaterial.new()
		material = mat
		mat.shader = load(GLOW_FILE)
		mat.set_shader_parameter("glow_type",def_glw)
	if !namae.is_empty():
		name = namae
	else:
		name = String.num_uint64(def_id)

func _draw() -> void:
	if extV.x <= 1 && extV.y <= 1:
		return
	if def_glw >= 2 && def_glw <= 3:
		material.set_shader_parameter("alpha",modulate.a)
	var ex = Vector2(0, 1)
	var rind = 0
	
	while extV.x - ex.x > 0:
		while extV.y - ex.y > 0:
			var exW = Vector2(region_rect.size.x * minf((extV.x - ex.x), 1), region_rect.size.y * minf((extV.y - ex.y), 1))
			var rct
			if rand:
				if rind >= rands.size():
					rands.append(randi_range(0, randCuts.size() - 1))
				rct = model.ic_rects[randCuts[rands[rind]]]
			else:
				rct = region_rect
			draw_texture_rect_region(texture, Rect2(Vector2(ex * rct.size + offset), exW), Rect2(rct.position, exW))
			ex.y += 1
			rind += 1
		ex.y = 0
		ex.x += 1

func reset(parsync : bool) -> void:
	par = model.mm_parts[def_par] if def_par != -1 else null
	vset = par == null
	spr = def_spr
	region_rect = model.ic_rects[spr]
	mm_z = def_zor
	offset.x = -def_pivx
	offset.y = -def_pivy
	vsca = 1

	scale.x = def_scax
	scale.y = def_scay
	rotation = def_angl * PI * (2 if model.scale.x * model.scale.y >= 0 else -2)
	modulate.a = def_opa
	extV = Vector2.ONE
	
	if parsync:
		if par != null:
			a_set()
		else:
			position.x = def_pivx
			position.y = def_pivy
		rands.clear()
		spr_ref = spr

	rand = false
	rot_h = false
	rot_v = false
	rot_scah = false
	rot_scav = false

func a_set(last : bool = false) -> bool: ##Returns true if the class was not set, but CAN be set
	if (vset || par == null):
		return false
	if (!par.vset && (par.def_id > def_id) == last):
		return true
	
	scale *= par.scale * vsca
	rotation += par.rotation
	modulate.a *= par.modulate.a
	reparent(par) ##Most efficient flaw-free way I know of
	position = set_pos
	reparent(model)
	
	set_pos = Vector2(def_posx, def_posy)
	vset = true
	queue_redraw()
	return false

func get_model_children() -> Array[MMPart]:
	var chdr : Array[MMPart]
	for part in model.mm_parts:
		if part.def_par != -1 && (part.def_par == def_id || chdr.has(model.mm_parts[part.def_par])):
			chdr.append(part)
	return chdr

func extend(v : float, y : bool) -> void:
	if v == 0:
		v = 1
	if y:
		extV.y = v
	else:
		extV.x = v
	
	if region_rect != model.ic_rects[spr] && extV.x >= 1 && extV.y >= 1:
		region_rect = model.ic_rects[spr]
	elif v < 1:
		if region_rect == model.ic_rects[spr]:
			region_rect = Rect2(model.ic_rects[spr])
		if y:
			region_rect.size.y = v
		else:
			region_rect.size.x = v
