.PHONY: docs test
docs:
	terraform-docs markdown table --output-file README.md .

test:
	terraform fmt -check -recursive .
	terraform init -backend=false
	terraform validate
	terraform test
