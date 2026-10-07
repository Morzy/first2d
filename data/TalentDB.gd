class_name TalentDB

# Global talent pool — grows as game progresses
const DATA: Dictionary = {
	"brute":   {"name": "大力",   "desc": "物理攻击 +10%",  "effect_type": "phys_atk_pct",  "value": 0.10},
	"keen":    {"name": "聪慧",   "desc": "法力上限 +10%",  "effect_type": "mana_pct",       "value": 0.10},
	"tough":   {"name": "强韧",   "desc": "生命值 +15%",    "effect_type": "hp_pct",         "value": 0.15},
	"psionic": {"name": "灵感",   "desc": "科研速度 +5%",   "effect_type": "research_pct",   "value": 0.05},
	"swift":   {"name": "敏捷",   "desc": "行动速度 +8%",   "effect_type": "speed_pct",      "value": 0.08},
}
