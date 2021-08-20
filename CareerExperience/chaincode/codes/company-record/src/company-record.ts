import { Context, Contract } from "fabric-contract-api";
import { Career } from "./model/career";
import * as utils from './utils';

export class CompanyRecord extends Contract {

    async initLedger(ctx: Context) {}

    async writeWork(ctx: Context, company: number, type: string, description: string, ...employees: string[]) {
        const career = new Career();
        const ts = ctx.stub.getTxTimestamp().seconds.low;
        career.company = company;
        career.type = type;
        career.description = description;
        career.startDate = utils.formatDate(ts);
        for (let i = 0; i < employees.length; i+=2) {
            const employeeAgreed = Boolean(employees[i + 1]);
            if ( employeeAgreed ) {
                const employeeId = parseInt(employees[i]);
                career.id = `C${company}-${ts}-${employeeId}`;
                career.employee = employeeId;
                await ctx.stub.putState(career.id, utils.stateValue(career));
            }
        }
    }

    async endWork(ctx: Context, id: string) {
        const career: Career = await this.get(ctx, id);
        career.endDate = utils.formatDate(ctx.stub.getTxTimestamp().seconds.low);
        await ctx.stub.putState(career.id, utils.stateValue(career));
    }

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

}

