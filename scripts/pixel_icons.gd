class_name PixelIcons
extends RefCounted
## 12x12 pixel-art icons in the style of ~2000 messenger emoticons and OS icons.
## Defined as character grids, converted to textures once and cached.
## Draw with texture_filter = NEAREST on the drawing node to keep the pixels crisp.

enum Icon {
	SMILE, WINK, GRIN, TONGUE, COOL, MONEY,  # subject smileys
	CAT,
	BUILDING, NEWSPAPER, STRANGER, LOCK, STAR,  # sender kinds + boss
	CLIP, ENVELOPE,
}

const SMILEYS := [Icon.SMILE, Icon.WINK, Icon.GRIN, Icon.TONGUE, Icon.COOL, Icon.MONEY]

const PALETTE := {
	"k": Color("1a1a1a"),  # outline
	"y": Color("ffd23f"),  # smiley yellow
	"Y": Color("fff3a0"),  # highlight
	"o": Color("d99a1c"),  # gold shade
	"w": Color("ffffff"),
	"p": Color("ff6f86"),  # tongue / nose
	"m": Color("2fa84f"),  # money green
	"c": Color("f0a040"),  # cat orange
	"b": Color("3b6fd8"),  # window blue
	"l": Color("d4d0c8"),  # light grey
	"g": Color("9a9a9a"),
	"G": Color("5a5a5a"),  # dark grey
	"n": Color("7a4a24"),  # brown
}

const GRIDS := {
	Icon.SMILE: [
		"....kkkk....",
		"..kkyyyykk..",
		".kyYYyyyyyk.",
		".kyYyyyyyyk.",
		"kyyykyykyyyk",
		"kyyykyykyyyk",
		"kyyyyyyyyyyk",
		"kykyyyyyykyk",
		"kyykyyyykyyk",
		".kyykkkkyyk.",
		"..kkyyyykk..",
		"....kkkk....",
	],
	Icon.WINK: [
		"....kkkk....",
		"..kkyyyykk..",
		".kyYYyyyyyk.",
		".kyYyyyyyyk.",
		"kyyyyyykyyyk",
		"kykkyyykyyyk",
		"kyyyyyyyyyyk",
		"kykyyyyyykyk",
		"kyykyyyykyyk",
		".kyykkkkyyk.",
		"..kkyyyykk..",
		"....kkkk....",
	],
	Icon.GRIN: [
		"....kkkk....",
		"..kkyyyykk..",
		".kyYYyyyyyk.",
		".kyYyyyyyyk.",
		"kyyykyykyyyk",
		"kyyykyykyyyk",
		"kyyyyyyyyyyk",
		"kykkkkkkkkyk",
		"kyykwwwwkyyk",
		".kyykkkkyyk.",
		"..kkyyyykk..",
		"....kkkk....",
	],
	Icon.TONGUE: [
		"....kkkk....",
		"..kkyyyykk..",
		".kyYYyyyyyk.",
		".kyYyyyyyyk.",
		"kyyykyykyyyk",
		"kyyykyykyyyk",
		"kyyyyyyyyyyk",
		"kyykkkkkkyyk",
		"kyyyykppkyyk",
		".kyyyykkyyk.",
		"..kkyyyykk..",
		"....kkkk....",
	],
	Icon.COOL: [
		"....kkkk....",
		"..kkyyyykk..",
		".kyYYyyyyyk.",
		".kyYyyyyyyk.",
		"kkkkkkkkkkkk",
		"kykkkyykkkyk",
		"kyyyyyyyyyyk",
		"kykyyyyyykyk",
		"kyykyyyykyyk",
		".kyykkkkyyk.",
		"..kkyyyykk..",
		"....kkkk....",
	],
	Icon.MONEY: [
		"....kkkk....",
		"..kkyyyykk..",
		".kyYYyyyyyk.",
		".kyYyyyyyyk.",
		"kyymmyymmyyk",
		"kyymmyymmyyk",
		"kyyyyyyyyyyk",
		"kykkkkkkkkyk",
		"kyykmmmmkyyk",
		".kyykkkkyyk.",
		"..kkyyyykk..",
		"....kkkk....",
	],
	Icon.CAT: [
		".k........k.",
		"kck......kck",
		"kcckkkkkkcck",
		"kcccccccccck",
		"kcckcccckcck",
		"kcckcccckcck",
		"kccccppcccck",
		"kccckcckccck",
		".kccckkccck.",
		"..kkcccckk..",
		"....kkkk....",
		"............",
	],
	Icon.BUILDING: [
		"...kkkkkk...",
		"...kllllk...",
		"...klblbk...",
		"...kllllk...",
		"kkkklblbkkkk",
		"kllkllllkllk",
		"klbklblbklbk",
		"kllkllllkllk",
		"klbklblbklbk",
		"kllkllllkllk",
		"kllklnnlkllk",
		"kkkkkkkkkkkk",
	],
	Icon.NEWSPAPER: [
		"kkkkkkkkkk..",
		"kwwwwwwwwkk.",
		"kwGGGGGGwkwk",
		"kwwwwwwwwkwk",
		"kwGGwlllwkwk",
		"kwGGwwwwwkwk",
		"kwwwwlllwkwk",
		"kwlllwwwwkwk",
		"kwwwwlllwkwk",
		"kwlllwwwwkwk",
		"kkkkkkkkkkwk",
		".kkkkkkkkkkk",
	],
	Icon.STRANGER: [
		"....kkkk....",
		"..kkGGGGkk..",
		".kGGwwwwGGk.",
		".kGwwGGwwGk.",
		"kGGGGGGwwGGk",
		"kGGGGGwwGGGk",
		"kGGGGwwGGGGk",
		"kGGGGwwGGGGk",
		".kGGGGGGGGk.",
		".kGGGwwGGGk.",
		"..kkGwwGkk..",
		"....kkkk....",
	],
	Icon.LOCK: [
		"....kkkk....",
		"...kGllGk...",
		"..kGk..kGk..",
		"..kGk..kGk..",
		"..kGk..kGk..",
		".kkkkkkkkkk.",
		".koooooooyk.",
		".kyyyykyyyk.",
		".kyyykkkyyk.",
		".kyyyykyyyk.",
		".kooooooook.",
		".kkkkkkkkkk.",
	],
	Icon.STAR: [
		".....kk.....",
		".....kk.....",
		"....kyyk....",
		"....kyyk....",
		"kkkkkyykkkkk",
		".kyyyyyyyyk.",
		"..kyyyyyyk..",
		"...kyyyyk...",
		"..kyyykyyyk.",
		"..kyyk.kyyk.",
		".kyk....kyk.",
		".kk......kk.",
	],
	Icon.CLIP: [
		".....GG.....",
		"....G..G....",
		"....G..G....",
		"....G.GG....",
		"....G.G.G...",
		"....G.G.G...",
		"....G.G.G...",
		"....G.G.G...",
		"....G...G...",
		".....G.G....",
		"......G.....",
		"............",
	],
	Icon.ENVELOPE: [
		"............",
		"............",
		"kkkkkkkkkkkk",
		"kwkwwwwwwkwk",
		"kwwkwwwwkwwk",
		"kwwwkwwkwwwk",
		"kwwwwkkwwwwk",
		"kwwwwwwwwwwk",
		"kwwwwwwwwwwk",
		"kkkkkkkkkkkk",
		"............",
		"............",
	],
}

static var _cache := {}


static func texture(icon: Icon) -> Texture2D:
	if not _cache.has(icon):
		var grid: Array = GRIDS[icon]
		var img := Image.create(12, 12, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		for y in grid.size():
			var row: String = grid[y]
			for x in mini(row.length(), 12):
				if PALETTE.has(row[x]):
					img.set_pixel(x, y, PALETTE[row[x]])
		_cache[icon] = ImageTexture.create_from_image(img)
	return _cache[icon]


## Draws an icon with its top-left at `pos`, scaled to `size` pixels.
static func draw(ci: CanvasItem, icon: Icon, pos: Vector2, size: float, modulate: Color = Color.WHITE) -> void:
	ci.draw_texture_rect(texture(icon), Rect2(pos, Vector2(size, size)), false, modulate)


static func draw_centered(ci: CanvasItem, icon: Icon, center: Vector2, size: float, modulate: Color = Color.WHITE) -> void:
	draw(ci, icon, center - Vector2(size, size) * 0.5, size, modulate)
