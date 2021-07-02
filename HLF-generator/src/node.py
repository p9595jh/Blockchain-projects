import config


class Orderer:
    def __init__(self, msp, caport, items):
        self.msp = msp
        self.caport = caport
        self.items = items
        for item in self.items:
            item.orderer = self


class OrdererItem:
    def __init__(self, addr, name, port, orderer=None):
        super().__init__()
        self.addr = addr
        self.name = name
        self.port = port
        self.orderer = orderer


class Organ:
    def __init__(self, addr, name, msp, caport, admin='admin', adminpw='adminpw', peers=[]):
        self.addr = addr
        self.name = name
        self.msp = msp
        self.caport = caport
        self.admin = admin
        self.adminpw = adminpw
        self.peers = []
        if peers is not None:
            for peer in peers:
                peer.org = self
                self.peers.append(peer)
    
    def add_peer(self, peer):
        peer.org = self
        self.peers.append(peer)

    def __str__(self):
        return '<Organ>(addr: %s, name: %s, msp: %s, caport: %d, admin: %s, adminpw: %s, peers: %s' % (self.addr, self.name, self.msp, self.caport, self.admin, self.adminpw, str([peer.name for peer in self.peers]))


class FabChannel:
    def __init__(self, channel, profile, consortium=config.consortium_name):
        self.channel = channel
        self.profile = profile
        self.consortium = consortium

    def __str__(self):
        return '<FabChannel>(channel: %s, profile: %s, consortium: %s)' % (self.channel, self.profile, self.consortium)


class Peer:
    def __init__(self, name, port, dbport, channels, org=None):
        self.org = org
        self.name = name
        self.port = port
        self.dbport = dbport
        self.channels = channels

    def __str__(self):
        return '<Peer>(org: %s, name: %s, port: %d, dbport: %d, channels: %s)' % (self.org.name, self.name, self.port, self.dbport, self.channels)

