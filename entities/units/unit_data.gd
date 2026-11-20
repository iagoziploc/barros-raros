class_name UnitData
extends Resource
## Datos de un tipo de unidad. Cada tipo es un .tres en data/units/.

## Clave de localization/strings.csv con el nombre.
@export var name_key := ""

@export_group("Costo")
@export var earth_cost := 20
@export var water_cost := 10

@export_group("Construcción")
## Segundos que tarda en construirse. Mientras tanto no ataca y no se puede construir otra.
@export var build_time := 3.0
## Distancia mínima en píxeles entre esta unidad y cualquier otra.
@export var spacing := 72.0

@export_group("Ataque")
## Daño de cada golpe, antes de restar la armadura del enemigo.
@export var damage := 4
## Segundos entre golpes.
@export var attack_interval := 0.8
## Radio en píxeles dentro del cual detecta enemigos.
@export var attack_range := 90.0

@export_group("Visual y sonido")
@export var texture: Texture2D
@export var sprite_scale := 0.12
## Se reproduce al terminar de construirse. Puede quedar vacío.
@export var spawn_sound: AudioStream
## Cuánto puede subir o bajar el tono del sonido al terminar. 0.2 = entre 80% y 120% del tono original.
@export_range(0.0, 0.5, 0.01) var pitch_variation := 0.2
