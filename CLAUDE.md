# CLAUDE.md – tofu-modules

OpenTofu modules of dreitier, consumed by dreitier/basement (Terragrunt; locally `../basement`, its CLAUDE.md
has the architecture, rules and lessons). Communicate with the user (Thomas) in German; code, comments and docs
are in English.

## Rules

- One module per directory under `modules/`, versioned on its own (multi-semantic-release, tags
  `<module>@x.y.z`). PR titles are Conventional Commits with the module as scope (`fix(keycloak): …`); a
  breaking change to inputs/outputs or a change that replaces/destroys resources is `feat!`/`fix!`.
- No secrets in git or in the state: `ephemeral` resources for credentials, write-only attributes (`*_wo` +
  version) for generated secrets, never `data "sops_file"`.
- Stateful resources keep `prevent_destroy`. Renaming resources needs `moved` blocks – basement's states
  depend on the addresses.
- The leading comment of `main.tf` describes the module; README.md: description by hand, inputs/outputs from
  terraform-docs (pre-commit). Every new module needs `package.json` (`name`, `"version": "0.0.0"`).
- Check before finishing: `pre-commit run -a` (tofu fmt, tflint, trivy, terraform-docs);
  `tofu init -backend=false && tofu validate` in the changed modules. Test against the real infrastructure from
  basement with `TG_MODULES_ROOT=<this checkout>/modules` (plan only; applies stay with Thomas).
