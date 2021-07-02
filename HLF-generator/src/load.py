import os
import config
import util
import json
import yaml
import shutil
import node
import docker
from configtx import configtx
from datetime import datetime
from copy import deepcopy
from configtx import configtx
from create_channel import create_channel
from deploy import deploy

if __name__ == '__main__':

    print('\n<history>')
    histories = os.listdir('../history')
    histories.sort()
    for i in range(0, len(histories), 2):
        print(histories[i][:histories[i].rfind('.')])
    print()

    s = util.sinput('History to load', default=histories[-1][:histories[-1].rfind('.')])
    path = '../history/%s.json' % s
    if not os.path.exists(path):
        print('There is no file `%s`' % s)
        exit(1)
    with open(path, 'r') as f:
        jsn = json.load(f)

    #########################################################################################################
    #########################################################################################################
    #########################################################################################################
    #########################################################################################################
    #########################################################################################################
    #########################################################################################################
    #########################################################################################################
    #########################################################################################################
    #########################################################################################################
    #########################################################################################################

    if not os.path.exists('../exports'):
        os.mkdir('../exports')

    config.project_name = jsn['project_name']
    path = '../exports/{}/'.format(config.project_name)
    config.path = path

    if os.path.exists(path):
        answer = util.sinput('`%s` already exists; Would you like to remove and continue? (y/N)' % config.project_name, '[yYnN]{1}', default='y').upper()
        if answer == 'N':
            config.project_name = util.sinput('rename', default='Example')
            path = '../exports/{}/'.format(config.project_name)
            while True:
                if os.path.exists(path):
                    print('`{}` already exists; Input again please')
                    config.project_name = util.sinput('rename', default='Example')
                    path = '../exports/{}/'.format(config.project_name)
                else:
                    break
        else:
            shutil.rmtree(path)

    os.mkdir(path)
    os.mkdir(path + 'network')
    os.mkdir(path + 'network/cc')
    os.mkdir(path + 'network/configtx')
    os.mkdir(path + 'network/docker')
    os.mkdir(path + 'network/organizations')
    os.mkdir(path + 'network/organizations/fabric-ca')
    os.mkdir(path + 'network/organizations/fabric-ca/ordererOrg')
    os.mkdir(path + 'network/scripts')
    os.mkdir(path + 'network/system-genesis-block')
    os.mkdir(path + 'chaincode')
    os.mkdir(path + 'chaincode/codes')
    os.mkdir(path + 'chaincode/packages')
    os.mkdir(path + 'invoke')
    os.mkdir(path + 'invoke/src')
    os.mkdir(path + 'invoke/public')

    config.project_creator = jsn['project_creator']
    config.srvn = jsn['srvn']
    config.network_profile = jsn['network_profile']

    # chaincode setting
    config.chaincode_title = jsn['chaincode_name']
    chaincode_title_folder = jsn['chaincode_folder']
    
    os.mkdir(path + 'chaincode/codes/%s/' % chaincode_title_folder)
    os.mkdir(path + 'chaincode/codes/%s/src' % chaincode_title_folder)

    util.copy_file('chaincode/codes/template_cc/tsconfig.json', 'chaincode/codes/%s/tsconfig.json' % chaincode_title_folder)
    util.copy_file('chaincode/codes/template_cc/tslint.json', 'chaincode/codes/%s/tslint.json' % chaincode_title_folder)
    util.copy_file('chaincode/codes/template_cc/src/utils.ts', 'chaincode/codes/%s/src/utils.sh' % chaincode_title_folder)

    util.copy_replace('chaincode/codes/template_cc/package.json', 'chaincode/codes/%s/package.json' % chaincode_title_folder, {
        'TEMPLATE_CC': (chaincode_title_folder, 1),
    })
    util.copy_replace('chaincode/codes/template_cc/src/index.ts', 'chaincode/codes/%s/src/index.ts' % chaincode_title_folder, {
        'TEMPLATE_CC': (config.chaincode_title,),
        'CC_FILENAME': (chaincode_title_folder,)
    })
    util.copy_replace('chaincode/codes/template_cc/src/TEMPLATE_CC.ts', 'chaincode/codes/%s/src/%s.ts' % (chaincode_title_folder, chaincode_title_folder), {
        'TEMPLATE_CC': (config.chaincode_title, 1)
    })

    config.channel_identities = jsn['channel_identities']
    for key in config.channel_identities.keys():
        config.channel_identities[key] = tuple(config.channel_identities[key])

    for organ in jsn['organs']:
        peers = []
        for peer in organ['peers']:
            peers.append(node.Peer(peer['name'], peer['port'], peer['dbport'], [node.FabChannel(channel['channel'], channel['profile'], channel['consortium']) for channel in peer['channels']]))
        util.organs.append(node.Organ(organ['addr'], organ['name'], organ['msp'], organ['caport'], organ['admin'], organ['adminpw'], peers))

    util.orderer = node.Orderer(jsn['orderer']['msp'], jsn['orderer']['caport'], [node.OrdererItem(item['addr'], item['name'], item['port']) for item in jsn['orderer']['items']])

    configtx_str = configtx()
    with open(path + 'network/configtx/configtx.yaml', 'w+') as f:
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
        fabric_ca_server_config['affiliations'] = {org.addr: ['department1', 'department2'] if i is 1 else ['department1'] for i, org in enumerate(util.organs)}

    couchdb_peer_count = 0
    gen_organs_commands = ''
    gen_ccp_commands = ''
    docker_rm_commands = "    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf system-genesis-block/*.block organizations/peerOrganizations organizations/ordererOrganizations'\n"
    gitignore_organs_1 = 'organizations/fabric-ca/ordererOrg/*\n'
    gitignore_organs_2 = '!organizations/fabric-ca/ordererOrg/fabric-ca-server-config.yaml\n'
    all_nodes = ''

    d = {
        'srvn': config.srvn,
        # 'consortium': config.consortium_name,
        'network_profile': config.network_profile,
        'channel_identities': config.channel_identities,
        'chaincode_name': config.chaincode_title,
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
        gen_organs_commands_peers = ''

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
        fabric_ca_server_path = path + 'network/organizations/fabric-ca/{}/'.format(org.addr)
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

            gen_organs_commands_peers += peer.name + ' '
            gen_ccp_commands += '  ./organizations/ccp-generate.sh ${SERV_NM} %s %s %d %d %s\n' % (org.addr, org.name, peer.port, org.caport, peer.name)

            peer_dict = deepcopy(peer.__dict__)
            peer_dict['channels'] = []
            del peer_dict['org']

            for j, peer_channel in enumerate(peer.channels):
                all_nodes += '%s=(%s %s %s Admin %d %s)\n' % (util.naming_var(org.addr, i, j), org.addr, org.name, peer.name, peer.port, peer_channel.channel)
                peer_dict['channels'].append(deepcopy(peer_channel.__dict__))

            org_dict['peers'].append(peer_dict)

        d['organs'].append(org_dict)

        gen_organs_commands += '  registerPeer ${regiParams[@]} %s\n' % gen_organs_commands_peers[:-1]
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
    with open(path + 'network/organizations/fabric-ca/ordererOrg/fabric-ca-server-config.yaml', 'w+') as f:
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
    with open(path + 'network/docker/docker-compose-ca.yaml', 'w+') as f:
        f.write(yaml.dump(docker_compose_ca))    
    with open(path + 'network/docker/docker-compose-couch.yaml', 'w+') as f:
        f.write(yaml.dump(docker_compose_couch))
    with open(path + 'network/docker/docker-compose-net.yaml', 'w+') as f:
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
    
    # envVar
    util.copy_replace('network/scripts/envVar.sh', None, {
        'ORDERER_FIRST_NM': (util.orderer.items[0].addr, 1),
        'ORDERER_MSP': (util.orderer.msp, 1)
    })

    # invoke files generate
    util.copy_replace('invoke/package.json', None, {
        'CC_INVOKE': (config.chaincode_title, 1)
    })
    with open(path + 'invoke/data.json', 'w+') as f:
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
            'network/cc/ccfs.sh',
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

    os.system('chmod -R 777 ' + path)

    # save commands history
    commands = deepcopy(d)
    commands['chaincode_folder'] = chaincode_title_folder
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

    history_path = '../history/'
    now = datetime.now().strftime('H_%Y-%m-%d_%H:%M:%S.%f')
    if not os.path.exists(history_path): os.mkdir(history_path)
    with open(history_path + '%s.json' % now, 'w+') as f:
        f.write(json.dumps(commands, indent=4))
    with open(history_path + '%s.yaml' % now, 'w+') as f:
        f.write(yaml.dump(commands))

    print('Working done - check the folder `{}`'.format(path))
    print()

