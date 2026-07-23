class_name SegmentRecipe extends Resource


@export var rows: int = Tuning.ROWS_PER_SEGMENT
@export var base_kind: int = Cell.Kind.WALL

@export var crawler_count: float = 1.0
@export var gargoyle_count: float = 1.0
@export var lurker_count: float = 0.0
@export var guard_count: float = 0.0
@export var mason_count: float = 0.0
@export var window_swiper_chance: float = 0.35


static func for_depth(index: int, total: int) -> SegmentRecipe:
	var recipe := SegmentRecipe.new()
	var t := 0.0 if total <= 1 else float(index) / float(total - 1)
	recipe.base_kind = Cell.Kind.BRICK if index % 2 == 1 else Cell.Kind.WALL

	recipe.crawler_count = lerpf(0.6, 1.5, t)
	recipe.gargoyle_count = lerpf(0.3, 1.2, t)
	recipe.lurker_count = lerpf(0.0, 1.0, t)
	recipe.guard_count = lerpf(0.6, 0.0, t)
	recipe.mason_count = lerpf(0.0, 0.5, t)
	recipe.window_swiper_chance = lerpf(0.15, 0.30, t)
	return recipe
