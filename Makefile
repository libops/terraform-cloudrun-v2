.PHONY: docs
docs:
	terraform-docs markdown table --output-file README.md .
