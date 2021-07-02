import config
import util

def unset(params):
    s = '# to remove channel info\n'
    for param in params:
        s += 'unset {}[5]\n'.format(param)
    s += '\n'
    return s

def make_param_join(params):
    return ' '.join(['${%s[@]}' % param for param in params])

def match_variables(params, rns, indent='  '):
    s = ''
    for i, rn in enumerate(rns):
        s += indent + '%s=("${%s[@]}")\n' % (params[i], rn)
    s += '\n'
    return s

def kurikaesu(params, label, command, infoln=None):
    s = '## ' + label + '\n'
    if infoln is not None:
        s += 'infoln "{}"\n'.format(infoln)
    for param in params:
        s += '%s ${%s[@]}\n' % (command, param)
    s += '\n'
    return s

def one_set(params, indent='  '):
    s = indent + unset(params)

    s += indent + '## package the chaincode\npackageChaincode\n\n'
    s += indent + kurikaesu(params, 'Install chaincode', 'installChaincode', 'Installing chaincode on the channel...')
    s += indent + kurikaesu(params, 'query whether the chaincode is installed', 'queryInstalled')
    s += indent + kurikaesu(params, 'approve the definition for the channel', 'approveForMyOrg')

    s += indent + '## now that we know for sure both orgs have approved, commit the definition\n'
    param_join = make_param_join(params)
    s += indent + 'commitChaincodeDefinition %s\n\n' % param_join

    s += indent + kurikaesu(params, 'query on both orgs to see that the definition committed successfully', 'queryCommitted')

    s += indent + '## Invoke the chaincode - this does require that the chaincode have the `initLedger` method defined\n'
    s += indent + 'if [ "$CC_INIT_FCN" = "NA" ]; then\n'
    s += indent + '  infoln "Chaincode initialization is not required"\n'
    s += indent + 'else\n'
    s += indent + '  chaincodeInvokeInit %s\n' % param_join
    s += indent + 'fi\n\n'

    return s

def deploy_single_channel():
    rns = config.channel_identities[list(config.channel_identities.keys())[0]][2]
    params = ['param{}'.format(i + 1) for i in range(len(rns))]
    s = match_variables(params, rns, '')
    return s + one_set(params, '')

def deploy_multiple_but_same_len(l):
    s = ''
    params = ['param{}'.format(i + 1) for i in range(l)]
    for i, (channel, profile_t) in enumerate(config.channel_identities.items()):
        s += '%s [ "$CHANNEL_NAME" = "%s" ]; then\n\n' % ('if' if i == 0 else 'elif', channel)
        s += match_variables(params, profile_t[2])
        s += '\n'
    s += 'fi\n\n'
    s += one_set(params, '')
    return s

def deploy_multiple_and_diff_len():
    s = ''
    for i, (channel, profile_t) in enumerate(config.channel_identities.items()):
        params = ['param{}'.format(i + 1) for i in range(len(profile_t[2]))]
        s += '%s [ "$CHANNEL_NAME" = "%s" ]; then\n\n' % ('if' if i == 0 else 'elif', channel)
        s += match_variables(params, profile_t[2])
        s += '\n'
        s += one_set(params)
    s += 'fi\n\n'
    return s

def deploy():
    if len(config.channel_identities.keys()) == 1:
        return deploy_single_channel()
    
    l = 0
    for i, (channel, profile_t) in enumerate(config.channel_identities.items()):
        if i == 0:
            l = len(profile_t[2])
        elif l != len(profile_t[2]):
                return deploy_multiple_and_diff_len()
    
    return deploy_multiple_but_same_len(l)

