class_name MaBit
extends RefCounted

var frame : float
var value : int
var ease_typ : int
var ease_deg : int

func _init(data : Array[String]) -> void:
	var intA : Array[int]
	for i in range(4):
		intA.append(int(data[i]))
	
	frame = (1.0 * intA[0]) / 30
	value = intA[1]
	ease_typ = intA[2]
	ease_deg = intA[3]
