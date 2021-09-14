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

// get a car
app.get('/api/cars/:key', async (req, res, next) => {
    doTransaction(req, res, next, async contract => {

        const key = req.params.key;
        const result = await contract.evaluateTransaction('getCar', key);
        const obj = utils.bufferToObject(result);
        res.json(obj);
    });
});

app.get('/api/cars', async (req, res, next) => {
    doTransaction(req, res, next, async contract => {

        const result = await contract.evaluateTransaction('getAllCars');
        const obj = utils.bufferToObject(result);
        res.json(obj);
    });
});

app.get('/api/drivers', async (req, res, next) => {
    doTransaction(req, res, next, async contract => {

        const result = await contract.evaluateTransaction('getAllDrivers');
        const obj = utils.bufferToObject(result);
        res.json(obj);
    });
});

// get a driver
app.get('/api/drivers/:key', async (req, res, next) => {
    doTransaction(req, res, next, async contract => {

        const key = req.params.key;
        const result = await contract.evaluateTransaction('getDriver', key);
        const obj = utils.bufferToObject(result);
        res.json(obj);
    });
});

// post charge
app.post('/api/charge', async (req, res, next) => {
    doTransaction(req, res, next, async contract => {

        const car_num = req.body.car_num;
        const tollgate = req.body.tollgate;
        await contract.submitTransaction('charge', car_num, tollgate);
        res.status(204).json();
    });
});

// post pay
app.post('/api/pay', async (req, res, next) => {
    doTransaction(req, res, next, async contract => {

        const phone = req.body.phone;
        const payed = req.body.payed;
        await contract.evaluateTransaction('pay', phone, payed);
        res.status(204).json();
    });
});

// running on localhost:3000
const port = 3000;
app.listen(port, () => console.log(`app listening at http://localhost:${port}`));

interface Err extends Error {
    status: number,
    data?: any
}
