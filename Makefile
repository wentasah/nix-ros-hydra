all: spec.json experiments.json wentasah.json

spec.json: generate-jobsets.py
	./generate-jobsets.py nix_ros_overlay > $@

wentasah.json: generate-jobsets.py
	./generate-jobsets.py nix_ros_overlay_wentasah > $@

experiments.json: generate-jobsets.py
	./generate-jobsets.py nix_ros_experiments > $@
