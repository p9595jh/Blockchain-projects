import { Gateway, Wallets, Contract } from 'fabric-network';
import * as utils from './utils';

function checkParamCount(need: number) {
    const length = process.argv.length - 3;
    if ( length !== need ) {
        console.log(`need ${need} parameter(s) to run '${process.argv[2]}', but ${length} received`);
        console.log('exit the program');
        process.exit(1);
    }
}

async function main() {
    try {
        const ccp = utils.getProfile(utils.delegate);
        const walletPath = utils.getWalletPath(utils.delegate);
        const wallet = await Wallets.newFileSystemWallet(walletPath);
        console.log(`Wallet path: ${walletPath}`);

        const appUser = utils.getUserId(utils.delegate);
        const identity = await wallet.get(appUser);
        if ( !identity ) {
            console.log(`An identity for the user "${appUser}" does not exist in the wallet`);
            console.log('Run the registerUser.js application before retrying');
            return;
        }

        const gateway = new Gateway();
        await gateway.connect(ccp, { wallet, identity: appUser, discovery: { enabled: true, asLocalhost: true } });
        const network = await gateway.getNetwork(utils.delegate.peer.channel.channel);
        const contract = network.getContract(utils.delegate.chaincode);

        if ( process.argv.length == 2 ) {
            console.log('there is no given parameter');
            console.log('exit the program');
            process.exit(1);
        }

        const parameters = process.argv.slice(2);

        // for querying
        // must add more arguments
        console.log(
            JSON.stringify(
                (await contract.evaluateTransaction(...parameters)).toString(),
                null,
                2
            )
        );

        // for invoke
        // must add more arguments
        console.log(
            JSON.stringify(
                (await contract.submitTransaction(...parameters)).toString(),
                null,
                2
            )
        );

        gateway.disconnect();

    } catch (error) {
        utils.plog(utils.LType.ERROR, 'Failed to submit transaction');
        utils.plog(utils.LType.ERROR, error);
        process.exit(1);
    }
}

main();
