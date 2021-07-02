import * as path from 'path';
import * as fs from 'fs';

export const orgNm = 'Cafe1MSP';
export const orgAddr = 'cafe1';
export const servNm = 'hn';

export const channel_name = 'hnchannel';
export const cc_name = 'cafe-manage';

const ccpPath = path.resolve(__dirname, '..', '..', 'network', 'organizations', 'peerOrganizations', `${orgAddr}.${servNm}.com`, `connection-${orgAddr}.json`);
export const ccp = JSON.parse(fs.readFileSync(ccpPath, 'utf8'));

// export const walletPath = path.join(process.cwd(), 'wallet');
export const walletPath = path.join(process.cwd(), 'wallet');
