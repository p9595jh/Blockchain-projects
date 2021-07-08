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

    for channel, profile_t in config.channel_identities.items():
        s += 'infoln "Updating anchor peers for %s..."\n' % channel
        s += 'updateAnchorPeers ${%s[@]}' % profile_t[2][0]
        exists_multi = False
        for ch, pt in config.channel_identities.items():
            if channel == ch: continue
            p: str = profile_t[2][0]
            if p[:p.rfind('_')] in [ps[:ps.rfind('_')] for ps in pt[2]]:
                exists_multi = True
                break
        s += (' %s\n\n' % profile_t[0]) if exists_multi else '\n\n'

    return s
