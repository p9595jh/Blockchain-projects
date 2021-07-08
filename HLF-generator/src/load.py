import os
import config
import util
import json
import yaml
import shutil
import node
import docker
import argparse
from configtx import configtx
from datetime import datetime
from copy import deepcopy
from configtx import configtx
from create_channel import create_channel
from deploy import deploy
from main import pre_process, run_process


if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument('--log', default=True, required=False)
    args = parser.parse_args()
    try:
        args.log = bool(args.log)
    except:
        args.log = False


    print('\n<history>')
    histories = os.listdir('../history')
    histories.sort()
    for i in range(0, len(histories), 2):
        with open('../history/' + histories[i], 'r') as f:
            print(histories[i][:histories[i].rfind('.')], end='')
            try:
                print(' (%s)' % json.load(f)['project_name'])
            except KeyError as e:
                print()
    print()

    default = histories[-1][:histories[-1].rfind('.')]
    s = input('History to load (default is `%s`): ' % default).strip()
    if s == '': s = default
    history_path = '../history/%s.json' % s
    if not os.path.exists(history_path):
        print('There is no file `%s`' % s)
        exit(1)
    with open(history_path, 'r') as f:
        jsn = json.load(f)

    print()

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

    config.project_name = jsn['project_name']
    config.path = '../exports/{}/'.format(config.project_name)

    if os.path.exists(config.path):
        answer = util.sinput('`%s` already exists; Would you like to remove and continue? (y/N)' % config.project_name, '[yYnN]{1}', default='y').upper()
        if answer == 'N':
            config.project_name = util.sinput('rename', default='Example')
            config.path = '../exports/{}/'.format(config.project_name)
            while True:
                if os.path.exists(config.path):
                    print('`{}` already exists; Input again please')
                    config.project_name = util.sinput('rename', default='Example')
                    config.path = '../exports/{}/'.format(config.project_name)
                else:
                    break
        else:
            shutil.rmtree(config.path)


    config.project_creator = jsn['project_creator']
    config.srvn = jsn['srvn']
    config.network_profile = jsn['network_profile']

    # chaincode setting
    config.chaincode_title = jsn['chaincode_name']
    config.chaincode_title_folder = jsn['chaincode_folder']

    pre_process()

    config.channel_identities = jsn['channel_identities']
    for key in config.channel_identities.keys():
        config.channel_identities[key] = tuple(config.channel_identities[key])

    for organ in jsn['organs']:
        peers = []
        for peer in organ['peers']:
            peers.append(node.Peer(peer['name'], peer['port'], peer['dbport'], [node.FabChannel(channel['channel'], channel['profile'], channel['consortium']) for channel in peer['channels']]))
        util.organs.append(node.Organ(organ['addr'], organ['name'], organ['msp'], organ['caport'], organ['admin'], organ['adminpw'], peers))

    util.orderer = node.Orderer(jsn['orderer']['msp'], jsn['orderer']['caport'], [node.OrdererItem(item['addr'], item['name'], item['port']) for item in jsn['orderer']['items']])

    run_process(log=args.log)

    print('Working done - check the folder `{}`'.format(config.path))
    print()

