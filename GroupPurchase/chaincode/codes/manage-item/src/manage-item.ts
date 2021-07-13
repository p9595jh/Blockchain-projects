import { Context, Contract } from "fabric-contract-api";
import { Deal, Item, Seller } from "./model";
import * as utils from './utils';

export class ManageItem extends Contract {

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

    async get(ctx: Context, key: string) {
        const byteItem = await ctx.stub.getState(key);
        if ( !byteItem || byteItem.length === 0 ) {
            throw new Error(`error on loading '${key}'`);
        }
        const result = utils.toItem(byteItem);
        return result;
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

    async registerItem(ctx: Context, category: string, name: string, itemId: number, stockCount: number, price: number) {
        try {
            const item: Item = {
                category: category,
                name: name,
                id: itemId,
                stock: stockCount,
                price: price
            };
            await ctx.stub.putState(`I-${itemId}`, utils.stateValue(item));

        } catch(err) {
            console.log(err);
        }
    }

    async execDeal(ctx: Context, itemId: number, sellerId: number, ...customerIds: number[]) {
        try {
            const date = new Date(ctx.stub.getTxTimestamp().seconds.low);
            const deal: Deal = {
                item: itemId,
                date: `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')}`,
                seller: sellerId,
                customers: customerIds
            };
            await ctx.stub.putState(`D-${date.getTime()}`, utils.stateValue(deal));

        } catch(err) {
            console.log(err);
        }
    }

}

