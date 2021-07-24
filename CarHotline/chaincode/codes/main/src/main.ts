import { Context, Contract } from "fabric-contract-api";
import { Record, Report } from "./model";
import * as utils from './utils';

export class Main extends Contract {

    async initLedger(ctx: Context) {}

    async get(ctx: Context, key: any) {
        const byteItem = await ctx.stub.getState(key);
        if ( !byteItem || byteItem.length === 0 ) {
            throw new Error(`error on loading '${key}'`);
        }
        const result = utils.toItem(byteItem);
        return result;
    }

    async record(ctx: Context, owner: number, participant: number) {
        try {
            const record: Record = {
                timestamp: ctx.stub.getTxTimestamp().seconds.low,
                channelOwner: owner,
                participant: participant
            };
            record.key = `RC-${record.timestamp}-${owner}`;
            await ctx.stub.putState(record.key, utils.stateValue(record));

        } catch(err) {
            console.log(err);
        }
    }

    async handleReport(ctx: Context, reportId: string, result: string) {
        try {
            const report: Report = await this.get(ctx, reportId);
            report.handled = ctx.stub.getTxTimestamp().seconds.low;
            report.result = result;
            await ctx.stub.putState(report.key, utils.stateValue(report));

        } catch(err) {
            console.log(err);
        }
    }

}

