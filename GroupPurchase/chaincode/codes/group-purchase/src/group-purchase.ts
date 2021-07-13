import { Context, Contract } from "fabric-contract-api";
import { Customer, Seller } from "./model";
import * as utils from './utils';

export class GroupPurchase extends Contract {

    async initLedger(ctx: Context) {}

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

    async apply(ctx: Context, customerId: number, count: number) {
        try {
            const customer: Customer = {
                id: customerId,
                numberOfBought: count
            };
            await ctx.stub.putState(`C-${customerId}`, utils.stateValue(customer));

        } catch(err) {
            console.log(err);
        }
    }

    async registerSeller(ctx: Context, sellerId: number, itemId: number) {
        try {
            const seller: Seller = {
                id: sellerId,
                sellingItem: itemId
            };
            await ctx.stub.putState(`S-${sellerId}`, utils.stateValue(seller));

        } catch(err) {
            console.log(err);
        }
    }

}

