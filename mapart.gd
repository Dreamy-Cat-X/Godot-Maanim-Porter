class_name MaPart
extends RefCounted

const P_PART = 0
const P_MOD = 1
const P_LOOP = 2
var pmods : Array[int]
var tmods : Array[MaBit]

func _init(line : int, data : PackedStringArray, mm_parts : Array[MMPart]):
	var parr = data[line].split(",")
	for i in range(3):
		pmods.append(int(parr[i]))
	var siz = int(data[line+1]) + line + 2
	for i in range(line+2,siz):
		var bit = MaBit.new(data[i].split(","))
		tmods.append(bit)
		if pmods[MaPart.P_MOD] == MaAnim.SPRITE && mm_parts[pmods[MaPart.P_PART]].randCuts.find(bit.value) == -1:
				mm_parts[pmods[MaPart.P_PART]].randCuts.append(bit.value)

func size() -> int:
	return tmods.size()

func duration() -> float:
	if (tmods.is_empty()):
		return 0
	if pmods[P_LOOP] > 0:
		return tmods[-1].frame * pmods[P_LOOP]
	return tmods[-1].frame

func ease3(i : int,frame : float) -> int:
	var low : int = i;
	var high : int = i;
	for j in range(i-1, -1, -1):
		if tmods[j].ease_typ == 3:
			low = j;
		else:
			break;
	for j in range(i + 1, tmods.size()):
		high = j
		if tmods[j].ease_typ != 3:
			break;
	var sum : float = 0;
	for j in range(low, high + 1):
		var val : float = tmods[j].value * 4096;
		if (tmods[i].ease_deg > 0):
			val *= 1+(tmods[i].ease_deg*0.01)
		for k in range(low, high + 1):
			if (j != k):
				val *= 1.0 * (frame - tmods[k].frame) / (tmods[j].frame - tmods[k].frame);
		sum += val;
	var div = 4096;
	if (tmods[i].ease_deg < 0 && tmods[i].ease_deg != -100):
		div *= 1-(tmods[i].ease_deg*0.01);
	return (int) (sum / div);
