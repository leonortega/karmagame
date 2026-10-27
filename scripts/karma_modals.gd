class_name KarmaModals
extends RefCounted

# Pure modal selector + display-only roulette helpers (no engine I/O).
# Scene-owned Main keeps all Control nodes and input wiring.

const SETTLE_AFTER := 1.6
const CYCLE_PER_SEC := 8.0


static func active_modal(state: Dictionary) -> String:
	if bool(state.get("dead", false)):
		return "judgment"
	if not bool(state.get("introDone", true)):
		return "birth"
	if bool(state.get("paused", false)):
		return "pause"
	if bool(state.get("shopOpen", false)):
		return "shop"
	return ""


static func is_modal_open(state: Dictionary) -> bool:
	return active_modal(state) != ""


static func roulette_pick(pool: Array, next_key: String, t: float) -> String:
	if pool.is_empty():
		return next_key
	if pool.size() == 1:
		return str(pool[0])
	if t >= SETTLE_AFTER:
		return next_key
	var idx := int(t * CYCLE_PER_SEC) % pool.size()
	return str(pool[idx])
