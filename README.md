# Barros Raros

Tower defense hecho para la game jam [Liberen el Paraná](https://itch.io/jam/liberen-el-parana-gamejam).

Del norte llegan los inversores a llevarse las **tierras raras** y el **agua dulce** del Paraná. El **Cara de Barro** despierta y amasa **golems de barro** para defender el río.

Inspirado en la obra de [Manuel Brandazza](https://www.manuelbrandazza.com).

**Diseño y narrativa:** el GDD está en un documento compartido del equipo. Si sos parte del equipo y no lo tenés, pedile el link a iago.

## Equipo

| Rol | Persona |
| --- | --- |
| Game design, narrativa y programación | iago |
| Audio | _por definir_ |
| Arte y animación | _por definir_ |

## Cómo abrir el proyecto

1. Instalar **Godot 4.7.2 estándar** (no la versión .NET). Todo el equipo tiene que usar exactamente esta versión.
2. Clonar el repo: `git clone https://github.com/iagoziploc/barros-raros.git`
3. En Godot: **Importar** → elegir el archivo `project.godot` de la carpeta clonada.

## Estructura

| Carpeta | Qué va ahí |
| --- | --- |
| `assets/art/` | Sprites, animaciones, fondos |
| `assets/audio/` | Música y efectos |
| `assets/fonts/` | Tipografías |
| `localization/` | Textos del juego (español primero, preparado para traducir) |
| `data/` | **Valores de balance** (`.tres`). Se editan en el inspector de Godot, sin tocar código |
| `systems/` | Sistemas globales del juego (por ejemplo, la economía de tierra y agua) |
| `levels/` | Escenas de los niveles: mapa, camino de los enemigos, zona húmeda y río |
| `tests/` | Pruebas automáticas |

### Pruebas

```
godot --headless --path . res://tests/economy_test.tscn
```

Termina con código 0 si todo pasa.

**Convención:** nombres de archivos y carpetas en minúsculas, con `_` y sin tildes ni ñ (`totem_de_barro.png`, no `Tótem de Barro.png`).

## Fechas

- Cierre de entregas: **24/11/2026, 03:00**
