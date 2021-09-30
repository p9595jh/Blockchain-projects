import { Context, Contract } from "fabric-contract-api";
import * as utils from './utils';
import * as models from '../../common/models';

export class ConstructorRegi extends Contract {

    async initLedger(ctx: Context) {
        const companyNames = [ 'INS1', 'INS2', 'INS3', 'GA1', 'GA2' ];
        for (let [i, name] of companyNames.entries()) {
            const c = name.startsWith('INS') ? new models.InsuranceCompany() : new models.Ga();
            c.code = i;
            c.name = name;
            c.found = '20000101';
            await ctx.stub.putState(c.genKey(), utils.stateValue(c));

            const constructor = new models.Constructor();
            constructor.id = Math.floor( Math.random() * 100000 ).toString().padStart(5, '0');
            constructor.type = c.representedAs() === 'GA' ? 'GA' : 'EXCLUSIVE';
            constructor.company = c.code;
            await ctx.stub.putState(constructor.genKey(), utils.stateValue(constructor));
        }
    }

    async getAllConstructor(ctx: Context) {
        const res = ctx.stub.getQueryResult(JSON.stringify({
            selector: {
                key: {
                    $regex: `^${new models.Constructor().representedAs()}-`
                }
            }
        }));
        const items: models.Constructor[] = [];
        for await (const {key, value} of res) items.push(utils.toItem(value));
        return items;
    }

    async getAllInsuranceCompanies(ctx: Context) {
        const res = ctx.stub.getQueryResult(JSON.stringify({
            selector: {
                key: {
                    $regex: `^${new models.InsuranceCompany().representedAs()}-`
                }
            }
        }));
        const items: models.InsuranceCompany[] = [];
        for await (const {key, value} of res) items.push(utils.toItem(value));
        return items;
    }

    async getAllGAs(ctx: Context) {
        const res = ctx.stub.getQueryResult(JSON.stringify({
            selector: {
                key: {
                    $regex: `^${new models.Ga().representedAs()}-`
                }
            }
        }));
        const items: models.Ga[] = [];
        for await (const {key, value} of res) items.push(utils.toItem(value));
        return items;
    }

    async get(ctx: Context, key: string) {
        const byteItem = await ctx.stub.getState(key);
        if ( !byteItem || byteItem.length === 0 ) {
            throw new Error(`error on loading '${key}'`);
        }
        const result = utils.toItem(byteItem);
        return result;
    }

    async createConstructor(ctx: Context, id: string, type: string, company: number) {
        const constructor = new models.Constructor();
        constructor.id = id;
        constructor.type = type;
        constructor.company = company;
        await ctx.stub.putState(constructor.key, utils.stateValue(constructor));
    }

    async updateConstructor(ctx: Context, data: any) {
        await ctx.stub.putState(data.key, utils.stateValue(data));
    }

    async deleteConstructor(ctx: Context, key: any) {
        await ctx.stub.deleteState(key);
    }

}

