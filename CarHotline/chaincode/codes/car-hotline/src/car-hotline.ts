import { Context, Contract } from "fabric-contract-api";
import { Car, Report } from "./model";
import * as utils from './utils';

export class CarHotline extends Contract {

    async initLedger(ctx: Context) {}

    async getsByCondition(ctx: Context, field: string, value: any) {
        const res = ctx.stub.getQueryResult(JSON.stringify({
            selector: {
                [field]: value
            }
        }));
        const results = [];
        for await (const {key, value} of res) {
            results.push(utils.toItem(value));
        }

        return results.length === 1 ? results[0] : results;
    }

    async allowChat(ctx: Context, owner: number, participant: number, recordId: string) {
        try {
            const ownerCar: Car = await this.getsByCondition(ctx, 'owner', owner);
            const participantCar: Car = await this.getsByCondition(ctx, 'owner', participant);

            ownerCar.conversations.push(recordId);
            participantCar.conversations.push(recordId);

            await ctx.stub.putState(ownerCar.key, utils.stateValue(ownerCar));
            await ctx.stub.putState(participantCar.key, utils.stateValue(participantCar));

        } catch(err) {
            console.log(err);
        }
    }

    async report(ctx: Context, reporter: number, recordId: string, description: string) {
        try {
            const report: Report = {
                timestamp: ctx.stub.getTxTimestamp().seconds.low,
                recordId: recordId,
                description: description,
                handled: undefined,
                result: undefined
            };
            report.key = `RP-${report.timestamp}-${reporter}`;
            await ctx.stub.putState(report.key, utils.stateValue(report));

        } catch(err) {
            console.log(err);
        }
    }

}

