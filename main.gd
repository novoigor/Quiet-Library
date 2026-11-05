extends Node2D

# Quiet Library — версия с графическими ассетами.
# Godot 4.x

const BOOK_COUNT := 18
const BOOKS_PER_SHELF := 6
const BOOKS_PER_ROW := 9

var shelf_names: Array[String] = ["ИСТОРИЯ", "НАУКА", "ФАНТАСТИКА"]
var shelf_colors: Array[Color] = [
	Color("#477fbd"),
	Color("#479b72"),
	Color("#b94f59")
]

var books: Array[Dictionary] = []
var dragged_book: int = -1
var drag_offset: Vector2 = Vector2.ZERO
var placed_count: int = 0
var game_won: bool = false
var message: String = "Перетащи каждую книгу на полку своего цвета"

# Основные текстуры
var wallpaper_texture: Texture2D
var bookshelf_texture: Texture2D
var lectern_texture: Texture2D
var book_textures: Array[Texture2D] = []

# Декоративные текстуры
var quiet_sign_texture: Texture2D
var globe_texture: Texture2D
var plant_texture: Texture2D
var coffee_texture: Texture2D
var restart_button_texture: Texture2D

# Звуки
var correct_player: AudioStreamPlayer
var wrong_player: AudioStreamPlayer
var win_player: AudioStreamPlayer


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_load_assets()
	_create_books()
	queue_redraw()


func _load_assets() -> void:
	# Большие элементы библиотеки
	wallpaper_texture = load("res://assets/Library #01/Wallpaper-00.png") as Texture2D
	bookshelf_texture = load("res://assets/Library #01/Bookshelfs-00.png") as Texture2D
	lectern_texture = load("res://assets/Library #01/Lecter-00.png") as Texture2D

	# Книги для перетаскивания
	book_textures.clear()
	book_textures.append(load("res://assets/Pixel_Library_Books_Icons/PNG/32x32/books/book_blue.png") as Texture2D)
	book_textures.append(load("res://assets/Pixel_Library_Books_Icons/PNG/32x32/books/book_green.png") as Texture2D)
	book_textures.append(load("res://assets/Pixel_Library_Books_Icons/PNG/32x32/books/book_red.png") as Texture2D)

	# Небольшие украшения
	quiet_sign_texture = load("res://assets/Pixel_Library_Books_Icons/PNG/32x32/extras/quiet_sign.png") as Texture2D
	globe_texture = load("res://assets/Pixel_Library_Books_Icons/PNG/32x32/lighting_decor/globe.png") as Texture2D
	plant_texture = load("res://assets/Pixel_Library_Books_Icons/PNG/32x32/lighting_decor/plant_pot.png") as Texture2D
	coffee_texture = load("res://assets/Pixel_Library_Books_Icons/PNG/32x32/extras/coffee_cup.png") as Texture2D

	# Кнопка из Kenney UI Pack Adventure
	restart_button_texture = load("res://assets/kenney_ui-pack-adventure/PNG/Default/button_brown.png") as Texture2D

	# Звуки из Kenney UI Pack
	correct_player = _create_audio_player("res://assets/kenney_ui-pack/Sounds/click-a.ogg")
	wrong_player = _create_audio_player("res://assets/kenney_ui-pack/Sounds/tap-a.ogg")
	win_player = _create_audio_player("res://assets/kenney_ui-pack/Sounds/click-b.ogg")


func _create_audio_player(path: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = load(path) as AudioStream
	add_child(player)
	return player


func _play_sound(player: AudioStreamPlayer) -> void:
	if player == null:
		return
	player.stop()
	player.play()


func _draw() -> void:
	var screen_size := get_viewport_rect().size

	_draw_background(screen_size)
	_draw_decor(screen_size)
	_draw_header(screen_size)

	for i in range(3):
		_draw_shelf(i, screen_size)

	_draw_table(screen_size)

	# Сначала рисуем обычные книги, затем перетаскиваемую книгу поверх остальных.
	for i in range(BOOK_COUNT):
		if i != dragged_book:
			_draw_book(i)

	if dragged_book != -1:
		_draw_book(dragged_book)

	if game_won:
		_draw_win_overlay(screen_size)


func _draw_background(screen_size: Vector2) -> void:
	var wall_height := screen_size.y * 0.72

	# Цвет стены под прозрачными участками обоев.
	draw_rect(
		Rect2(Vector2.ZERO, Vector2(screen_size.x, wall_height)),
		Color("#4e2638")
	)

	if wallpaper_texture != null:
		# Обои повторяются без растягивания, чтобы пиксельный рисунок не искажался.
		draw_texture_rect(
			wallpaper_texture,
			Rect2(Vector2.ZERO, Vector2(screen_size.x, wall_height)),
			true
		)
	else:
		draw_rect(
			Rect2(Vector2.ZERO, Vector2(screen_size.x, wall_height)),
			Color("#3b202e")
		)

	# Лёгкое затемнение стены помогает выделить полки.
	draw_rect(
		Rect2(Vector2.ZERO, Vector2(screen_size.x, wall_height)),
		Color(0.0, 0.0, 0.0, 0.12)
	)

	# Деревянный пол.
	draw_rect(
		Rect2(Vector2(0, wall_height), Vector2(screen_size.x, screen_size.y - wall_height)),
		Color("#493039")
	)

	for plank in range(1, 5):
		var line_y := wall_height + float(plank) * (screen_size.y - wall_height) / 5.0
		draw_line(
			Vector2(0, line_y),
			Vector2(screen_size.x, line_y),
			Color(0.75, 0.55, 0.38, 0.18),
			2.0
		)

	draw_line(
		Vector2(0, wall_height),
		Vector2(screen_size.x, wall_height),
		Color("#d0a66b"),
		5.0
	)


func _draw_decor(screen_size: Vector2) -> void:
	# Кафедра из основного набора библиотеки.
	if lectern_texture != null:
		draw_texture_rect(
			lectern_texture,
			Rect2(Vector2(8, screen_size.y * 0.39), Vector2(145, 104)),
			false
		)

	# Табличка «Тишина».
	if quiet_sign_texture != null:
		draw_texture_rect(
			quiet_sign_texture,
			Rect2(Vector2(22, screen_size.y * 0.22), Vector2(58, 58)),
			false
		)

	# Глобус и растение с правой стороны.
	if globe_texture != null:
		draw_texture_rect(
			globe_texture,
			Rect2(Vector2(screen_size.x - 92, screen_size.y * 0.25), Vector2(66, 66)),
			false
		)

	if plant_texture != null:
		draw_texture_rect(
			plant_texture,
			Rect2(Vector2(screen_size.x - 92, screen_size.y * 0.49), Vector2(66, 66)),
			false
		)


func _draw_header(screen_size: Vector2) -> void:
	# Тёмная плашка отделяет заголовок от узорчатых обоев.
	var header_panel := Rect2(
		Vector2(screen_size.x / 2.0 - 350.0, 8.0),
		Vector2(700.0, 126.0)
	)
	draw_rect(header_panel, Color("#21131f"))
	draw_rect(
		Rect2(header_panel.position + Vector2(4, 4), header_panel.size - Vector2(8, 8)),
		Color("#392333")
	)
	draw_rect(header_panel, Color("#c9a36b"), false, 3.0)

	_draw_centered_text(
		"QUIET LIBRARY",
		screen_size.x / 2.0,
		38,
		32,
		Color("#ffe8b5"),
		screen_size.x * 0.8
	)

	_draw_centered_text(
		"Помоги библиотекарю рассортировать книги",
		screen_size.x / 2.0,
		68,
		17,
		Color("#f8ead8"),
		screen_size.x * 0.8
	)

	_draw_centered_text(
		"РАЗЛОЖЕНО: %d / %d" % [placed_count, BOOK_COUNT],
		screen_size.x / 2.0,
		96,
		15,
		Color("#ffd58b"),
		300
	)

	var bar_rect := Rect2(
		Vector2(screen_size.x / 2.0 - 125, 104),
		Vector2(250, 9)
	)
	draw_rect(bar_rect, Color("#170f18"))
	draw_rect(
		Rect2(bar_rect.position, Vector2(bar_rect.size.x * float(placed_count) / float(BOOK_COUNT), bar_rect.size.y)),
		Color("#e4b96f")
	)
	draw_rect(bar_rect, Color("#f0d29c"), false, 1.5)

	_draw_centered_text(
		message,
		screen_size.x / 2.0,
		130,
		14,
		Color("#fff4e5"),
		screen_size.x * 0.78
	)

func _shelf_rect(index: int, screen_size: Vector2) -> Rect2:
	var shelf_width: float = minf(screen_size.x * 0.22, 250.0)
	var shelf_height: float = screen_size.y * 0.37
	var gap: float = screen_size.x * 0.035
	var total_width: float = shelf_width * 3.0 + gap * 2.0
	var start_x: float = (screen_size.x - total_width) / 2.0

	return Rect2(
		Vector2(start_x + float(index) * (shelf_width + gap), screen_size.y * 0.255),
		Vector2(shelf_width, shelf_height)
	)


func _draw_shelf(index: int, screen_size: Vector2) -> void:
	var rect := _shelf_rect(index, screen_size)

	# Тень под полкой.
	draw_rect(
		Rect2(rect.position + Vector2(7, 9), rect.size),
		Color(0.0, 0.0, 0.0, 0.38)
	)

	if bookshelf_texture != null:
		# Пустая секция книжного шкафа: 1-й столбец, 3-я строка атласа.
		draw_texture_rect_region(
			bookshelf_texture,
			rect,
			Rect2(Vector2(0, 256), Vector2(128, 128))
		)
	else:
		draw_rect(rect, Color("#39212c"))
		draw_rect(rect, Color("#b68a55"), false, 4.0)

	# Цветная табличка с названием раздела.
	var label_rect := Rect2(
		Vector2(rect.position.x + 38, rect.position.y - 29),
		Vector2(rect.size.x - 76, 28)
	)
	draw_rect(label_rect, Color("#24171d"))
	draw_rect(
		Rect2(label_rect.position + Vector2(3, 3), label_rect.size - Vector2(6, 6)),
		shelf_colors[index]
	)

	_draw_centered_text(
		shelf_names[index],
		label_rect.position.x + label_rect.size.x / 2.0,
		label_rect.position.y + 20,
		14,
		Color("#fff4df"),
		label_rect.size.x - 8
	)


func _table_rect(screen_size: Vector2) -> Rect2:
	return Rect2(
		Vector2(screen_size.x * 0.04, screen_size.y * 0.73),
		Vector2(screen_size.x * 0.92, screen_size.y * 0.25)
	)


func _draw_table(screen_size: Vector2) -> void:
	var rect := _table_rect(screen_size)

	# Тень и деревянная поверхность для книг.
	draw_rect(
		Rect2(rect.position + Vector2(7, 8), rect.size),
		Color(0.0, 0.0, 0.0, 0.38)
	)
	draw_rect(rect, Color("#24171d"))
	draw_rect(
		Rect2(rect.position + Vector2(5, 5), rect.size - Vector2(10, 10)),
		Color("#704832")
	)
	draw_rect(
		Rect2(rect.position + Vector2(10, 10), rect.size - Vector2(20, 20)),
		Color("#986849")
	)
	draw_rect(rect, Color("#d0a66b"), false, 3.0)

	_draw_centered_text(
		"КНИГИ — ПЕРЕТАЩИ НА ПОДХОДЯЩУЮ ПОЛКУ",
		rect.position.x + rect.size.x / 2.0,
		rect.position.y + 28,
		14,
		Color("#fff0d8"),
		rect.size.x - 30
	)

	# Чашка кофе на краю стола.
	if coffee_texture != null:
		draw_texture_rect(
			coffee_texture,
			Rect2(Vector2(8, rect.position.y + 70), Vector2(48, 48)),
			false
		)


func _book_start_position(index: int, screen_size: Vector2) -> Vector2:
	var table := _table_rect(screen_size)
	var column := index % BOOKS_PER_ROW
	var row := int(index / BOOKS_PER_ROW)

	var x := table.position.x + table.size.x * (float(column) + 0.5) / float(BOOKS_PER_ROW)
	var y := table.position.y + (68.0 if row == 0 else 124.0)

	return Vector2(x, y)


func _book_rect(index: int) -> Rect2:
	var book_size := Vector2(54, 54)

	if bool(books[index]["placed"]):
		book_size = Vector2(38, 38)
	elif dragged_book == index:
		book_size = Vector2(64, 64)

	var book_position: Vector2 = books[index]["position"]
	return Rect2(book_position - book_size / 2.0, book_size)


func _draw_book(index: int) -> void:
	var color_index := int(books[index]["color"])
	if color_index < 0 or color_index >= book_textures.size():
		return

	var texture := book_textures[color_index]
	if texture == null:
		return

	var rect := _book_rect(index)

	# Небольшая тень помогает видеть книгу на столе.
	if not bool(books[index]["placed"]):
		draw_rect(
			Rect2(rect.position + Vector2(3, 4), rect.size),
			Color(0.0, 0.0, 0.0, 0.35)
		)

	draw_texture_rect(texture, rect, false)

	if dragged_book == index:
		draw_rect(rect, Color("#ffe5a5"), false, 2.0)


func _draw_centered_text(
	text: String,
	center_x: float,
	y: float,
	font_size: int,
	color: Color,
	width: float
) -> void:
	var text_position := Vector2(center_x - width / 2.0, y)
	var outline_offsets: Array[Vector2] = [
		Vector2(-1, 0),
		Vector2(1, 0),
		Vector2(0, -1),
		Vector2(0, 1),
		Vector2(-1, -1),
		Vector2(1, -1),
		Vector2(-1, 1),
		Vector2(1, 1)
	]

	# Тонкая тёмная обводка делает надписи читаемыми на любых текстурах.
	for offset in outline_offsets:
		draw_string(
			ThemeDB.fallback_font,
			text_position + offset,
			text,
			HORIZONTAL_ALIGNMENT_CENTER,
			width,
			font_size,
			Color("#21131f")
		)

	draw_string(
		ThemeDB.fallback_font,
		text_position,
		text,
		HORIZONTAL_ALIGNMENT_CENTER,
		width,
		font_size,
		color
	)


func _create_books() -> void:
	books.clear()
	placed_count = 0

	var screen_size := get_viewport_rect().size

	# Порядок перемешан, чтобы книги не шли по цветам подряд.
	var color_order: Array[int] = [
		2, 0, 1, 1, 2, 0,
		2, 1, 0, 1, 0, 2,
		0, 2, 1, 2, 1, 0
	]

	for i in range(BOOK_COUNT):
		books.append({
			"color": color_order[i],
			"position": _book_start_position(i, screen_size),
			"placed": false
		})


func _get_shelf_at(point: Vector2, screen_size: Vector2) -> int:
	for i in range(3):
		if _shelf_rect(i, screen_size).has_point(point):
			return i
	return -1


func _count_placed_in_shelf(shelf_index: int) -> int:
	var count := 0
	for book in books:
		if bool(book["placed"]) and int(book["color"]) == shelf_index:
			count += 1
	return count


func _input(event: InputEvent) -> void:
	var screen_size := get_viewport_rect().size

	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return

		if event.pressed:
			if game_won:
				if _restart_button_rect(screen_size).has_point(event.position):
					_restart_game()
				return

			for i in range(BOOK_COUNT):
				if not bool(books[i]["placed"]) and _book_rect(i).has_point(event.position):
					dragged_book = i
					drag_offset = books[i]["position"] - event.position
					queue_redraw()
					break

		else:
			if dragged_book == -1:
				return

			var target := _get_shelf_at(event.position, screen_size)

			if target != -1 and int(books[dragged_book]["color"]) == target:
				var slot := _count_placed_in_shelf(target)
				var column := slot % 3
				var row := int(slot / 3)
				var shelf := _shelf_rect(target, screen_size)

				var slot_x := shelf.position.x + shelf.size.x * (0.32 + float(column) * 0.18)
				var slot_y := shelf.position.y + shelf.size.y * (0.59 if row == 0 else 0.77)

				books[dragged_book]["placed"] = true
				books[dragged_book]["position"] = Vector2(slot_x, slot_y)

				placed_count += 1
				message = "Верно! Книга на своём месте."
				_play_sound(correct_player)

				if placed_count == BOOK_COUNT:
					game_won = true
					message = "Все книги на своих местах!"
					_play_sound(win_player)
			else:
				books[dragged_book]["position"] = _book_start_position(dragged_book, screen_size)
				message = "Не та полка. Попробуй ещё раз!"
				_play_sound(wrong_player)

			dragged_book = -1
			queue_redraw()

	elif event is InputEventMouseMotion:
		if dragged_book != -1:
			books[dragged_book]["position"] = event.position + drag_offset
			queue_redraw()


func _restart_button_rect(screen_size: Vector2) -> Rect2:
	return Rect2(
		Vector2(screen_size.x / 2.0 - 80, screen_size.y / 2.0 + 52),
		Vector2(160, 80)
	)


func _draw_win_overlay(screen_size: Vector2) -> void:
	draw_rect(
		Rect2(Vector2.ZERO, screen_size),
		Color(0.04, 0.02, 0.04, 0.78)
	)

	var panel := Rect2(
		Vector2(screen_size.x / 2.0 - 250, screen_size.y / 2.0 - 150),
		Vector2(500, 300)
	)

	draw_rect(panel, Color("#291b25"))
	draw_rect(panel, Color("#d6b477"), false, 4.0)
	draw_rect(
		Rect2(panel.position + Vector2(9, 9), panel.size - Vector2(18, 18)),
		Color("#49303b"),
		false,
		2.0
	)

	_draw_centered_text(
		"ОТЛИЧНАЯ РАБОТА!",
		screen_size.x / 2.0,
		screen_size.y / 2.0 - 65,
		30,
		Color("#f6d99c"),
		450
	)

	_draw_centered_text(
		"Все 18 книг разложены по разделам.",
		screen_size.x / 2.0,
		screen_size.y / 2.0 - 22,
		18,
		Color("#fff0d8"),
		450
	)

	var button := _restart_button_rect(screen_size)
	if restart_button_texture != null:
		draw_texture_rect(restart_button_texture, button, false)
	else:
		draw_rect(button, Color("#d2a46a"))

	_draw_centered_text(
		"ИГРАТЬ СНОВА",
		screen_size.x / 2.0,
		button.position.y + 48,
		16,
		Color("#593a29"),
		button.size.x - 12
	)


func _restart_game() -> void:
	placed_count = 0
	game_won = false
	dragged_book = -1
	message = "Перетащи каждую книгу на полку своего цвета"
	_create_books()
	_play_sound(correct_player)
	queue_redraw()
