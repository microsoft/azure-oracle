#!/usr/bin/python
import os, sys
readTemplate('wlshome/wlserver/common/templates/wls/wls.jar')
cd('/Security/base_domain/User/weblogic')
cmo.setPassword('wlspwd')
cd('/Server/AdminServer')
cmo.setName('AdminServer')
cmo.setListenPort(7001)
cmo.setListenAddress('')
setOption('ServerStartMode', 'prod')
writeDomain('wlshome/user_projects/domains/jdee1')
closeTemplate()
exit()

