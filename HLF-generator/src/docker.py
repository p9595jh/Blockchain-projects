import config
from node import OrdererItem

class DockerCa:
    def __init__(self, org_addr, port, volume=None):
        super().__init__()
        self.org_addr = org_addr
        self.port = port
        self.container_name = 'ca_' + self.org_addr
        self.ca_name = 'ca-' + self.org_addr
        self.volume = volume if volume is not None else self.org_addr

    def to_dict(self):
        return {
            'image': 'hyperledger/fabric-ca',
            'environment': [
                'FABRIC_CA_HOME=/etc/hyperledger/fabric-ca-server',
                'FABRIC_CA_SERVER_CA_NAME=' + self.ca_name,
                'FABRIC_CA_SERVER_TLS_ENABLED=true',
                'FABRIC_CA_SERVER_PORT=' + str(self.port)
            ],
            'ports': ['{0}:{0}'.format(self.port)],
            'command': "sh -c 'fabric-ca-server start -b admin:adminpw -d'",
            'volumes': ['../organizations/fabric-ca/{}:/etc/hyperledger/fabric-ca-server'.format(self.volume)],
            'container_name': self.container_name,
            'networks': ['test']
        }

class DockerCouch:
    def __init__(self, name, peer, port_start=5984):
        super().__init__()
        self.port = peer.dbport
        self.name = name
        self.peer = peer
        self.org_addr = peer.org.addr
        self.admin = peer.org.admin
        self.adminpw = peer.org.adminpw
        self.port_start = port_start
        self.addr = '%s.%s.%s.com' % (peer.name, self.org_addr, config.srvn)

    def to_dict(self):
        return {
            self.name: {
                'container_name': self.name,
                'image': 'couchdb:3.1',
                'environment': [
                    'COUCHDB_USER=' + self.admin,
                    'COUCHDB_PASSWORD=' + self.adminpw
                ],
                'ports': ['%d:%d' % (self.port, self.port_start)],
                'networks': ['test']
            },
            self.addr: {
                'environment': [
                    'CORE_LEDGER_STATE_STATEDATABASE=CouchDB',
                    'CORE_LEDGER_STATE_COUCHDBCONFIG_COUCHDBADDRESS=%s:%d' % (self.name, self.port_start),
                    'CORE_LEDGER_STATE_COUCHDBCONFIG_USERNAME=' + self.admin,
                    'CORE_LEDGER_STATE_COUCHDBCONFIG_PASSWORD=' + self.adminpw
                ],
                'depends_on': [self.name]
            }
        }

class DockerNetOrderer:
    def __init__(self, item: OrdererItem):
        self.item = item
        self.addr = '%s.%s.com' % (self.item.addr, config.srvn)
    
    def to_dict(self):
        return {
            self.addr: {
                'container_name': '%s.%s.com' % (self.item.addr, config.srvn),
                'image': 'hyperledger/fabric-orderer' + config.IMAGE_TAG,
                'environment': [
                    'FABRIC_LOGGING_SPEC=INFO',
                    'ORDERER_GENERAL_LISTENADDRESS=0.0.0.0',
                    'ORDERER_GENERAL_LISTENPORT={}'.format(self.item.port),
                    'ORDERER_GENERAL_GENESISMETHOD=file',
                    'ORDERER_GENERAL_GENESISFILE=/var/hyperledger/orderer/{}.genesis.block'.format(self.item.addr),
                    'ORDERER_GENERAL_LOCALMSPID=' + self.item.orderer.msp,
                    'ORDERER_GENERAL_LOCALMSPDIR=/var/hyperledger/orderer/msp',
                    'ORDERER_GENERAL_TLS_ENABLED=true',
                    'ORDERER_GENERAL_TLS_PRIVATEKEY=/var/hyperledger/orderer/tls/server.key',
                    'ORDERER_GENERAL_TLS_CERTIFICATE=/var/hyperledger/orderer/tls/server.crt',
                    'ORDERER_GENERAL_TLS_ROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]',
                    'ORDERER_KAFKA_TOPIC_REPLICATIONFACTOR=1',
                    'ORDERER_KAFKA_VERBOSE=true',
                    'ORDERER_GENERAL_CLUSTER_CLIENTCERTIFICATE=/var/hyperledger/orderer/tls/server.crt',
                    'ORDERER_GENERAL_CLUSTER_CLIENTPRIVATEKEY=/var/hyperledger/orderer/tls/server.key',
                    'ORDERER_GENERAL_CLUSTER_ROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]'
                ],
                'working_dir': '/opt/gopath/src/github.com/hyperledger/fabric',
                'command': 'orderer',
                'volumes': [
                    '../system-genesis-block/genesis.block:/var/hyperledger/orderer/{}.genesis.block'.format(self.item.addr),
                    '../organizations/ordererOrganizations/%s.com/orderers/%s/msp:/var/hyperledger/orderer/msp' % (config.srvn, self.addr),
                    '../organizations/ordererOrganizations/%s.com/orderers/%s/tls/:/var/hyperledger/orderer/tls' % (config.srvn, self.addr),
                    '{}:/var/hyperledger/production/orderer'.format(self.addr)
                ],
                'ports': ['{0}:{0}'.format(self.item.port)],
                'networks': ['test']
            }
        }

class DockerNetPeer:
    def __init__(self, peer, orderer):
        self.peer = peer
        self.addr = '%s.%s.%s.com' % (self.peer.name, self.peer.org.addr, config.srvn)
        self.addr_no_peer = '%s.%s.com' % (self.peer.org.addr, config.srvn)
        self.cc_port = self.peer.port + 1
        self.depends_on = ['%s.%s.com' % (item.addr, config.srvn) for item in orderer.items]
    
    def to_dict(self):
        return {
            self.addr: {
                'container_name': self.addr,
                'image': 'hyperledger/fabric-peer' + config.IMAGE_TAG,
                'environment': [
                    'CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock',
                    'CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=docker_test',
                    'FABRIC_LOGGING_SPEC=INFO',
                    'CORE_PEER_TLS_ENABLED=true',
                    'CORE_PEER_PROFILE_ENABLED=true',
                    'CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/fabric/tls/server.crt',
                    'CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/fabric/tls/server.key',
                    'CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt',
                    'CORE_PEER_ID=%s' % self.addr,
                    'CORE_PEER_ADDRESS=%s:%d' % (self.addr, self.peer.port),
                    'CORE_PEER_LISTENADDRESS=0.0.0.0:%d' % self.peer.port,
                    'CORE_PEER_CHAINCODEADDRESS=%s:%d' % (self.addr, self.cc_port),
                    'CORE_PEER_CHAINCODELISTENADDRESS=0.0.0.0:%d' % self.cc_port,
                    'CORE_PEER_GOSSIP_BOOTSTRAP=%s:%d' % (self.addr, self.peer.port),
                    'CORE_PEER_GOSSIP_EXTERNALENDPOINT=%s:%d' % (self.addr, self.peer.port),
                    'CORE_PEER_LOCALMSPID=' + self.peer.org.msp
                ],
                'volumes': [
                    '/var/run/:/host/var/run/',
                    '../organizations/peerOrganizations/%s/peers/%s/msp:/etc/hyperledger/fabric/msp' % (self.addr_no_peer, self.addr),
                    '../organizations/peerOrganizations/%s/peers/%s/tls:/etc/hyperledger/fabric/tls' % (self.addr_no_peer, self.addr),
                    '%s:/var/hyperledger/production' % self.addr
                ],
                'working_dir': '/opt/gopath/src/github.com/hyperledger/fabric/peer',
                'command': 'peer node start',
                'depends_on': self.depends_on,
                'ports': ['{0}:{0}'.format(self.peer.port)],
                'networks': ['test']
            }
        }

