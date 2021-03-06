import yaml
import util
import node
import config
import docker
import os
import shutil
import json
from datetime import datetime
from copy import deepcopy
from configtx import configtx
from create_channel import create_channel
from deploy import deploy


def camel_to_pothole(camel: str):
    s = camel[0].lower()
    for i in range(1, len(camel)):
        # when the capital is found, turn this to -{lower}
        # ex. input: HelloWorld, output: hello-world
        if 65 <= ord(camel[i]) <= 90:
            s += '-' + camel[i].lower()
        # change underscore(_) to hypen(-)
        elif camel[i] == '_':
            s += '-'
        # if there is no problem, copy the character
        else:
            s += camel[i]
    return s

def cc_title_tuple(s, default):
    if s == '.': s = default
    return (s, camel_to_pothole(s))

def pre_process():

    # make folders
    if not os.path.exists('../exports'):
        os.mkdir('../exports')

    os.mkdir(config.path)
    os.mkdir(config.path + 'network')
    os.mkdir(config.path + 'network/cc')
    os.mkdir(config.path + 'network/configtx')
    os.mkdir(config.path + 'network/docker')
    os.mkdir(config.path + 'network/organizations')
    os.mkdir(config.path + 'network/organizations/fabric-ca')
    os.mkdir(config.path + 'network/organizations/fabric-ca/ordererOrg')
    os.mkdir(config.path + 'network/scripts')
    os.mkdir(config.path + 'network/system-genesis-block')
    os.mkdir(config.path + 'chaincode')
    os.mkdir(config.path + 'chaincode/codes')
    os.mkdir(config.path + 'chaincode/packages')
    os.mkdir(config.path + 'invoke')
    os.mkdir(config.path + 'invoke/src')
    os.mkdir(config.path + 'invoke/public')

    for chaincode_title, chaincode_title_folder in config.chaincode_titles:
        try:
            os.mkdir(config.path + 'chaincode/codes/%s/' % chaincode_title_folder)
            os.mkdir(config.path + 'chaincode/codes/%s/src' % chaincode_title_folder)
        except FileExistsError as e:
            continue

        util.copy_file('chaincode/codes/template_cc/tsconfig.json', 'chaincode/codes/%s/tsconfig.json' % chaincode_title_folder)
        util.copy_file('chaincode/codes/template_cc/tslint.json', 'chaincode/codes/%s/tslint.json' % chaincode_title_folder)
        util.copy_file('chaincode/codes/template_cc/src/utils.ts', 'chaincode/codes/%s/src/utils.ts' % chaincode_title_folder)

        util.copy_replace('chaincode/codes/template_cc/package.json', 'chaincode/codes/%s/package.json' % chaincode_title_folder, {
            'TEMPLATE_CC': (chaincode_title_folder, 1),
        })
        util.copy_replace('chaincode/codes/template_cc/src/index.ts', 'chaincode/codes/%s/src/index.ts' % chaincode_title_folder, {
            'TEMPLATE_CC': (chaincode_title,),
            'CC_FILENAME': (chaincode_title_folder,)
        })
        util.copy_replace('chaincode/codes/template_cc/src/TEMPLATE_CC.ts', 'chaincode/codes/%s/src/%s.ts' % (chaincode_title_folder, chaincode_title_folder), {
            'TEMPLATE_CC': (chaincode_title, 1)
        })


def run_process(log=True):
    print('Creating files...')

    # generate configtx.yaml
    configtx_str = configtx()
    with open(config.path + 'network/configtx/configtx.yaml', 'w+') as f:
        f.write(configtx_str)
    
    # generate core.yaml
    util.copy_replace('network/configtx/core.yaml', None, {
        'CORE_ID': (config.project_creator, 1)
    })

    # generate docker files
    with open(config.template_path + 'network/docker/docker-compose-ca.yaml', 'r') as f:
        docker_compose_ca = yaml.load(f, Loader=yaml.FullLoader)
        docker_compose_ca['services'] = {}

        orderer_ca = docker.DockerCa('orderer', util.orderer.caport, 'ordererOrg')
        docker_compose_ca['services'][orderer_ca.container_name] = orderer_ca.to_dict()

    with open(config.template_path + 'network/docker/docker-compose-couch.yaml', 'r') as f:
        docker_compose_couch = yaml.load(f, Loader=yaml.FullLoader)
        docker_compose_couch['services'] = {}

    with open(config.template_path + 'network/docker/docker-compose-net.yaml', 'r') as f:
        docker_compose_net = yaml.load(f, Loader=yaml.FullLoader)
        docker_compose_net['services'] = {}
        docker_compose_net['volumes'] = {}
    
    with open(config.template_path + 'network/organizations/fabric-ca/fabric-ca-server-config.yaml', 'r') as f:
        fabric_ca_server_config = yaml.load(f, Loader=yaml.FullLoader)
        fabric_ca_server_config['affiliations'] = {org.addr: ['department1', 'department2'] if i == 1 else ['department1'] for i, org in enumerate(util.organs)}

    couchdb_peer_count = 0
    gen_organs_commands = ''
    gen_ccp_commands = ''
    docker_rm_commands = "    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf system-genesis-block/*.block organizations/peerOrganizations organizations/ordererOrganizations'\n"
    gitignore_organs_1 = 'organizations/fabric-ca/ordererOrg/*\n'
    gitignore_organs_2 = '!organizations/fabric-ca/ordererOrg/fabric-ca-server-config.yaml\n'
    all_nodes = ''

    d = {
        'srvn': config.srvn,
        'network_profile': config.network_profile,
        'channel_identities': config.channel_identities,
        'chaincode_names': [{
            'title': title,
            'folder': folder
        } for title, folder in config.chaincode_titles],
        'orderer': deepcopy(util.orderer.__dict__),
        'organs': []
    }

    d['orderer']['items'] = []

    # most important loop!!!
    for org in util.organs:
        print('Set configuration for `{}`...'.format(org.addr))

        ca = docker.DockerCa(org.addr, org.caport)
        docker_compose_ca['services'][ca.container_name] = ca.to_dict()

        gen_organs_commands += '  infoln "Create {} Identites"\n\n'.format(org.name)
        gen_organs_commands += '  orgEnv %s %d\n' % (org.addr, org.caport)
        gen_organs_commands += '  createOrg $SERV_NM $ORG_ADDR $CAPORT\n'

        docker_rm_commands += "    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/{0}/msp organizations/fabric-ca/{0}/tls-cert.pem organizations/fabric-ca/{0}/ca-cert.pem organizations/fabric-ca/{0}/IssuerPublicKey organizations/fabric-ca/{0}/IssuerRevocationPublicKey organizations/fabric-ca/{0}/fabric-ca-server.db'\n".format(org.addr)

        gitignore_organs_1 += 'organizations/fabric-ca/{}/*\n'.format(org.addr)
        gitignore_organs_2 += '!organizations/fabric-ca/{}/fabric-ca-server-config.yaml\n'.format(org.addr)

        org_dict = deepcopy(org.__dict__)
        org_dict['peers'] = []

        fabric_ca_server_config['port'] = org.caport
        fabric_ca_server_config['ca']['name'] = 'ca-' + org.addr
        fabric_ca_server_config['registry']['identities'][0]['name'] = org.admin
        fabric_ca_server_config['registry']['identities'][0]['pass'] = org.adminpw
        fabric_ca_server_config['csr']['cn'] = 'ca.%s.%s.com' % (org.addr, config.srvn)
        fabric_ca_server_config['csr']['names'][0]['O'] = '%s.%s.com' % (org.addr, config.srvn)
        fabric_ca_server_config['csr']['hosts'][1] = '%s.%s.com' % (org.addr, config.srvn)
        fabric_ca_server_path = config.path + 'network/organizations/fabric-ca/{}/'.format(org.addr)
        os.mkdir(fabric_ca_server_path)
        with open(fabric_ca_server_path + 'fabric-ca-server-config.yaml', 'w+') as f:
            f.write(yaml.dump(fabric_ca_server_config))

        for i, peer in enumerate(org.peers):
            couchdb = docker.DockerCouch('couchdb{}'.format(couchdb_peer_count), peer)
            couchdb_peer_count += 1

            couchdb_dict = couchdb.to_dict()
            docker_compose_couch['services'][couchdb.name] = couchdb_dict[couchdb.name]
            docker_compose_couch['services'][couchdb.addr] = couchdb_dict[couchdb.addr]

            net = docker.DockerNetPeer(peer, util.orderer)
            docker_compose_net['volumes'][net.addr] = None
            docker_compose_net['services'][net.addr] = net.to_dict()[net.addr]

            gen_organs_commands += '  registerPeer ${regiParams[@]} %s\n' % peer.name
            gen_ccp_commands += '  ./organizations/ccp-generate.sh ${SERV_NM} %s %s %d %d %s\n' % (org.addr, org.name, peer.port, org.caport, peer.name)

            peer_dict = deepcopy(peer.__dict__)
            peer_dict['channels'] = []
            del peer_dict['org']

            for j, peer_channel in enumerate(peer.channels):
                all_nodes += '%s=(%s %s %s Admin %d %s)\n' % (util.naming_var(org.addr, i, j), org.addr, org.name, peer.name, peer.port, peer_channel.channel)
                peer_dict['channels'].append(deepcopy(peer_channel.__dict__))

            org_dict['peers'].append(peer_dict)

        d['organs'].append(org_dict)

        gen_organs_commands += '  registerUser ${regiParams[@]} user1 User1\n'
        gen_organs_commands += '  registerAdmin ${regiParams[@]} ${ORG_ADDR}admin Admin\n\n'

        docker_rm_commands += "    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/ordererOrg/msp organizations/fabric-ca/ordererOrg/tls-cert.pem organizations/fabric-ca/ordererOrg/ca-cert.pem organizations/fabric-ca/ordererOrg/IssuerPublicKey organizations/fabric-ca/ordererOrg/IssuerRevocationPublicKey organizations/fabric-ca/ordererOrg/fabric-ca-server.db'\n"

    gen_organs_commands += '  infoln "Create Orderer Org Identities"\n'
    gen_organs_commands += '  createOrdererOrg ${SERV_NM} %d' % util.orderer.caport
    gen_organs_commands_orderers = ''

    # orderer fabric-ca-server-config
    fabric_ca_server_config['port'] = util.orderer.caport
    fabric_ca_server_config['ca']['name'] = 'ca-orderer'
    fabric_ca_server_config['registry']['identities'][0]['name'] = 'admin'
    fabric_ca_server_config['registry']['identities'][0]['pass'] = 'adminpw'
    fabric_ca_server_config['csr']['cn'] = 'ca.%s.com' % config.srvn
    fabric_ca_server_config['csr']['names'][0]['O'] = '%s.com' % config.srvn
    fabric_ca_server_config['csr']['hosts'][1] = '%s.com' % config.srvn
    with open(config.path + 'network/organizations/fabric-ca/ordererOrg/fabric-ca-server-config.yaml', 'w+') as f:
        f.write(yaml.dump(fabric_ca_server_config))

    for item in util.orderer.items:
        print('Set configuration for `{}`...'.format(item.addr))
        net = docker.DockerNetOrderer(item)
        docker_compose_net['volumes'][net.addr] = None
        docker_compose_net['services'][net.addr] = net.to_dict()[net.addr]
        gen_organs_commands_orderers += ' ' + item.addr

        item_dict = deepcopy(item.__dict__)
        del item_dict['orderer']
        d['orderer']['items'].append(item_dict)
    
    print('Working for other files...')

    # loading docker files
    with open(config.path + 'network/docker/docker-compose-ca.yaml', 'w+') as f:
        f.write(yaml.dump(docker_compose_ca))    
    with open(config.path + 'network/docker/docker-compose-couch.yaml', 'w+') as f:
        f.write(yaml.dump(docker_compose_couch))
    with open(config.path + 'network/docker/docker-compose-net.yaml', 'w+') as f:
        f.write(yaml.dump(docker_compose_net))

    # network.sh
    util.copy_replace('network/network.sh', None, {
        'GEN_ORGANS_COMMANDS': (gen_organs_commands + gen_organs_commands_orderers, 1),
        'GEN_CCP_COMMANDS': (gen_ccp_commands, 1),
        'DOCKER_RM_COMMANDS': (docker_rm_commands, 1)
    })

    # .gitignore
    util.copy_replace('network/.gitignore_t', 'network/.gitignore', {
        'GITIGNORE_ORGANS_1': (gitignore_organs_1, 1),
        'GITIGNORE_ORGANS_2': (gitignore_organs_2, 1)
    })

    # utils.sh
    util.copy_replace('network/scripts/utils.sh', None, {
        'SERV_NM': (config.srvn, 1),
        'NETWORK_PROFILE': (config.network_profile, 1),
        'ALL_NODES': (all_nodes, 1)
    })
    
    # create channel
    util.copy_replace('network/scripts/createChannel.sh', None, {
        'JOIN_CHANNEL_COMMANDS': (create_channel(), 1),
        'ORDERER_FIRST_PORT': (str(util.orderer.items[0].port),)
    })

    # deploy
    util.copy_replace('network/cc/deploy.sh', None, {
        'CHAINCODE_DEPLOY_COMMANDS': (deploy(), 1)
    })

    # ccfs
    util.copy_replace('network/cc/ccfs.sh', None, {
        'CHAINCODE_CCFS_ORDERER_PORT': (str(util.orderer.items[0].port),)
    })

    # envVar
    util.copy_replace('network/scripts/envVar.sh', None, {
        'ORDERER_FIRST_NM': (util.orderer.items[0].addr, 1),
        'ORDERER_MSP': (util.orderer.msp, 1)
    })

    # invoke files generate
    util.copy_replace('invoke/package.json', None, {
        'CC_INVOKE': (config.chaincode_title, 1)
    })
    with open(config.path + 'invoke/data.json', 'w+') as f:
        d['delegate'] = deepcopy(d['organs'][0])
        d['delegate']['peer'] = deepcopy(d['delegate']['peers'][0])
        d['delegate']['peer']['channel'] = deepcopy(d['delegate']['peer']['channels'][0])
        d['delegate']['chaincode'] = config.chaincode_title
        del d['delegate']['peers']
        del d['delegate']['peer']['channels']
        f.write(json.dumps(d, indent=4))

    # copy files not needed to modify
    copy_filenames = [
        [
            'network/.env',
            # 'network/cc/ccfs.sh',
            'network/organizations/fabric-ca/registerEnroll.sh',
            'network/organizations/ccp-generate.sh',
            'network/organizations/ccp-template.json',
            'network/organizations/ccp-template.yaml',
            'invoke/.editorconfig',
            'invoke/tsconfig.json',
            'invoke/tslint.json',
            'invoke/src/enrollAdmin.ts',
            'invoke/src/invoke.ts',
            'invoke/src/registerUser.ts',
            'invoke/src/server.ts',
            'invoke/src/utils.ts'
        ], [
            ('chaincode/.gitignore_t', 'chaincode/.gitignore'),
            ('invoke/.gitignore_t', 'invoke/.gitignore')
        ]
    ]
    for filename in copy_filenames[0]:
        util.copy_file(filename)
    for filenames in copy_filenames[1]:
        util.copy_file(filenames[0], filenames[1])

    os.system('chmod -R 777 ' + config.path)

    # save commands history
    commands = deepcopy(d)
    commands['project_name'] = config.project_name
    commands['project_creator'] = config.project_creator
    commands['chaincode_folder'] = config.chaincode_title_folder
    commands['docker'] = {
        'ca': docker_compose_ca,
        'couch': docker_compose_couch,
        'net': docker_compose_net,
        'configtx': yaml.load(configtx_str, Loader=yaml.FullLoader)
    }

    cids = deepcopy(config.channel_identities)
    for key in cids.keys():
        cids[key] = list(cids[key])
    commands['channel_identities'] = cids

    if log:
        history_path = '../history/'
        now = datetime.now().strftime('H_%Y-%m-%d_%H:%M:%S.%f')
        if not os.path.exists(history_path): os.mkdir(history_path)
        with open(history_path + '%s.json' % now, 'w+') as f:
            f.write(json.dumps(commands, indent=4))
        with open(history_path + '%s.yaml' % now, 'w+') as f:
            f.write(yaml.dump(commands))


if __name__ == '__main__':

    print()
    print('********************************************')
    print('*                                          *')
    print('*       HYPERLEDGER FABRIC GENERATOR       *')
    print('*          BASED 2.2 LTS VERSION           *')
    print('*            POWERED BY p9595jh            *')
    print('*                                          *')
    print('********************************************')
    print('\n')

    config.project_name = util.sinput('Project name', default='Example')
    config.path = '../exports/{}/'.format(config.project_name)

    # while True:
    #     if os.path.exists(path):
    #         print('`{}` already exists; Input again please')
    #         config.project_name = util.sinput('Project name', default='Example')
    #     else:
    #         break

    if os.path.exists(config.path):
        answer = util.sinput('`%s` already exists; Would you like to remove and continue? (y/N)' % config.project_name, '[yYnN]{1}', default='y').upper()
        if answer == 'N':
            exit(1)
        else:
            shutil.rmtree(config.path)

    config.project_creator = util.sinput('Creator', default=config.project_creator)
    config.srvn = util.sinput('Service addr', default=config.srvn)
    config.network_profile = util.sinput('Network profile', default=config.network_profile)

    chaincode_titles = util.minput('Chaincode titles (first letter capital, if you\'d like to input default, use `.`)', pattern='[.]|([A-Z]+[a-zA-Z0-9\_]*)', default=[config.project_name])
    config.chaincode_titles = [cc_title_tuple(chaincode_title, config.project_name) for chaincode_title in chaincode_titles]

    pre_process()

    print()


    number_of_organs = util.ninput('Number of organizations', default=1)
    created_peer_count = 0
    created_ca_count = 0
    created_couch_count = 0

    for i in range(number_of_organs):
        print()
        config.line_print()
        print('[Organization %d/%d]' % (i + 1, number_of_organs))
        # addr, name, msp, admin='admin', adminpw='adminpw', peers=[]
        addr = util.sinput('addr', default='org{}'.format(i + 1), pattern='[a-z]+[a-zA-Z0-9]+')
        name = util.sinput('name', default=addr[0].upper() + addr[1:])
        msp = util.sinput('MSP', default=name + 'MSP')
        caport = util.ninput('CA port', default=config.caport_default + config.caport_default_step * created_ca_count)
        created_ca_count += 1
        admin = util.sinput('admin', default='admin')
        adminpw = util.sinput('admin password', default='adminpw')

        number_of_peers = util.ninput('Number of peers of {}'.format(name), default=1)
        peers = []
        # name, port, channels
        for j in range(number_of_peers):
            print()
            print('[Peer %d/%d of %s]' % (j + 1, number_of_peers, name))
            peer_name = util.sinput('peer name', default='peer{}'.format(j))
            peer_port = util.ninput('peer port', default=config.peer_default_port + config.peer_default_port_step * created_peer_count)
            created_peer_count += 1
            peer_dbport = util.ninput('peer DB port', default=config.couch_default + config.couch_default_step * created_couch_count)
            created_couch_count += 1
            peer_channel_names = util.minput('input all channels of the peer seperates with space (ex. `channel1 channel2`)', default=['mychannel'])
            channels = []
            for k, channel_name in enumerate(peer_channel_names):
                print('\n[Channel %s (%d/%d) of %s.%s.%s.com]' % (channel_name, k + 1, len(peer_channel_names), peer_name, addr, config.srvn))
                if channel_name in config.channel_identities:
                    config.channel_identities[channel_name][2].append(util.naming_var(addr, j, k))
                    profile, consortium, rns = config.channel_identities[channel_name]
                    print('you have selected existing channel - use its setting (%s, %s, %s)' % (channel_name, profile, consortium))
                    channels.append(node.FabChannel(channel_name, profile, consortium))
                else:
                    channel_default = 'MyChannelProfile'
                    channel_default_str = channel_default
                    l = 2
                    while True:
                        profile_duplicates = False
                        for _, v in config.channel_identities.items():
                            if v[0] == channel_default_str:
                                profile_duplicates = True
                                channel_default_str += str(l)
                                l += 1
                                break
                        if not profile_duplicates: break

                    profile = util.sinput('channel profile of {}'.format(channel_name), default=channel_default_str)
                    while True:
                        profile_duplicates = False
                        for _, v in config.channel_identities.items():
                            if v[0] == profile:
                                print('channel profile `{}` already exists; please input again'.format(profile))
                                profile = util.sinput('channel profile of {}'.format(channel_name), default=channel_default_str)
                                profile_duplicates = True
                        if not profile_duplicates: break

                    consortium = util.sinput('consortium of {}'.format(channel_name), default=config.consortium_name)
                    channels.append(node.FabChannel(channel_name, profile, consortium))
                    config.channel_identities[channel_name] = (profile, consortium, [util.naming_var(addr, j, k)])
            peers.append(node.Peer(peer_name, peer_port, peer_dbport, channels))
        
        util.organs.append(node.Organ(addr, name, msp, caport, admin, adminpw, peers))


    print()


    config.line_print()
    print('[Orderer]')
    orderer_msp = util.sinput('orderer MSP', default='OrdererMSP')
    orderer_caport = util.ninput('orderer CA port', default=config.caport_default + config.caport_default_step * created_ca_count)
    orderer_addrs = util.minput('input all items of the orderer seperates with space (ex. `orderer1 orderer2`)', default=['orderer'])
    orderer_items = []

    for i, orderer_item_addr in enumerate(orderer_addrs):
        print()
        orderer_item_name = util.sinput('name of ' + orderer_item_addr, default=orderer_item_addr[0].upper() + orderer_item_addr[1:])
        orderer_item_port = util.ninput('port of ' + orderer_item_addr, config.orderer_default_port + i * config.orderer_default_port_step)
        orderer_items.append(node.OrdererItem(orderer_item_addr, orderer_item_name, orderer_item_port))
    util.orderer = node.Orderer(orderer_msp, orderer_caport, orderer_items)

    config.line_print()

    run_process()

    print()
    print('Working done - check the folder `{}`'.format(config.path))
    print()
