import { Gateway, Wallets } from 'fabric-network';
import { ccp, cc_name, channel_name, orgAddr, orgNm, servNm, walletPath } from './utils';

async function main() {
    try {
        // Create a new file system based wallet for managing identities.
        const wallet = await Wallets.newFileSystemWallet(walletPath);
        console.log(`Wallet path: ${walletPath}`);

        // Check to see if we've already enrolled the user.
        const identity = await wallet.get('appUser');
        if ( !identity ) {
            console.log('An identity for the user "appUser" does not exist in the wallet');
            console.log('Run the registerUser.js application before retrying');
            return;
        }

        // Create a new gateway for connecting to our peer node.
        const gateway = new Gateway();
        await gateway.connect(ccp, { wallet, identity: 'appUser', discovery: { enabled: true, asLocalhost: true } });

        // Get the network (channel) our contract is deployed to.
        const network = await gateway.getNetwork(channel_name);

        // Get the contract from the network.
        const contract = network.getContract(cc_name);

        // Submit the specified transaction.
        await contract.submitTransaction('gettingIn', 'starbucks', '01044445555', 'true');
        console.log('Transaction has been submitted');

        // Disconnect from the gateway.
        gateway.disconnect();

    } catch (error) {
        console.error(`Failed to submit transaction: ${error}`);
        process.exit(1);
    }
}

main();
