# Barros Raros

Tower defense hecho para la game jam [Liberen el Paraná](https://itch.io/jam/liberen-el-parana-gamejam).

Del norte llegan los inversores a llevarse las **tierras raras** y el **agua dulce** del Paraná. El **Cara de Barro** despierta y amasa **defensores de barro** para defender el río.

Inspirado en la obra de [Manuel Brandazza](https://www.manuelbrandazza.com).

**Diseño y narrativa:** el GDD está en un documento compartido del equipo. Si sos parte del equipo y no lo tenés, pedile el link a iago.

## Equipo

| Rol | Persona |
| --- | --- |
| Game design, narrativa y programación | iago |
| Audio | _por definir_ |
| Arte y animación | _por definir_ |

## Cómo jugar la versión en desarrollo

### Lo que hace falta (una sola vez)

- **Godot 4.7.2 Standard** (no la .NET), desde <https://godotengine.org/download/archive/>. Tiene que ser exactamente esa versión: con otra, Godot puede modificar los archivos del proyecto.
- **GitHub Desktop**, desde <https://desktop.github.com>. Al abrirlo por primera vez podés iniciar sesión con tu cuenta de GitHub o saltear ese paso: para bajar el juego no hace falta.

### Bajar el proyecto

1. En GitHub Desktop: **File → Clone repository → URL**.
2. Pegá `https://github.com/iagoziploc/barros-raros`, elegí en qué carpeta guardarlo y tocá **Clone**.
3. En Godot: **Importar** → elegí el `project.godot` de esa carpeta → **Importar y editar**. La primera vez tarda un minuto mientras prepara imágenes y sonidos.
4. **F5** (o el ▶ de arriba a la derecha) para jugar.

### Mantenerlo actualizado

En GitHub Desktop, con el repo `barros-raros` seleccionado: **Fetch origin** y, si aparece, **Pull origin**. Después volvé a Godot y apretá F5.

Si GitHub Desktop muestra archivos modificados que no tocaste a propósito (Godot a veces reescribe alguno al abrir el proyecto), antes del Pull hacé clic derecho sobre ellos → **Discard changes**. Para **subir** tus propios archivos (por ejemplo, sonidos) hace falta una cuenta con permiso en el repo: pedíselo a iago.

### Controles

| Acción | Cómo |
| --- | --- |
| Avanzar un diálogo | **Clic**, **Espacio** o **Enter** (el primero completa el texto, el segundo pasa a la línea siguiente) |
| Elegir una unidad | Botón de la barra de abajo, o teclas **1**, **2**, **3**… |
| Colocarla | **Clic izquierdo** en el mapa (si el fantasma está rojo, ahí no se puede) |
| Cancelar | **Clic derecho** o **Esc** |
| Destruir una unidad (devuelve la mitad) | **Clic derecho** sobre la unidad, sin nada seleccionado |

Al terminar la oleada, las unidades se disuelven y devuelven todo su costo. Si la tierra o el agua llegan a 0 y no las recuperás en 5 segundos, perdés.

## Para el equipo que edita el proyecto

- Todos con **Godot 4.7.2 estándar**.
- Clonar: `git clone https://github.com/iagoziploc/barros-raros.git` e importar `project.godot`.
- **Nombres de archivos:** minúsculas, con `_` y sin tildes ni ñ (`fondo_rio.png`, no `Fondo Río.png`). La versión web distingue mayúsculas.
- Los archivos `.import` que Godot crea al lado de cada imagen o sonido **se suben al repo**: guardan cómo se importan (por ejemplo, el loop de la música).

### Estructura

| Carpeta | Qué va ahí |
| --- | --- |
| `assets/art/` | Sprites, animaciones, fondos |
| `assets/audio/` | Música y efectos |
| `assets/fonts/` | Tipografías |
| `localization/` | Todos los textos del juego (`strings.csv`) |
| `data/` | **Valores de balance** (`.tres`). Se editan en el inspector de Godot, sin tocar código |
| `systems/` | Sistemas globales: economía, oleadas, colocación de unidades |
| `levels/` | Escenas de los niveles: mapa, camino, zona húmeda y río |
| `entities/` | Enemigos y unidades |
| `ui/` | Interfaz: HUD y barra de construcción |
| `tests/` | Pruebas automáticas |

### Pruebas

```
godot --headless --path . res://tests/economy_test.tscn
godot --headless --path . res://tests/enemy_test.tscn
godot --headless --path . res://tests/wave_test.tscn
godot --headless --path . res://tests/hud_test.tscn
godot --headless --path . res://tests/unit_test.tscn
godot --headless --path . res://tests/dialogue_test.tscn
```

Cada una termina con código 0 si todo pasa.

## Fechas

- Cierre de entregas: **24/11/2026, 03:00**
