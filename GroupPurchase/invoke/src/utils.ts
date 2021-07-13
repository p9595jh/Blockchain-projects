import * as path from 'path';
import * as fs from 'fs';

class Organ {
    addr: string;
    name: string;
    msp: string;
    peers: Peer[]
}

class Peer {
    org: Organ;
    name: string;
    port: number;
    channels: FabChannel[];
}

class FabChannel {
    channel: string;
    profile: string;
    consortium: string;
}

interface Delegate {
    addr: string,
    name: string,
    msp: string,
    chaincode: string,
    peer: {
        org: Organ,
        name: string,
        port: number,
        channel: {
            channel: string,
            profile: string,
            consortium: string
        }
    }
}

const data = JSON.parse( path.readFileSync('data.json', { encoding: 'utf8' }) );
export const SERV_NM = data.srvn;
export const delegate: Delegate = data.delegate;
export const organs: Organ[] = data.organs;
export const organ_obj: {
    [org_addr: string]: {
        [peer_name: string]: Peer
    }
} = {};

organs.map(organ => {
    organ_obj[organ.addr] = {};
    organ.peers.map(peer => organ_obj[organ.addr][peer.name] = peer);
});

const colors = {
    Reset: "\x1b[0m",
    Bright: "\x1b[1m",
    Dim: "\x1b[2m",
    Underscore: "\x1b[4m",
    Blink: "\x1b[5m",
    Reverse: "\x1b[7m",
    Hidden: "\x1b[8m",

    FgBlack: "\x1b[30m",
    FgRed: "\x1b[31m",
    FgGreen: "\x1b[32m",
    FgYellow: "\x1b[33m",
    FgBlue: "\x1b[34m",
    FgMagenta: "\x1b[35m",
    FgCyan: "\x1b[36m",
    FgWhite: "\x1b[37m",

    BgBlack: "\x1b[40m",
    BgRed: "\x1b[41m",
    BgGreen: "\x1b[42m",
    BgYellow: "\x1b[43m",
    BgBlue: "\x1b[44m",
    BgMagenta: "\x1b[45m",
    BgCyan: "\x1b[46m",
    BgWhite: "\x1b[47m"
};

export const LType = {
    INFO: colors.FgBlue,
    ERROR: colors.FgRed,
    WARN: colors.FgYellow
}

export function plog(logType: string, log: any) {
    console.log(`${logType}${log}${colors.Reset}`);
}

export function getProfile(d: Delegate) {
    try {
        const upperFolder = 'network';
        let p = __dirname;
        for (
            let i = 0;
            !fs.existsSync( path.resolve(p, upperFolder) ) && i < 10;
            p = path.resolve(p, '..'), i++
        );
        const ccpPath = path.resolve(p, upperFolder, 'organizations', 'peerOrganizations', `${d.addr}.${SERV_NM}.com`, `connection-${d.addr}.json`);
        return JSON.parse(fs.readFileSync(ccpPath, 'utf8'));

    } catch(err) {
        plog(LType.ERROR, `Failed to load profile`);
        plog(LType.ERROR, err);
    }
}

export function getWalletPath(delegate: Delegate) {
    return path.join(process.cwd(), 'wallets', `${delegate.peer.name}.${delegate.addr}.${delegate.peer.channel.channel}`);
}

export function getUserId(delegate: Delegate) {
    const walletPath = getWalletPath(delegate);
    const files = fs.readdirSync(walletPath);
    files.sort((a, b) => { return b.localeCompare(a) });
    return files[0].substring(0, files[0].lastIndexOf('.'));
}

export function bufferToObject(buffer: Buffer) {
    try {
        return JSON.parse(buffer.toString());
    } catch(err) {
        return {};
    }
}

