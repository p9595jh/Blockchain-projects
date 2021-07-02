import { Gateway, Wallets } from 'fabric-network';
import { ccp, cc_name, channel_name, orgAddr, orgNm, servNm, walletPath } from './utils';

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

        if ( process.argv.length == 2 ) {
            console.log('there is no given parameter');
            console.log('exit the program');
            process.exit(1);
        }

        switch (process.argv[2]) {
            case 'gettingIn':
                checkParamCount(3);
                await contract.submitTransaction(process.argv[2], process.argv[3], process.argv[4], process.argv[5]);
                console.log('got in successfully');
                break;

            case 'gettingOut':
                checkParamCount(1);
                await contract.submitTransaction(process.argv[2], process.argv[3]);
                console.log('got out successfully');
                break;

            case 'getIOs':
                console.log(
                    JSON.stringify(
                        JSON.parse( (await contract.evaluateTransaction(process.argv[2])).toString() ),
                        null,
                        2
                    )
                );
                break;

            case 'getIO':
                console.log(
                    JSON.stringify(
                        JSON.parse( (await contract.evaluateTransaction(process.argv[2], process.argv[3])).toString() ),
                        null,
                        2
                    )
                );
                break;

            case 'checkDisobeyed':
                console.log(
                    JSON.stringify(
                        JSON.parse( (await contract.evaluateTransaction(process.argv[2])).toString() ),
                        null,
                        2
                    )
                );
                break;

            default:
                console.log(`no function named '${process.argv[2]}'`);
        }

        // Disconnect from the gateway.
        gateway.disconnect();

    } catch (error) {
        console.error(`Failed to submit transaction: ${error}`);
        process.exit(1);
    }
}

main();
