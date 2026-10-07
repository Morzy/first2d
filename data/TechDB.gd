class_name TechDB

# Each tech: prereqs (Array[String]) + cost (S/E/C) + effect (Dictionary)
const DATA: Dictionary = {
	"basic_physics": {
		"name": "基础物理",
		"desc": "所有研究产出 +10%",
		"prereqs": [],
		"cost": {"S": 50, "E": 0, "C": 0},
		"effect": {"all_rate_pct": 0.10},
	},
	"antimatter_research": {
		"name": "反物质研究",
		"desc": "理科产出 +20%",
		"prereqs": ["basic_physics"],
		"cost": {"S": 500, "E": 0, "C": 0},
		"effect": {"science_rate_pct": 0.20},
	},
	"orbital_engineering": {
		"name": "轨道工程",
		"desc": "工科产出 +15%",
		"prereqs": [],
		"cost": {"S": 0, "E": 100, "C": 0},
		"effect": {"engineering_rate_pct": 0.15},
	},
	"antimatter_cannon": {
		"name": "反物质炮",
		"desc": "帝国武力 +500",
		"prereqs": ["antimatter_research", "orbital_engineering"],
		"cost": {"S": 5000, "E": 10000, "C": 0},
		"effect": {"empire_power": 500},
	},
	"multiculturalism": {
		"name": "多元文化",
		"desc": "社科产出 +15%",
		"prereqs": [],
		"cost": {"S": 0, "E": 0, "C": 100},
		"effect": {"social_rate_pct": 0.15},
	},
	"interspecies_union": {
		"name": "物种通婚政策",
		"desc": "主角可继承其他物种天赋",
		"prereqs": ["multiculturalism"],
		"cost": {"S": 0, "E": 0, "C": 2000},
		"effect": {"cross_species_talents": true},
	},
}
