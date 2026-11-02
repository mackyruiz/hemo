class_name CellShapes
extends RefCounted
## Cell silhouettes in local coordinates. Random builders use only the supplied RNG.


static func circle(r: float, n: int = 48) -> PackedVector2Array:
	return _ellipse(r, r, maxi(n, 8))


static func ellipse(rx: float, ry: float) -> PackedVector2Array:
	return _ellipse(rx, ry, 48)


static func _ellipse(rx: float, ry: float, n: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(n):
		var a: float = TAU * float(i) / n
		points.append(Vector2(cos(a) * rx, sin(a) * ry))
	return points


static func sickle(r: float) -> PackedVector2Array:
	return _notched_circle(r, 0.65 * r, 0.9 * r)


static func bite(r: float) -> PackedVector2Array:
	return _notched_circle(r, r, 0.5 * r)


static func _notched_circle(r: float, offset: float, notch: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	if r <= 0.0:
		return circle(0.0)
	var x: float = (r * r - notch * notch + offset * offset) / (2.0 * offset)
	var y: float = sqrt(maxf(0.0, r * r - x * x))
	var outer_angle: float = atan2(y, x)
	for i in range(41):
		var a: float = lerpf(outer_angle, TAU - outer_angle, i / 40.0)
		points.append(Vector2(cos(a), sin(a)) * r)
	var inner_top: float = atan2(y, x - offset)
	for i in range(1, 25):
		var a: float = lerpf(TAU - inner_top, inner_top, i / 24.0)
		points.append(Vector2(offset + cos(a) * notch, sin(a) * notch))
	return points


static func teardrop(r: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(48):
		var a: float = TAU * i / 48.0
		# A rounded body tapering into a single upper pole.
		var x: float = r * cos(a) * (0.70 + 0.27 * sin(a))
		var y: float = r * sin(a)
		if sin(a) < 0.0:
			y -= r * 0.35 * pow(-sin(a), 6.0)
		points.append(Vector2(x, y + r * 0.1))
	return points


static func fragment(r: float, rng: RandomNumberGenerator) -> PackedVector2Array:
	var n: int = rng.randi_range(4, 6)
	var points := PackedVector2Array()
	for i in range(n):
		var a: float = TAU * i / n
		var radius: float = r * (0.35 if i == 1 else rng.randf_range(0.75, 1.0))
		points.append(Vector2(cos(a), sin(a)) * radius)
	return points


static func spiculated(r: float, spikes: int, spike_len: float, irregular: bool, rng: RandomNumberGenerator) -> PackedVector2Array:
	var points := PackedVector2Array()
	var count: int = clampi(spikes, 3, 40)
	for i in range(count):
		var a: float = TAU * i / count
		var length: float = spike_len * (rng.randf_range(0.55, 1.45) if irregular else 1.0)
		var shift: float = rng.randf_range(-0.2, 0.2) * TAU / count if irregular else 0.0
		points.append(Vector2.from_angle(a - 0.40 * TAU / count) * r)
		# Two close tip points produce a slightly knobbed acanthocyte spur.
		points.append(Vector2.from_angle(a + shift - 0.025) * (r + length))
		points.append(Vector2.from_angle(a + shift + 0.025) * (r + length))
		points.append(Vector2.from_angle(a + 0.40 * TAU / count) * r)
	return points


static func lobed_nucleus(r: float, lobes: int, rng: RandomNumberGenerator) -> PackedVector2Array:
	var points := PackedVector2Array()
	var count: int = clampi(lobes, 2, 8)
	var phase: float = rng.randf_range(-0.12, 0.12)
	for i in range(128):
		var a: float = TAU * i / 128.0
		var radius: float = r * (0.36 + 0.64 * pow((1.0 + cos(count * a + phase)) * 0.5, 0.55))
		points.append(Vector2.from_angle(a) * radius)
	return points


static func kidney(r: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(64):
		var a: float = TAU * i / 64.0
		var p := Vector2(cos(a) * r, sin(a) * r * 0.75)
		if cos(a) > 0.0:
			p.x -= r * 0.8 * pow(cos(a), 4.0)
		points.append(p)
	return points


static func band(r: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(41):
		var a: float = lerpf(0.28 * PI, 1.72 * PI, i / 40.0)
		points.append(Vector2.from_angle(a) * r)
	for i in range(41):
		var a: float = lerpf(1.72 * PI, 0.28 * PI, i / 40.0)
		points.append(Vector2.from_angle(a) * r * 0.48)
	return points
