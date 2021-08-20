import { Context, Contract } from "fabric-contract-api";
import { Career } from "./model/career";
import * as utils from './utils';

export class CareerExperience extends Contract {

    async initLedger(ctx: Context) {}

    async updateCareer(ctx: Context, id: string, employee: number, company: number, type: string, startDate: string, endDate: string, description: string) {
        const career: Career = {
            id: id,
            employee: employee,
            company: company,
            type: type,
            startDate: startDate,
            endDate: endDate,
            description: description
        };
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

    async getMyCareers(ctx: Context, employee: number) {
        const res = ctx.stub.getQueryResult(JSON.stringify({
            selector: {
                employee: employee
            }
        }));

        const careers: Career[] = [];
        for await (let {key, value} of res) careers.push(utils.toItem(value));

        return careers;
    }

}

