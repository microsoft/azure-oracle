
####################################
##  SecurityRuleHelper.tf   
####################################

#module "securityRuleHelper" {
    /*
    count = "${var.rule_overrides_count}" # "${length(var.rule_overrides)}"
    name =  "${join("-",list(var.basename_prefix,lower(lookup(merge(var.base_rule_value,var.rule_overrides[count.index]),"direction")),format("%.2d",count.index+1)))}"

}

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

 #   depends_on = [ "null_resource.NSGFinalRules"]
 # TODO -- needs to be literal
 #   depends_on = "${null_resource.NSGFinalRules.*.blended.depends_on[count.index]}" 

}
*/

#################################################################################################
## Need two variants of rules - could be ASG or NSG, which require different parameters.
##
## As there's no way to vary which parameters are specified (i.e., no special RHS syntax 
## to have a parameter ignored), so no way to use count.Index.  Thus, the approach below is to
## unroll the security rules into two lists -- one for ASGs, one for NSGs and then use the
## count parameter on the rule as a conditional (value==0 means don't provision) to control
## which rules are actually provisioned.   
##
## Aside:  so run list of rules against both lists and the individual rule will be provisioned
##         from one list or the other, depending on the parameters.
##
## Note that a side effect of this approach is a maxiumum on the number of rules possible in a
## set -- gated by the length of each of the two lists, currently 10.
##
## Variations:
##     0. Source and Destination address prefixes
##     1. Source address prefix + Destination ASG
##     2. Source ASG + Destination address prefix
##     3. Source ASG + Destination ASG
##  So 4 lists needed :-(
#################################################################################################

locals {
    emptyMap = { }
    badType = 0   # for now, process something unexpected as Type 0.  If we used -1, there'd be no error from TF.

    #m0 = "${zipmap(keys(var.rule_overrides[0]),values(var.rule_overrides[0]))}"
    #merge0 = "${(var.rule_overrides_count >= 1) ? merge(var.base_rule_value,var.rule_overrides[0]) : local.emptyMap}"
    #merge0 = "${(var.rule_overrides_count >= 1) ? merge(var.base_rule_value,local.emptyMap) : local.emptyMap}"    
    #merge0 = "${merge(var.base_rule_value,var.r_s)}"    
    merge0 = "${var.r_s}"
  #  type0  = "${(contains(keys(local.merge0),"source_address_prefix") ? 0 : 2) + (contains(keys(local.merge0),"destination_address_prefix") ? 0 : 1)}"
  /*
    type0a  = "${(contains(keys(local.merge0),"source_address_prefix") ? 0 : 2)}"
    type0b  = "${(contains(keys(local.merge0),"destination_address_prefix") ? 0 : 1)}"
    type0 = "${local.type0a + local.type0b}"
    isT0 = "${contains(keys(var.r_s),"source_application_security_group_ids")}"
    */

/*
    merge1 = "${(var.rule_overrides_count >= 2) ? merge(var.base_rule_value,var.rule_overrides[1]) : local.emptyMap}"
    merge2 = "${(var.rule_overrides_count >= 3) ? merge(var.base_rule_value,var.rule_overrides[2]) : local.emptyMap}"
    merge3 = "${(var.rule_overrides_count >= 4) ? merge(var.base_rule_value,var.rule_overrides[3]) : local.emptyMap}"
    merge4 = "${(var.rule_overrides_count >= 5) ? merge(var.base_rule_value,var.rule_overrides[4]) : local.emptyMap}"
    merge5 = "${(var.rule_overrides_count >= 6) ? merge(var.base_rule_value,var.rule_overrides[5]) : local.emptyMap}"
    merge6 = "${(var.rule_overrides_count >= 7) ? merge(var.base_rule_value,var.rule_overrides[6]) : local.emptyMap}"
    merge7 = "${(var.rule_overrides_count >= 8) ? merge(var.base_rule_value,var.rule_overrides[7]) : local.emptyMap}"
    merge8 = "${(var.rule_overrides_count >= 9) ? merge(var.base_rule_value,var.rule_overrides[8]) : local.emptyMap}"
    merge9 = "${(var.rule_overrides_count >= 10)? merge(var.base_rule_value,var.rule_overrides[9]) : local.emptyMap}"
*/
}
resource "azurerm_network_security_rule" "NSGSecurityRuleT0" {  # Source Prefix / Dest Prefix
    #count = "${(local.type0 == 0) ? 1 : 0}"
    count = "${var.r_s["flavor"] == "SP-DP" ? 1 : 0}"
    #count = "${local.count}"
    #count = "${(var.rule_overrides_count >= 1 && contains(keys(var.rule_overrides[0]),"source_application_security_group_ids")) ? 1 : 0}"
    name =  "${join("-",list(var.basename_prefix,lower(lookup(local.merge0,"direction")),format("%.2d",1)))}"

    priority    = "${lookup(local.merge0,"priority") + 0}"
    direction   = "${lookup(local.merge0,"direction")}"    
    access      = "${lookup(local.merge0,"access")}" 
    protocol    = "${lookup(local.merge0,"protocol")}"      

    source_port_ranges = [ "${split(",",lookup(local.merge0,"source_port_ranges"))}" ]   
    
    destination_port_ranges = [ "${split(",",lookup(local.merge0,"destination_port_ranges"))}" ] 

    source_address_prefix = "${lookup(local.merge0,"source_address_prefix","")}"
    destination_address_prefix = "${lookup(local.merge0,"destination_address_prefix","")}"

    network_security_group_name = "${lookup(local.merge0,"network_security_group_name")}"
    resource_group_name = "${lookup(local.merge0,"resource_group_name")}" 
}

resource "azurerm_network_security_rule" "NSGSecurityRuleT1" {  # Source Prefix / Dest ASG
    #count = "${(local.type0 == 1) ? 1 : 0}"
    count = "${var.r_s["flavor"] == "SP-DA" ? 1 : 0}"    
    name =  "${join("-",list(var.basename_prefix,lower(lookup(local.merge0,"direction")),format("%.2d",1)))}"

    priority    = "${lookup(local.merge0,"priority") + 0}"
    direction   = "${lookup(local.merge0,"direction")}"    
    access      = "${lookup(local.merge0,"access")}" 
    protocol    = "${lookup(local.merge0,"protocol")}"      

    source_port_ranges = [ "${split(",",lookup(local.merge0,"source_port_ranges"))}" ]   
    destination_port_ranges = [ "${split(",",lookup(local.merge0,"destination_port_ranges"))}" ] 

    source_address_prefix = "${lookup(local.merge0,"source_address_prefix","")}"
    destination_application_security_group_ids = [ "${lookup(local.merge0,"destination_application_security_group_id","")}" ]

    network_security_group_name = "${lookup(local.merge0,"network_security_group_name")}"
    resource_group_name = "${lookup(local.merge0,"resource_group_name")}" 
}

resource "azurerm_network_security_rule" "NSGSecurityRuleT2" {  # Source ASG / Dest Prefix
    #count = "${(local.type0 == 2) ? 1 : 0}"
    count = "${var.r_s["flavor"] == "SA-DP" ? 1 : 0}"       
    name =  "${join("-",list(var.basename_prefix,lower(lookup(local.merge0,"direction")),format("%.2d",1)))}"

    priority    = "${lookup(local.merge0,"priority") + 0}"
    direction   = "${lookup(local.merge0,"direction")}"    
    access      = "${lookup(local.merge0,"access")}" 
    protocol    = "${lookup(local.merge0,"protocol")}"      

    source_port_ranges = [ "${split(",",lookup(local.merge0,"source_port_ranges"))}" ]   
    destination_port_ranges = [ "${split(",",lookup(local.merge0,"destination_port_ranges"))}" ] 

    source_application_security_group_ids = [ "${lookup(local.merge0,"source_application_security_group_id","")}" ]      
    destination_address_prefix = "${lookup(local.merge0,"destination_address_prefix","")}"

    network_security_group_name = "${lookup(local.merge0,"network_security_group_name")}"
    resource_group_name = "${lookup(local.merge0,"resource_group_name")}" 
}

resource "azurerm_network_security_rule" "NSGSecurityRuleT3" {  # Source ASG / Dest ASG
    #count = "${(local.type0 == 3) ? 1 : 0}"
    count = "${var.r_s["flavor"] == "SA-DA" ? 1 : 0}"      
    name =  "${join("-",list(var.basename_prefix,lower(lookup(local.merge0,"direction")),format("%.2d",1)))}"

    priority    = "${lookup(local.merge0,"priority") + 0}"
    direction   = "${lookup(local.merge0,"direction")}"    
    access      = "${lookup(local.merge0,"access")}" 
    protocol    = "${lookup(local.merge0,"protocol")}"      

    source_port_ranges = [ "${split(",",lookup(local.merge0,"source_port_ranges"))}" ]   
    destination_port_ranges = [ "${split(",",lookup(local.merge0,"destination_port_ranges"))}" ] 

    source_application_security_group_ids = [ "${lookup(local.merge0,"source_application_security_group_id","")}" ]   
    destination_application_security_group_ids = [ "${lookup(local.merge0,"destination_application_security_group_id","")}" ]   

    network_security_group_name = "${lookup(local.merge0,"network_security_group_name")}"
    resource_group_name = "${lookup(local.merge0,"resource_group_name")}" 
}

#}