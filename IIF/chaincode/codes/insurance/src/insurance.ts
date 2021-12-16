import { Context, Contract } from "fabric-contract-api";
import * as utils from './utils';
import * as models from '../../common/models';

export class Insurance extends Contract {

    async initLedger(ctx: Context) {
        const companies = [ 'INS1', 'INS2', 'INS3' ];
        for (let i=0; i<10; i++) {
            const insurance = new models.Insurance();
            insurance.name = 'INSURANCE' + i;
            insurance.company = i % 3;
            insurance.id = `${i}`;
            await ctx.stub.putState(insurance.genKey(), utils.stateValue(insurance));
        }
    }

    async getAllInsurances(ctx: Context) {
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

    async getInsurance(ctx: Context, key: any) {
        const byteItem = await ctx.stub.getState(key);
        if ( !byteItem || byteItem.length === 0 ) {
            throw new Error(`error on loading '${key}'`);
        }
        const result = utils.toItem(byteItem);
        return result;
    }

    async createInsurance(ctx: Context, name: string, company: number, id: string) {
        const insurance = new models.Insurance();
        insurance.name = name;
        insurance.company = company;
        insurance.id = id;
        await ctx.stub.putState(insurance.genKey(), utils.stateValue(insurance));
    }

    async updateInsurance(ctx: Context, key: string, field: string, value: any) {
        const insurance = await this.getInsurance(ctx, key);
        insurance[field] = value;
        await ctx.stub.putState(insurance.key, utils.stateValue(insurance));
    }

    async deleteInsurance(ctx: Context, key: string) {
        await ctx.stub.deleteState(key);
    }

}

