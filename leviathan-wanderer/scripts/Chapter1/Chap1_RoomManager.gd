# RoomManager.gd
extends Node

var room_scenes: Array[PackedScene] = [
    preload("res://scene/Chapter1/Level1_roomA.tscn"),
    preload("res://scene/Chapter1/Level1_roomB.tscn"),
    preload("res://scene/Chapter1/Level1_roomD.tscn")
]

func get_random_room() -> PackedScene:
    return room_scenes[randi() % room_scenes.size()]