import { Wallets, X509Identity } from 'fabric-network';
import * as FabricCAServices from 'fabric-ca-client';
import * as utils from './utils';

async function main() {
    try {
        const ccp = utils.getProfile(utils.delegate);
        // Create a new CA client for interacting with the CA.
        const caURL = ccp.certificateAuthorities[`ca.${utils.delegate.addr}.${utils.SERV_NM}.com`].url;
        const ca = new FabricCAServices(caURL);

        // const appUser = process.argv.length > 2 ? process.argv[2] : 'appUser';
        let appUser = 'appUser';

        // Create a new file system based wallet for managing identities.
        const walletPath = utils.getWalletPath(utils.delegate);
        const wallet = await Wallets.newFileSystemWallet(walletPath);
        console.log(`Wallet path: ${walletPath}`);

        // Check to see if we've already enrolled the user.
        const userIdentity = await wallet.get(appUser);
        if ( userIdentity ) {
            // console.log(`An identity for the user "${appUser}" already exists in the wallet`);
            return;
        }

        // for (let i=1;; i++) {
        //     try {
        //         console.log(1);
        //         const userIdentity = await wallet.get(appUser + i);
        //         if ( !userIdentity ) {
        //             appUser = appUser + i;
        //             break;
        //         }
        //     } catch(err) {
        //         console.log(2);
        //         // continue;
        //     }
        // }

        // Check to see if we've already enrolled the admin user.
        const adminIdentity = await wallet.get('admin');
        if ( !adminIdentity ) {
            console.log('An identity for the admin user "admin" does not exist in the wallet');
            console.log('Run the enrollAdmin.js application before retrying');
            return;
        }

        // build a user object for authenticating with the CA
        const provider = wallet.getProviderRegistry().getProvider(adminIdentity.type);
        const adminUser = await provider.getUserContext(adminIdentity, 'admin');

        // Register the user, enroll the user, and import the new identity into the wallet.
        const secret = await ca.register({
            affiliation: `${utils.delegate.addr}.department1`,
            enrollmentID: appUser,
            role: 'client'
        }, adminUser);
        const enrollment = await ca.enroll({
            enrollmentID: appUser,
            enrollmentSecret: secret
        });
        const x509Identity = {
            credentials: {
                certificate: enrollment.certificate,
                privateKey: enrollment.key.toBytes(),
            },
            mspId: utils.delegate.name,
            type: 'X.509',
        };
        await wallet.put(appUser, x509Identity);
        utils.plog(utils.LType.INFO, 'Successfully registered and enrolled admin user "appUser" and imported it into the wallet');

    } catch (error) {
        utils.plog(utils.LType.ERROR, `Failed to register user "appUser": ${error}`);
        process.exit(1);
    }
}

main();
