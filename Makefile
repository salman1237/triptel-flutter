# Thin wrapper; harness.sh is canonical (no `make` on the dev machine).
NAME ?= screen
.PHONY: setup run test verify build device-check shot
setup run test verify build device-check:
	bash harness.sh $@
shot:
	bash harness.sh shot $(NAME)
