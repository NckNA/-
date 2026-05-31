extends Resource
class_name PlayerData

var name: String = "Игрок"
var global_x: int = 0
var global_y: int = 0
var health: int = 100
var hunger: int = 0
var energy: int = 100
var inventory: Dictionary = {}
var skills: Dictionary = {}


func change_health(amount: int) -> void:
	health = clamp(health + amount, 0, 100)


func change_energy(amount: int) -> void:
	energy = clamp(energy + amount, 0, 100)


func ensure_skills_initialized() -> void:
	_ensure_skill_exists("survival")
	_ensure_skill_exists("construction")
	_ensure_skill_exists("cooking")


func get_skill_level(skill_name: String) -> int:
	ensure_skills_initialized()

	if not skills.has(skill_name):
		return 1

	var skill_data: Dictionary = skills[skill_name]
	return int(skill_data.get("level", 1))


func get_skill_xp(skill_name: String) -> int:
	ensure_skills_initialized()

	if not skills.has(skill_name):
		return 0

	var skill_data: Dictionary = skills[skill_name]
	return int(skill_data.get("xp", 0))


func get_xp_required_for_next_level(level: int) -> int:
	return level * 20


func add_skill_xp(skill_name: String, amount: int) -> Dictionary:
	ensure_skills_initialized()

	if amount <= 0:
		return {"leveled_up": false}

	if not skills.has(skill_name):
		_ensure_skill_exists(skill_name)

	var skill_data: Dictionary = skills[skill_name]
	var current_level: int = int(skill_data.get("level", 1))
	var current_xp: int = int(skill_data.get("xp", 0)) + amount
	var xp_required: int = get_xp_required_for_next_level(current_level)

	if current_xp >= xp_required:
		current_xp -= xp_required
		current_level += 1
		skill_data["xp"] = current_xp
		skill_data["level"] = current_level
		skills[skill_name] = skill_data

		return {
			"leveled_up": true,
			"skill_name": skill_name,
			"new_level": current_level
		}

	skill_data["xp"] = current_xp
	skill_data["level"] = current_level
	skills[skill_name] = skill_data
	return {"leveled_up": false}


func _ensure_skill_exists(skill_name: String) -> void:
	if not skills.has(skill_name) or not skills[skill_name] is Dictionary:
		skills[skill_name] = {
			"xp": 0,
			"level": 1
		}
		return

	var skill_data: Dictionary = skills[skill_name]

	if not skill_data.has("xp"):
		skill_data["xp"] = 0
	if not skill_data.has("level"):
		skill_data["level"] = 1

	skill_data["xp"] = int(skill_data.get("xp", 0))
	skill_data["level"] = int(skill_data.get("level", 1))
	skills[skill_name] = skill_data
