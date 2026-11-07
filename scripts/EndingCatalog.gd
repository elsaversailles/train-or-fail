extends RefCounted

# These six outcomes are collectible, in gallery order.
const ENDINGS := {
	"algorithm_reformer": {
		"title": "Algorithm Reformer",
		"image": "res://images/Endings/Algorithm_Reformer.png",
		"description": "Your exceptional performance and ethical auditing force Maypaya Financial to re-evaluate their risk criteria, establishing you as a key asset who bridges ethics and efficiency."
	},
	"another_cog_in_the_machine": {
		"title": "Another Cog in the Machine",
		"image": "res://images/Endings/Another_Cog_In_The_Machine.png",
		"description": "You are officially an average employee. You retain your analyst position with a modest annual cost-of-living raise.\n\nWalking home, you see a neighborhood of compromises—half the storefronts are bustling, while the other half are boarded up. You survived the system, but you didn't change it."
	},
	"cold_efficiency": {
		"title": "Cold Efficiency",
		"image": "res://images/Endings/Cold_Efficiency.png",
		"description": "You prioritized the company's algorithm over human empathy. You step into a spacious upper-management office with a view, but the city below feels hollow."
	},
	"conflict_of_interest": {
		"title": "Conflict of Interest",
		"image": "res://images/Endings/Conflict_of_Interest.png",
		"description": "Management flags the unauthorized approval. You are stripped of your analyst title and reassigned to low-level administrative duty, but Lolo’s business stays alive."
	},
	"stagnant_survival": {
		"title": "Stagnant Survival",
		"image": "res://images/Endings/Stagnant_Survival.png",
		"description": "You stay employed at Maypaya, but corporate locks your salary, freezes promotion paths, and assigns you to endless routine data entry in a secluded corner."
	},
	"clean_exit": {
		"title": "The Clean Exit",
		"image": "res://images/Endings/The_Clean_Exit.png",
		"description": "Rejecting the corporate grind, you hand over your badge and leave Maypaya behind to seek a fresh start, entering the job market with empty hands but a clear conscience."
	}
}

const TERMINATED := {
	"title": "Terminated",
	"image": "res://images/Endings/Terminated.png",
	"description": "Excessive evaluation errors result in immediate termination for incompetence before you can make any lasting impact on the business or the community."
}

const GRANDPA_SHIFT := "grandpa_shift"
const CAREER_CHOICE := "career_choice"
const SPECIAL_IDS := ["tita_elena", "mark_krazy", "nurse_clara", "jericho_santur"]


static func get_presentation(ending_id: String) -> Dictionary:
	return TERMINATED if ending_id == "terminated" else ENDINGS.get(ending_id, {})


# Both gameplay and older completed saves use the original day-nine branch rules.
static func get_final_route(data: Dictionary) -> String:
	var decisions: Dictionary = data.get("special_decisions", {})
	var unanimous: String = decisions.get(SPECIAL_IDS[0], "")
	for character_id in SPECIAL_IDS:
		if decisions.get(character_id, "") != unanimous:
			unanimous = ""
			break
	match unanimous:
		"sus":
			return GRANDPA_SHIFT
		"legit":
			return "algorithm_reformer"
	if data.get("total_score", 0) == 27:
		return CAREER_CHOICE
	return "another_cog_in_the_machine"


static func get_grandpa_ending(verdict: String) -> String:
	return "cold_efficiency" if verdict == "sus" else "conflict_of_interest"
