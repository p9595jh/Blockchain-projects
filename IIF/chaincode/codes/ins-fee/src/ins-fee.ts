import { Context, Contract } from "fabric-contract-api";
import { FeeData } from './fee-data';
import * as utils from './utils';

export class InsFee extends Contract {

    async initLedger(context: Context) {
        console.log('initializing the chaincode');

        for (let i=0; i<8; i++) {
            const fee: FeeData = {
                date: utils.dateFormat(new Date(context.stub.getTxTimestamp().nanos)),
                num: this.key(context),
                companyCode: ['012', '014'][Math.floor(Math.random() * 2)],
                product: 'PRODUCT' + i,
                fee: Math.floor(Math.random() * 100000) + 100000
            };
            fee.key = fee.num;
            await context.stub.putState(fee.key, utils.stateValue(fee));
        }

        console.log('initialized');
    }

    async getAll(context: Context) {
        const startKey = '';
        const endKey = '';
        const results: FeeData[] = [];

        for await (const {key, value} of context.stub.getStateByRange(startKey, endKey)) {
            const strValue = Buffer.from(value).toString('utf8');
            let record: FeeData;
            try {
                record = JSON.parse(strValue);
                record.key = key;
            } catch(err) {
                console.log(err);
                record = new FeeData();
                record.key = key;
            }
            results.push(record);
        }
        return results;
    }

    async get(context: Context, key: string) {
        const byteItem = await context.stub.getState(key);
        if ( !byteItem || byteItem.length === 0 ) {
            throw new Error(`error on loading data '${key}'`);
        }
        try {
            const fee = <FeeData> JSON.parse( byteItem.toString() );
            return fee;

        } catch(err) {
            console.log(err);
            return undefined;
        }
    }

    async create(context: Context, companyCode: string, product: string, fee: number) {
        try {
            const f: FeeData = {
                date: utils.dateFormat(new Date(context.stub.getTxTimestamp().nanos)),
                num: this.key(context),
                companyCode: companyCode,
                product: product,
                fee: fee
            };
            f.key = f.num;
            await context.stub.putState(f.key, utils.stateValue(f));
            console.log(`new fee data generated`);

        } catch(err) {
            console.log(err);
            return undefined;
        }
    }

    async edit(context: Context, key: string, field: string, value: string) {
        const byteItem = await context.stub.getState(key);
        if ( !byteItem || byteItem.length === 0 ) {
            throw new Error(`error on loading data '${key}'`);
        }
        try {
            const f = <FeeData> JSON.parse( byteItem.toString() );
            const keys = f.key.split('-');
            let sequence = 1
            if ( keys[keys.length - 1].includes('E') ) {
                sequence = parseInt( keys[keys.length - 1].substring(1) ) + 1;
                keys.length -= 1;
                keys.push('E' + sequence);
            }
            const newKey = keys.join('-');
            f.key = newKey;
            f.num = newKey;
            f[field] = value;
            await context.stub.putState(f.key, utils.stateValue(f));
            console.log(`fee data edited`);

        } catch(err) {
            console.log(err);
            return undefined;
        }
    }

    private key(context: Context) {
        const r = Math.floor(Math.random() * 1000);
        return `G-${context.stub.getTxTimestamp().nanos}-${r}`;
    }

}

