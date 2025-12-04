class_name MaModel
extends Node2D

const DIV_SCA := 0
const DIV_ANGL := 1
const DIV_OPA := 2

@export var sprite : Texture2D ##The sprite used by the part. Can also be used to get the folder path
@export var anims : Array[String] ##Animations to load. Can be as many as needed
@export var playing : String ##Name of the playing animation. Set a name in editor serve as autoplay
@export_range(0, 1000) var fps : float ##Limits the amount of fps for this entity. Set to 0 for no limit, can go up to 1000
var ic_rects : Array[Rect2] ##imgcut proportions, neatly stored into rectangles
var ic_names : PackedStringArray ##imgcut names
var mm_parts : Array[MMPart] ##Lists all mamodel parts. The index order is important, so consider not sorting

var mm_divs : Array[int] ##Mamodel dividend data used to know the measuring precision of scale, angle, and opacity
var mas : Dictionary ##Dictionary containing all maanims, with their name as key.
var passedTime : float ##Amount of time elapsed since last maanim update. Used if fps is active
@export_range(-1000, 1000) var play_speed : float = -1 ##Used to change the speed which the animation plays.

@warning_ignore("unused_signal") signal anim_finished ##Emitted when animation is done. Connect anything if needed

func _ready() -> void:
	if sprite != null:
		initialize_model()

##Separate functions for mamodels initialized at some point.
func initialize_model() -> void:
	var path = sprite.resource_path
	cut(path.substr(0, path.rfind("/") + 1))

func cut(dir : String) -> void:##Parses all data from the imgcut, mamodel, and specified maanim files
	sprite = load(dir + "sprite.png")
	var ic = FileAccess.open(dir + "imgcut.txt", FileAccess.READ)
	var content = ic.get_as_text()
	ic.close()
	var lines = content.split("\n")
	for line in lines:
		var d = line.split(",")
		if d.size() < 4:
			continue
		ic_rects.append(Rect2(float(d[0]), float(d[1]), float(d[2]), float(d[3])))
		ic_names.append(d[4] if d.size() >= 5 else "")

	var mm = FileAccess.open(dir + "mamodel.txt", FileAccess.READ)
	content = mm.get_as_text()
	mm.close()
	lines = content.split("\n")
	for line in lines:
		var d = line.split(",")
		var intA : Array[int]
		if d.size() < 13:
			if d.size() == 3:
				for i in d:
					intA.append(int(i))
				mm_divs = intA
			continue
		for i in range(13):
			intA.append(int(d[i]))
		var part = MMPart.new(self, sprite, mm_parts.size(), intA, d[13] if d.size() >= 14 && !d[13].is_empty() else ic_names[intA[MMPart.MM_SPR]])
		mm_parts.append(part)
		add_child(part)
	
	for part in mm_parts:
		part.def_scax /= mm_divs[DIV_SCA]
		part.def_scay /= mm_divs[DIV_SCA]
		part.def_angl /= mm_divs[DIV_ANGL]
		part.def_opa /= mm_divs[DIV_OPA] 
	
	for a in anims:
		mas[a] = MaAnim.new(self, dir, "maanim_" + a + ".txt")
	if !playing.is_empty():
		playAnim(playing)
	else:
		resetAnim()

func playAnim(a_name : String, startAt : float = 0) -> void:
	if !playing.is_empty():
		mas[playing].cur_f = -1
	playing = a_name
	resetAnim()
	if !playing.is_empty():
		mas[playing].update(1 + startAt)

func playAnimAt(ind : int, startAt : float = 0) -> void:
	playAnim(anims[ind], startAt)

func _process(delta: float) -> void:
	if (!playing.is_empty() && mas[playing].cur_f != -1):
		passedTime += delta * play_speed
		if fps == 0 || abs(passedTime) * fps >= 1:
			mas[playing].update(passedTime)
			passedTime = 0

func resetAnim(parsync : bool = true) -> void:
	var oldScale = scale #If scale.x * scale.y < 0, it can lead to incorrect positioning
	scale = scale.abs()
	for i in range(mm_parts.size()):
		var part = mm_parts[i]
		part.def_id = i
		part.reset(parsync)
	if parsync:
		sort_zOrder()
	scale = oldScale

func sort_zOrder() -> void:
	var sortedChildren = get_children()
	sortedChildren.sort_custom(z_sort)
	for node in get_children():
		remove_child(node)
	for node in sortedChildren:
		add_child(node)

func z_sort(a : Node, b : Node) -> bool:
	if a is not MMPart && b is not MMPart:
		return false
	if a is not MMPart:
		return true
	if b is not MMPart:
		return false
	if a.mm_z != b.mm_z:
		return a.mm_z < b.mm_z
	return a.def_id < b.def_id
