project_name = 'Example'
project_creator = 'John Doe'
srvn = 'example'
consortium_name = 'Consortium'
network_profile = 'TestNetworkProfile'
line_sep = '======================================'
path: str = None

def line_print():
    print(line_sep, end='\n\n')

channel_names = ['mychannel']
channel_profiles = ['TestChannelProfile']

# { channel_name: (channel_profile, consortium, [represented names in shell script (ex. _org2_1_0)]) }
# the tuple (which is the value of this dictionary) is called as 'profile_t'
# 'represented names' field is called as 'rns', and each of these is 'rn'
channel_identities = {}

template_path = '../templates/'

step_default = 1000

orderer_default_port = 7050
orderer_default_port_step = step_default

peer_default_port = 7051
peer_default_port_step = step_default

peer_default_dbport = 5984
peer_default_dbport_step = step_default

caport_default = 7054
caport_default_step = step_default

couch_default = 5984
couch_default_step = step_default

chaincode_title = 'TestCC'
chaincode_title_folder = 'testcc'

# [(title, folder)]
chaincode_titles = []
