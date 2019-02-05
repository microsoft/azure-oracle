redirect('/tmp/wlst.log',toStdOut='false')

#starting adminserver
startServer('AdminServer','jdee1','t3://localhost:7001','weblogic','wlspwd','wlshome/user_projects/domains/jdee1','false', 60000, jvmArgs='-XX:MaxPermSize=125m, -Xmx512m, -XX:+UseParallelGC')

os.system("sleep 20")

print 'Starting createMachine script ....'
#connect to the adminserver this time, using the username, password
#and hostname set you in the create domain script
connect('weblogic', 'wlspwd', 't3://localhost:7001')

#start up an edit session
edit()
startEdit()
#change to the root
cd('/')

#create a unix machine with what ever name suits
myMachine = cmo.createUnixMachine("jdem1")

print 'Create machine result: ' + str(myMachine)

#set the nodemanager settings, again that match the settings set up in
#the create domain script
myMachine.getNodeManager().setNMType('Plain')
myMachine.getNodeManager().setListenAddress('localhost')
myMachine.getNodeManager().setListenPort(5556)

#save and activate the changes
save()
activate(block="true")

print 'Done'

os.system("sleep 20")

print 'Start the NodeManager'

startNodeManager(verbose='false', NodeManagerHome='wlshome/user_projects/domains/jdee1/nodemanager', ListenPort='5556')
exit()


