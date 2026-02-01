extends Resource
class_name EnemyData

@export var enemy_key: String = ""
@export var display_name: String = ""
@export_multiline var desc: String = ""
@export var flip_effect_id: String = ""
@export var flip_trigger_id: String = ""
@export var resolver_script: Script = null
@export var card_art: Texture2D = null
@export var card_art_flipped: Texture2D = null

@export_group("Portrait")
@export var portrait: Texture2D = null
@export var portrait_flipped: Texture2D = null

@export_group("Death Behavior")
@export var death_transform: EnemyData = null

@export_group("Stats")
@export var n: int = 0
@export var e: int = 0
@export var s: int = 0
@export var w: int = 0
