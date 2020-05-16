<?php

class GpioAPI {

	public static $gpio_mapping = [
		1 => 24,
		2 => 25,
		3 => 16,
		4 => 17,
		5 => 27,
		6 => 22,
		7 => 5,
		8 => 6
	];

	public static function store($actions) {
		$json_web = "../gpio/json/values.json";
		$json_gpio = "../../config/gpio.json";
		if (!empty($actions)) {
			$actions_mapped = $actions;
			$action_index = 0;
			foreach ($actions as $action_obj) {
				$trigger =  $action_obj["trigger"];
				$param_idx = 0;
				foreach ($action_obj["param"] as $relay_action) {
					$param_name = $relay_action["name"];
					$slots_updated = [];
					$slots_formatted = [];
					foreach ($relay_action["slots"] as $relay_cmd) {
						$relay_cmd["state"] = intval($relay_cmd["state"]);
						$relay_cmd["gpio"] = intval($relay_cmd["gpio"]);
						array_push($slots_formatted, $relay_cmd);
						$relay_cmd_updated = $relay_cmd;
						$relay_cmd_updated["gpio"] = self::$gpio_mapping[$relay_cmd["gpio"]];
						array_push($slots_updated, $relay_cmd_updated);
					}
					$actions[$action_index]["param"][$param_idx]["slots"] = $slots_updated;
					$actions_mapped[$action_index]["param"][$param_idx]["slots"] = $slots_formatted;
					$param_idx++;
				}
				$action_index++;
			}
			if(file_put_contents($json_web, json_encode(["actions" => $actions_mapped], JSON_PRETTY_PRINT))) {
				file_put_contents($json_gpio, json_encode(["actions" => $actions], JSON_PRETTY_PRINT));
				return "json-ok";
			} else {
				return "json-error";
			}
			return "ok";
		}
		return "no-actions";
	}
}
