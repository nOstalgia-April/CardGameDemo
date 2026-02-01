extends Resource
class_name LevelData

@export var level_name: String = ""
@export var level_index: int = 1
@export var enemy_spawns: Array[EnemySpawnData] = []
@export var initial_hand_cards: Array[String] = []
@export var portrait: Texture2D
@export var is_boss: bool = false
