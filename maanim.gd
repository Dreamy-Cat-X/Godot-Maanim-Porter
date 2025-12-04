class_name MaAnim
extends RefCounted

const PARENT = 0
const ID = 1
const SPRITE = 2
const Z_ORDER = 3
const POS_X = 4
const POS_Y = 5
const PIVOT_X = 6
const PIVOT_Y = 7
const SCALE = 8
const SCALE_X = 9
const SCALE_Y = 10
const ROTATION = 11
const OPACITY = 12
const H_FLIP = 13
const V_FLIP = 14
const EXTEND_X = 50
const EXTEND_X_RAND = 51
const EXTEND_Y = 52
const G_SCALE = 53
const EXTEND_Y_RAND = 54

var model : MaModel
var modifs : Array[MaPart]
var cur_f : float = -1
var lastF = 0

func _init(m : MaModel, dir : String, name : String) -> void:
	model = m
	var adat = FileAccess.open(dir + name, FileAccess.READ)
	if adat == null:
		return
	var content = adat.get_as_text()
	adat.close()
	var lines = content.split("\n")
	var l = 3
	while l < lines.size():
		if lines[l].is_empty():
			break
		var np = MaPart.new(l, lines, m.mm_parts)
		modifs.append(np)
		lastF = max(lastF, np.duration())
		l += 2 + np.size()

func update(delta : float) -> void:
	model.resetAnim(false)
	cur_f += delta
	for mod in modifs:
		if mod.tmods.is_empty():
			continue
		var ani_f : float = cur_f if cur_f >= 0 else (mod.duration() + cur_f)
		if ani_f >= 0 && mod.tmods.size() >= 2 && (mod.pmods[MaPart.P_LOOP] == -1 || mod.tmods[-1].frame * mod.pmods[MaPart.P_LOOP] > cur_f):
			while ani_f >= mod.tmods[-1].frame:
				ani_f -= mod.tmods[-1].frame-mod.tmods[0].frame
		elif ani_f < 0:
			if mod.duration() > 0 && mod.pmods[MaPart.P_LOOP] == -1:
				while ani_f < 0:
					ani_f += mod.duration()
			else:
				ani_f = 0
		if ani_f < mod.tmods[0].frame:
			continue
		var p_ind = 0
		while p_ind < mod.tmods.size() - 1 && ani_f >= mod.tmods[p_ind + 1].frame:
			p_ind += 1
		var prog : float
		var value : float
		if p_ind < mod.tmods.size() - 1:
			prog = (ani_f-mod.tmods[p_ind].frame)/(mod.tmods[p_ind + 1].frame-mod.tmods[p_ind].frame)
			if mod.tmods[p_ind].ease_typ == 2:
					if mod.tmods[p_ind].ease_deg >= 0:
						prog = 1 - sqrt(1 - pow(prog, mod.tmods[p_ind].ease_deg))
					else:
						prog = sqrt(1 - pow(1 - prog, -mod.tmods[p_ind].ease_deg))
			elif mod.tmods[p_ind].ease_typ == 4:
				if (mod.tmods[p_ind].ease_deg > 0):
					prog = 1 - cos(prog * PI / 2);
				elif (mod.tmods[p_ind].ease_deg < 0):
					prog = sin(prog * PI / 2)
				else:
					prog = (1 - cos(prog * PI)) / 2;
			elif mod.tmods[p_ind].ease_typ == 1:
				prog = floor(prog*mod.tmods[p_ind].ease_deg)/mod.tmods[p_ind].ease_deg if mod.tmods[p_ind].ease_deg != 0 else 0
			if mod.tmods[p_ind].ease_typ == 3:
				value = mod.ease3(p_ind, ani_f);
			else:
				value = mod.tmods[p_ind].value + ((mod.tmods[p_ind + 1].value - mod.tmods[p_ind].value) * prog)
		else:
			value = mod.tmods[p_ind].value
		
		var part = model.mm_parts[mod.pmods[MaPart.P_PART]]
		match mod.pmods[MaPart.P_MOD]:
			PARENT:
				var v = floori(value)
				part.par = model.mm_parts[v] if v != -1 else null
			ID:
				part.def_id = floori(value)
			SPRITE:
				var v = floori(value)
				if part.rand && part.spr_ref != v:
					for i in range(part.rands.size()):
						part.rands[i] = abs(part.rands[i] + (v-part.spr_ref)) % part.randCuts.size();
				part.spr = v
				part.spr_ref = v
				part.region_rect = model.ic_rects[part.spr]
			Z_ORDER:
				part.mm_z = floori(value)
			POS_X:
				part.set_pos.x = part.def_posx + value
			POS_Y:
				part.set_pos.y = part.def_posy + value
			PIVOT_X:
				part.offset.x = -part.def_pivx - value
			PIVOT_Y:
				part.offset.y = -part.def_pivy - value
			SCALE:
				if part.rot_scah:
					value *= -1
				part.scale.x = part.def_scax * (value/model.mm_divs[MaModel.DIV_SCA])
				if part.rot_scah != part.rot_scav:
					value *= -1
				part.scale.y = part.def_scay * (value/model.mm_divs[MaModel.DIV_SCA])
			SCALE_X:
				if part.rot_scah:
					value *= -1
				part.scale.x = part.def_scax * (value/model.mm_divs[MaModel.DIV_SCA])
			SCALE_Y:
				if part.rot_scav:
					value *= -1
				part.scale.y = part.def_scay * (value/model.mm_divs[MaModel.DIV_SCA])
			ROTATION:
				var amul = 1.0 if part.get_parent().global_scale.x >= 0 && part.get_parent().global_scale.y >= 0 else -1.0
				if part.rot_h != part.rot_v:
					amul *= -1
				part.rotation = ((amul * part.def_angl)+((amul * value)/model.mm_divs[MaModel.DIV_ANGL])) * PI * (2 if model.scale.x * model.scale.y >= 0 else -2)
			OPACITY:
				part.modulate.a = part.def_opa * (value/model.mm_divs[MaModel.DIV_OPA])
			H_FLIP:
				var b = floori(value) != 0
				if part.rot_scah != b:
					part.rot_scah = b
					part.rot_h = !part.rot_h
					part.scale.x *= -1
					part.rotation *= -1
					for c in part.get_model_children():
						c.rot_h = !c.rot_h
						c.rotation *= -1
			V_FLIP:
				var b = floori(value) != 0
				if part.rot_scav != b:
					part.rot_scav = b
					part.rot_v = !part.rot_v
					part.scale.y *= -1
					part.rotation *= -1
					for c in part.get_model_children():
						c.rot_v = !c.rot_v
						c.rotation *= -1
			EXTEND_X:
				part.extend(value / model.mm_divs[MaModel.DIV_SCA], false)
			EXTEND_X_RAND:
				part.extend(value / model.mm_divs[MaModel.DIV_SCA], false)
				part.rand = true
			EXTEND_Y:
				part.extend(value / model.mm_divs[MaModel.DIV_SCA], true)
			G_SCALE:
				part.gsca = value / model.mm_divs[MaModel.DIV_SCA]
			EXTEND_Y_RAND:
				part.extend(value / model.mm_divs[MaModel.DIV_SCA], true)
				part.rand = true
	
	var setting : bool = true
	while setting:#Needs to be like this in case parts have attached a parent at a higher ID than themselves
		setting = false
		for part in model.mm_parts:
			if part.a_set(true):
				setting = true#No break cause all parts must be set
	model.sort_zOrder()
	if abs(cur_f) >= lastF:
		model.anim_finished.emit()
