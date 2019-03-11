
####################################
##  NSG Rule 
##   
####################################

resource "azurerm_network_security_rule" "NSGSecurityRule" {
    count = "${length(var.rule_overrides)}"
    name =  "${join("-",list(var.basename_prefix,lower(lookup(merge(var.base_rule_value,var.rule_overrides[count.index]),"direction")),format("%.2d",count.index+1)))}"
    #name = "${join("_",list(chomp(var.basename_prefix),"a","b"))}"
    #name = "${var.basename_prefix}"
    priority = "${lookup(merge(var.base_rule_value,var.rule_overrides[count.index]),"priority") + count.index}"
    direction = "${lookup(merge(var.base_rule_value,var.rule_overrides[count.index]),"direction")}"    
    access = "${lookup(merge(var.base_rule_value,var.rule_overrides[count.index]),"access")}" 
    protocol = "${lookup(merge(var.base_rule_value,var.rule_overrides[count.index]),"protocol")}"    

    source_port_range = "*"
#    source_port_ranges = [ 
#        "${split(",",lookup(merge(var.base_rule_value,var.rule_overrides[count.index]),"source_port_ranges"))}" 
#    ]

    destination_port_ranges = [ 
        "${split(",",lookup(merge(var.base_rule_value,var.rule_overrides[count.index]),"destination_port_ranges"))}"         
    ]    
   # source_address_prefixes = [ 
   #     "${split(",",lookup(merge(var.base_rule_value,var.rule_overrides[count.index]),"source_address_prefixes"))}"
   # ]   
    source_address_prefix = "${lookup(merge(var.base_rule_value,var.rule_overrides[count.index]),"source_address_prefix")}"

   # destination_address_prefixes = [ 
   #     "${split(",",lookup(merge(var.base_rule_value,var.rule_overrides[count.index]),"destination_address_prefixes"))}"
   # ]
    destination_address_prefix = "${lookup(merge(var.base_rule_value,var.rule_overrides[count.index]),"destination_address_prefix")}"

    network_security_group_name = "${lookup(merge(var.base_rule_value,var.rule_overrides[count.index]),"network_security_group_name")}"
    resource_group_name = "${lookup(merge(var.base_rule_value,var.rule_overrides[count.index]),"resource_group_name")}"
    
    /*

    depends_on = [ "null_resource.NSGFinalRules"]
 # TODO -- needs to be literal
 #   depends_on = "${null_resource.NSGFinalRules.*.blended.depends_on[count.index]}" 
 */
}