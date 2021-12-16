import { Context, Contract } from "fabric-contract-api";
import * as utils from './utils';
import * as models from '../../common/models';


export class UserRegi extends Contract {

    async initLedger(ctx: Context) {
        Math.floor( Math.random() * 100000 ).toString().padStart(5, '0');
        for (let i=0; i<10; i++) {
            const customer = new models.Customer();
            customer.id = 'C-' + i;
            customer.insurances = [];
            await ctx.stub.putState(customer.genKey(), utils.stateValue(customer));
        }
    }

    async getAllCustomers(ctx: Context) {
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

    async getCustomer(ctx: Context, key: string) {
        const byteItem = await ctx.stub.getState(key);
        if ( !byteItem || byteItem.length === 0 ) {
            throw new Error(`error on loading '${key}'`);
        }
        const result: models.Customer = utils.toItem(byteItem);
        return result;
    }

    async createCustomer(ctx: Context, id: string) {
        const customer = new models.Customer();
        customer.id = id;
        customer.insurances = [];
        await ctx.stub.putState(customer.genKey(), utils.stateValue(customer));
    }

    async updateCustomer(ctx: Context, id: string, field: string, value: any) {
        const customer = await this.getCustomer(ctx, id);
        customer[field] = value;
        await ctx.stub.putState(customer.key, utils.stateValue(customer));
    }

    async deleteCustomer(ctx: Context, key: string) {
        await ctx.stub.deleteState(key);
    }

}

