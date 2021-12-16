import { Context, Contract } from "fabric-contract-api";
import * as models from '../../common/models';
import * as utils from './utils';

export class InsFee extends Contract {

    async initLedger(ctx: Context) {
        console.log('initializing the chaincode');

        for (let i=0; i<8; i++) {
            const fee = new models.FeeData();
            fee.date = utils.dateFormat(new Date(ctx.stub.getTxTimestamp().nanos));
            fee.num = `${ctx.stub.getTxTimestamp().nanos}`;
            fee.companyCode = [12, 14][Math.floor(Math.random() * 2)];
            fee.product = 'INS-' + i;
            fee.fee = Math.floor(Math.random() * 100000) + 100000;
            await ctx.stub.putState(fee.genKey(), utils.stateValue(fee));
        }

        console.log('initialized');
    }

    async getAll(ctx: Context) {
        const startKey = '';
        const endKey = '';
        const results: models.FeeData[] = [];

        for await (const {key, value} of ctx.stub.getStateByRange(startKey, endKey)) {
            const strValue = Buffer.from(value).toString('utf8');
            let record: models.FeeData;
            try {
                record = JSON.parse(strValue);
                record.key = key;
            } catch(err) {
                console.log(err);
                record = new models.FeeData();
                record.key = key;
            }
            results.push(record);
        }
        return results;
    }

    async get(ctx: Context, key: string) {
        const byteItem = await ctx.stub.getState(key);
        if ( !byteItem || byteItem.length === 0 ) {
            throw new Error(`error on loading data '${key}'`);
        }
        try {
            const fee = <models.FeeData> JSON.parse( byteItem.toString() );
            return fee;

        } catch(err) {
            console.log(err);
            return undefined;
        }
    }

    async create(ctx: Context, companyCode: number, product: string, fee: number) {
        try {
            const f = new models.FeeData();
            f.date = utils.dateFormat(new Date(ctx.stub.getTxTimestamp().nanos));
            f.num = `${ctx.stub.getTxTimestamp().nanos}`;
            f.companyCode = companyCode;
            f.product = product;
            f.fee = fee;
            f.key = f.num;
            await ctx.stub.putState(f.key, utils.stateValue(f));
            console.log(`new fee data generated`);

        } catch(err) {
            console.log(err);
            return undefined;
        }
    }

    async edit(ctx: Context, key: string, field: string, value: any) {
        const byteItem = await ctx.stub.getState(key);
        if ( !byteItem || byteItem.length === 0 ) {
            throw new Error(`error on loading data '${key}'`);
        }
        try {
            const f = <models.FeeData> JSON.parse( byteItem.toString() );
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
            await ctx.stub.putState(f.key, utils.stateValue(f));
            console.log(`fee data edited`);

        } catch(err) {
            console.log(err);
            return undefined;
        }
    }

}

