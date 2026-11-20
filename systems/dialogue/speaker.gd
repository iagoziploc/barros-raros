class_name Speaker
extends Resource
## Quién habla en un diálogo. Cada personaje es un .tres en data/speakers/.

## Clave de localization/strings.csv con el nombre. Vacía = sin nombre (narrador).
@export var name_key := ""
## Retrato que acompaña sus líneas. Puede quedar vacío.
@export var portrait: Texture2D
## Color del nombre en la caja de diálogo.
@export var name_color := Color(1.0, 0.85, 0.6)
