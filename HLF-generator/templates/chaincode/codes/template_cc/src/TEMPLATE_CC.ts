import { Context, Contract } from "fabric-contract-api";
import * as utils from './utils';

export class {{TEMPLATE_CC}} extends Contract {

    async initLedger(ctx: Context) {}

    ////////////////////////////////////////////////////////////////////////////////////////
    //
    //   Functions below are to just refer.
    //   Please remove when start developing.
    //
    //   Reference functions: getAll, get, create, update, delete
    //   getAll:    get all data from database
    //   get:       get a specific data with a given key
    //   create:    create new data and insert to the database
    //   update:    update a given data
    //   delete:    delete a data in the database with a given key
    //
    ////////////////////////////////////////////////////////////////////////////////////////
    async getAll(ctx: Context) {
        const startKey = '';
        const endKey = '';
        const results = [];
        for await (const {key, value} of ctx.stub.getStateByRange(startKey, endKey)) {
            const strValue = Buffer.from(value).toString('utf8');
            let record: any;
            try {
                record = JSON.parse(strValue);
                record.key = key;
            } catch(err) {
                console.log(err);
                record = {};
                record.key = key;
            }
            results.push(record);
        }
        return results;
    }

    async get(ctx: Context, key: any) {
        const byteItem = await ctx.stub.getState(key);
        if ( !byteItem || byteItem.length === 0 ) {
            throw new Error(`error on loading '${key}'`);
        }
        const result = utils.toItem(byteItem);
        return result;
    }

    async create(ctx: Context, value: any) {
        const timestamp = ctx.stub.getTxTimestamp().seconds.low;
        const data = {
            key: `T-${timestamp}`,
            value: value
        };
        await ctx.stub.putState(data.key, utils.stateValue(data));
    }

    async update(ctx: Context, data: any) {
        await ctx.stub.putState(data.key, utils.stateValue(data));
    }

    async delete(ctx: Context, key: any) {
        await ctx.stub.deleteState(key);
    }

}

