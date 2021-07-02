import * as express from 'express';
import { Gateway, Wallets, Contract } from 'fabric-network';
import { ccp, cc_name, channel_name, walletPath } from './utils';

const app = express();

app.use(express.json());

async function doTransaction(req: express.Request, res: express.Response, next: express.NextFunction, callback: (contract: Contract) => Promise<void>) {
    try {
        const wallet = await Wallets.newFileSystemWallet(walletPath);

        // Check to see if we've already enrolled the user.
        const identity = await wallet.get('appUser');
        if ( !identity ) {
            const message = 'An identity for the user "appUser" does not exist in the wallet.\nRun the registerUser.ts application before retrying.';
            res.status(500).json({message: message});
            return;
        }

        // Create a new gateway for connecting to our peer node.
        const gateway = new Gateway();
        await gateway.connect(ccp, { wallet, identity: 'appUser', discovery: { enabled: true, asLocalhost: true } });

        // Get the network (channel) our contract is deployed to.
        const network = await gateway.getNetwork(channel_name);

        // Get the contract from the network.
        const contract = network.getContract(cc_name);

        // Do custom transaction using callback function.
        await callback(contract);

        // Disconnect from the gateway.
        await gateway.disconnect();

    } catch(err) {
        next(err);
    }
}

function bufferToObject(buffer: Buffer) {
    try {
        return JSON.parse(buffer.toString());
    } catch(err) {
        return {};
    }
}


app.post('/api/getting-in', async (req, res, next) => {
    doTransaction(req, res, next, async contract => {

        const cafe = req.body.cafe;
        const phone = req.body.phone;
        const agreeToOfferInfo = req.body.agreeToOfferInfo;
        await contract.evaluateTransaction('gettingIn', cafe, phone, agreeToOfferInfo);
        res.status(204).json();
    });
});

app.post('/api/getting-out', async (req, res, next) => {
    doTransaction(req, res, next, async contract => {

        const phone = req.body.phone;
        await contract.evaluateTransaction('gettingOut', phone);
        res.status(204).json();
    });
});

app.get('/api/check-disobeyed', async (req, res, next) => {
    doTransaction(req, res, next, async contract => {

        const result = await contract.evaluateTransaction('checkDisobeyed');
        const obj = bufferToObject(result);
        res.json(obj);
    });
});

app.get('/api/ios', async (req, res, next) => {
    doTransaction(req, res, next, async contract => {

        const result = await contract.evaluateTransaction('getIOs');
        const obj = bufferToObject(result);
        res.json(obj);
    });
});

app.get('/api/ios/:phone', async (req, res, next) => {
    doTransaction(req, res, next, async contract => {

        const phone = req.params.phone;
        const result = await contract.evaluateTransaction('getIO', phone);
        const obj = bufferToObject(result);
        res.json(obj);
    });
});


const port = 3000;
app.listen(port, () => console.log(`app listening at http://localhost:${port}`));
