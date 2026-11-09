class_name DebugMode
extends RefCounted
## Local-only switch that unlocks every bench so all content can be reached without
## earning XP. Off unless the game is started with `-- --unlock-all` or exported with
## the `unlock_all` custom feature, so release builds behave exactly as before.

const ARG := "--unlock-all"
const FEATURE := "unlock_all"

static var _unlock_all: int = -1   ## -1 unresolved, 0 off, 1 on


static func unlock_all() -> bool:
	if _unlock_all < 0:
		_unlock_all = 1 if (OS.has_feature(FEATURE) or OS.get_cmdline_user_args().has(ARG)) else 0
	return _unlock_all == 1
