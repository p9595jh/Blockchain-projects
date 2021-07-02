import config
import util

def create_channel():
    s = '## Create channeltx\ninfoln "Generating channel create transaction"\n'

    for channel, profile_t in config.channel_identities.items():
        s += 'createChannelTx %s %s\n' % (channel, profile_t[0])

    s += '\n## Create anchorpeertx\n'
    s += 'infoln "Generating anchor peer update transactions"\n'
    for org in util.organs:
        for peer in org.peers:
            if len(peer.channels) == 1:
                s += 'createAnchorPeerTx %s %s %s\n' % (org.msp, peer.channels[0].channel, peer.channels[0].profile)
            else:
                for channel in peer.channels:
                    s += 'createAnchorPeerTx %s %s %s %s\n' % (org.msp, channel.channel, channel.profile, channel.profile)
    
    s += '\n## Create channel\n'
    for channel, profile_t in config.channel_identities.items():
        s += 'infoln "Creating channel %s"\n' % channel
        s += 'createChannel ${%s[@]}\n\n' % profile_t[2][0]

    s += '## Join all the peers to the channel\n'
    for channel, profile_t in config.channel_identities.items():
        s += 'infoln "Join peers to the {}..."\n'.format(channel)
        for rn in profile_t[2]:
            s += 'joinChannel ${%s[@]}\n' % rn
        s += '\n'

    s += '## Set the anchor peers for each org in the channel\n'
    for org in util.organs:
        s += 'infoln "Updating anchor peers for %s..."\n' % org.addr
        for i, peer in enumerate(org.peers):
            if len(peer.channels) == 1:
                s += 'updateAnchorPeers ${%s[@]}\n' % util.naming_var(org.addr, i, 0)
            else:
                for j, channel in enumerate(peer.channels):
                    s += 'updateAnchorPeers ${%s[@]} %s\n' % (util.naming_var(org.addr, i, j), channel.profile)
            s += '\n'

    return s
