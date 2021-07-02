import yaml
import config
import util
from node import Orderer, Organ, Peer, OrdererItem, FabChannel


def configtx():
    with open('../templates/network/configtx/configtx.yaml.txt', 'r') as f:
        s = f.read()

    tab = '    '
    ordererEndpoints = ''
    consenters = ''
    addresses = ''

    for item in util.orderer.items:
        ordererEndpoints += (tab * 3 + '- %s.%s.com:%d\n' % (item.addr, config.srvn, item.port))

        consenters += tab * 2 + '- Host: %s.%s.com\n' % (item.addr, config.srvn)
        consenters += tab * 2 + '  Port: {}\n'.format(item.port)
        consenters += tab * 2 + '  ClientTLSCert: ../organizations/ordererOrganizations/%s.com/orderers/%s.%s.com/tls/server.crt\n' % (config.srvn, item.addr, config.srvn)
        consenters += tab * 2 + '  ServerTLSCert: ../organizations/ordererOrganizations/%s.com/orderers/%s.%s.com/tls/server.crt\n' % (config.srvn, item.addr, config.srvn)

        addresses += tab * 2 + '- %s.%s.com:%d\n' % (item.addr, config.srvn, item.port)

    ordererOrg = '''
    - &OrdererOrg
        Name: OrdererOrg
        ID: %s
        MSPDir: ../organizations/ordererOrganizations/%s.com/msp
        Policies:
            Readers:
                Type: Signature
                Rule: "OR('%s.member')"
            Writers:
                Type: Signature
                Rule: "OR('%s.member')"
            Admins:
                Type: Signature
                Rule: "OR('%s.admin')"
        OrdererEndpoints:
%s''' % (util.orderer.msp, config.srvn, util.orderer.msp, util.orderer.msp, util.orderer.msp, ordererEndpoints)

    peerOrg = ''
    org_names_in_profile = ''
    channel_dict = {}
    for org in util.organs:
        org_names_in_profile += '\n%s- *%s' % (tab * 5, org.name)
        for peer in org.peers:
            each = '''
    - &%s
        Name: %s
        ID: %s
        MSPDir: ../organizations/peerOrganizations/%s.%s.com/msp
        Policies:
            Readers:
                Type: Signature
                Rule: "OR('%s.admin', '%s.peer', '%s.client')"
            Writers:
                Type: Signature
                Rule: "OR('%s.admin', '%s.client')"
            Admins:
                Type: Signature
                Rule: "OR('%s.admin')"
            Endorsement:
                Type: Signature
                Rule: "OR('%s.peer')"
        AnchorPeers:
            - Host: %s.%s.%s.com
              Port: %s\n''' % (org.name, org.msp, org.msp, org.addr, config.srvn, org.msp, org.msp, org.msp, org.msp, org.msp, org.msp, org.msp, peer.name, org.addr, config.srvn, peer.port)
            peerOrg += each

            for channel in peer.channels:
                if channel.channel in channel_dict:
                    organizations = channel_dict[channel.channel][1]
                    organizations += '\n%s- *%s' % ((tab * 4), peer.org.name)
                    channel_dict[channel.channel][1] = organizations
                else:
                    text = '''
    %s:
        Consortium: %s
        <<: *ChannelDefaults
        Application:
            <<: *ApplicationDefaults
            Organizations:\n''' % (channel.profile, channel.consortium)
                    organizations = tab * 4 + '- *%s' % peer.org.name
                    channel_dict[channel.channel] = [text, organizations]

    all_profiles = ''
    profile_add = '''
            Capabilities:
                <<: *ApplicationCapabilities\n\n'''
    for k, v in channel_dict.items():
        all_profiles += v[0]
        all_profiles += v[1]
        all_profiles += profile_add

    s = s.replace('{{ORDERER_ORG_CONFIGTX}}', ordererOrg[1:], 1).replace('{{PEER_ORG_CONFIGTX}}', peerOrg, 1).replace('{{CONSORTIUM_PEERS_CONFIGTX}}', org_names_in_profile, 1).replace('{{CHANNEL_PROFILE_CONFIGTX}}', all_profiles, 1)
    s = s.replace('{{CONSENTERS_CONFIGTX}}', consenters, 1).replace('{{ORDERER_ADDRESSES_CONFIGTX}}', addresses, 1).replace('{{CONSORTIUM_NAME_CONFIGTX}}', config.consortium_name).replace('{{NETWORK_PROFILE_CONFIGTX}}', config.network_profile)

    return s

