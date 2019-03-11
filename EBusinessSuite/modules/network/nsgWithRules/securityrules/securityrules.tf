
####################################
##  NSG Rule 
##   
####################################

locals {
    finalRule = "${merge(var.base_rule_value,var.rule_overrides[0])}"
}

module "securityRuleList" {
    source = "./securityRuleHelper"
    rule_overrides_count = 1  # "${var.rule_overrides_count}" # "${length(var.rule_overrides)}"
    rule_overrides = "${var.rule_overrides}"
    base_rule_value = "${var.base_rule_value}"
    basename_prefix = "${var.basename_prefix}"
   # r_s = "${var.rule_overrides[0]}"
    #r_s = "${local.finalRule}"
    r_s = "${merge(var.base_rule_value,var.rule_overrides[0])}"
  #  rule_type = "${(contains(keys(local.finalRule),"source_address_prefix") ? 0 : 2) + (contains(keys(local.finalRule),"destination_address_prefix") ? 0 : 1)}"
    rule_type0 = 99 #"${contains(keys(local.finalRule),"source_address_prefix") || contains(keys(local.finalRule),"destination_address_prefix")}"

#    name =  "${join("-",list(var.basename_prefix,lower(lookup(merge(var.base_rule_value,var.rule_overrides[count.index]),"direction")),format("%.2d",count.index+1)))}"

}
/*
resource "azurerm_network_security_rule" "NSGSecurityRule" {
    count = "${var.rule_overrides_count}" # "${length(var.rule_overrides)}"
    name =  "${join("-",list(var.basename_prefix,lower(lookup(merge(var.base_rule_value,var.rule_overrides[count.index]),"direction")),format("%.2d",count.index+1)))}"

    priority = "${lookup(merge(var.base_rule_value,var.rule_overrides[count.index]),"priority") + count.index}"
    direction = "${lookup(merge(var.base_rule_value,var.rule_overrides[count.index]),"direction")}"    
    access = "${lookup(merge(var.base_rule_value,var.rule_overrides[count.index]),"access")}" 
    protocol = "${lookup(merge(var.base_rule_value,var.rule_overrides[count.index]),"protocol")}"   

    #source_port_ranges = [ 
    #    "${split(",",lookup(merge(var.base_rule_value,var.rule_overrides[count.index]),"source_port_ranges_str"))}"             
    #]       

    source_port_ranges = [ 
        "${split(",",lookup(merge(var.base_rule_value,var.rule_overrides[count.index]),"source_port_ranges"))}"             
    ]   

    #destination_port_ranges = [ 
    #    "${split(",",lookup(merge(var.base_rule_value,var.rule_overrides[count.index]),"destination_port_ranges_str"))}"         
    #]    
    
    destination_port_ranges = [ 
        "${split(",",lookup(merge(var.base_rule_value,var.rule_overrides[count.index]),"destination_port_ranges"))}"         
    ] 

    source_address_prefix = "${lookup(merge(var.base_rule_value,var.rule_overrides[count.index]),"source_address_prefix","")}"
    source_application_security_group_ids = [ "${lookup(merge(var.base_rule_value,var.rule_overrides[count.index]),"source_application_security_group_id","")}" ]   

    destination_address_prefix = "${lookup(merge(var.base_rule_value,var.rule_overrides[count.index]),"destination_address_prefix","")}"
    destination_application_security_group_ids = [ "${lookup(merge(var.base_rule_value,var.rule_overrides[count.index]),"destination_application_security_group_id","")}" ]

    network_security_group_name = "${lookup(merge(var.base_rule_value,var.rule_overrides[count.index]),"network_security_group_name")}"
    resource_group_name = "${lookup(merge(var.base_rule_value,var.rule_overrides[count.index]),"resource_group_name")}" 


 #  depends_on = [ "null_resource.NSGFinalRules"]
 # TODO -- needs to be literal
 #   depends_on = "${null_resource.NSGFinalRules.*.blended.depends_on[count.index]}" 

}
 */