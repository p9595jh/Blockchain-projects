import * as express from 'express';
import { Gateway, Wallets, Contract } from 'fabric-network';
import * as path from 'path';
import * as logger from 'morgan';
import * as utils from './utils'
const createError = require('http-errors')

const app = express();

app.use(express.json());
app.use(logger('dev'));
app.use(express.static(path.join(__dirname, 'public')));
app.use((err: Err, req: express.Request, res: express.Response, next: express.NextFunction) => {
    res.status(err.status || 500);
    res.json({
        message: err.message,
        data: err.data
    });
});

async function doTransaction(req: express.Request, res: express.Response, next: express.NextFunction, callback: (contract: Contract) => Promise<void>) {
    try {
        const ccp = utils.getProfile(utils.delegate);
        const walletPath = utils.getWalletPath(utils.delegate);
        const wallet = await Wallets.newFileSystemWallet(walletPath);

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

        await callback(contract);
        await gateway.disconnect();

    } catch(err) {
        next(err);
    }
}


/////////////////////////////////////////////////////////////////////////////////
//
//  Below functions are for tutorial; GET (single, couple), POST, PUT, DELETE
//
/////////////////////////////////////////////////////////////////////////////////

// get all
app.get('/api/samples', async (req, res, next) => {
    doTransaction(req, res, next, async contract => {

        const result = await contract.evaluateTransaction('getAll');
        const obj = utils.bufferToObject(result);
        res.json(obj);
    });
});

// get
app.get('/api/samples/:key', async (req, res, next) => {
    doTransaction(req, res, next, async contract => {

        const key = req.params.key;
        const result = await contract.evaluateTransaction('get', key);
        const obj = utils.bufferToObject(result);
        res.json(obj);
    });
});

// post (create)
app.post('/api/samples', async (req, res, next) => {
    doTransaction(req, res, next, async contract => {

        const key = req.body.key;
        const value = req.body.value;
        await contract.submitTransaction('create', key, value);
        res.status(204).json();
    });
});

// put (update)
app.put('/api/samples', async (req, res, next) => {
    doTransaction(req, res, next, async contract => {

        const key = req.body.key;
        const value = req.body.value;
        await contract.submitTransaction('update', key, value);
        res.json();
    })
});

// delete
app.delete('/api/samples/:key', async (req, res, next) => {
    doTransaction(req, res, next, async contract => {

        const key = req.params.key;
        const result = await contract.submitTransaction('delete', key);
        const obj = utils.bufferToObject(result);
        res.json(obj);
    });
});

// running on localhost:3000
const port = 3000;
app.listen(port, () => console.log(`app listening at http://localhost:${port}`));

interface Err extends Error {
    status: number,
    data?: any
}
