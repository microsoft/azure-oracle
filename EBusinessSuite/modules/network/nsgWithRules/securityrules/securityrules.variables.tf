
variable "base_rule_value" {
    description = "Single map of operands for SecurityRule instance.  This is overlaid with rule_override elements to get final operands for instance."
    type = "map"
}

variable "rule_overrides" {
    description = "List of rule value objects -- used to overlay base_rule_value for final SecurityRule operands"
    type = "list"
}

variable "basename_prefix" {
    description = "A string to prefix rule name with. Note that if a rule name is specified in the overrides, that value will be used instead for the rulename."
    type = "string"
}


