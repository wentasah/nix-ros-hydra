all: spec.json experiments.json

spec.json: generate-jobsets.py
	./generate-jobsets.py nix_ros_overlay > $@

experiments.json: generate-jobsets.py
	./generate-jobsets.py nix_ros_experiments > $@
