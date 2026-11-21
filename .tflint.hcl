# preset "recommended" (as in CI via pre-commit tofu_tflint). "all" additionally wants descriptions for every
# variable/output and outputs.tf/variables.tf in every module – ~300 findings in the modules taken over from
# basement; switch to "all" once they are documented.
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}
