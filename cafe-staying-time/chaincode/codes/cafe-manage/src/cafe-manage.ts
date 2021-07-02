import { Context, Contract } from "fabric-contract-api";
import { IO } from "./io";
import { getItem, stateValue, toItem } from "./utils";

export class CafeManage extends Contract {

    async initLedger(context: Context) {
        console.log('initializing the chaincode');
        const ts = context.stub.getTxTimestamp().seconds.low;
        const ios: IO[] = [
            {
                cafe: 'starbucks',
                phone: '01012345678',
                in_ms: ts,
                out_ms: -1,
                agreeToOfferInfo: true
            }, {
                cafe: 'ediya',
                phone: '01034345656',
                in_ms: ts + 1,
                out_ms: -1,
                agreeToOfferInfo: true
            }
        ];

        for (let [i, io] of ios.entries()) {
            io.key = this.generateKey(context, io.phone);
            await context.stub.putState(io.key, stateValue(io));
            console.log(`added item:`);
            console.log(io);
            console.log();
        }
        console.log('initialized');
    }

    async getIOs(context: Context) {
        const startKey = '';
        const endKey = '';
        const results: IO[] = [];

        for await (const {key, value} of context.stub.getStateByRange(startKey, endKey)) {
            const strValue = Buffer.from(value).toString('utf8');
            let record: IO;
            try {
                record = JSON.parse(strValue);
                record.key = key;
            } catch(err) {
                console.log(err);
                record = new IO();
                record.key = key;
            }
            results.push(record);
        }
        return results;
    }

    async getIO(context: Context, phone: string) {
        const byteItem = await context.stub.getState(phone);
        if ( !byteItem || byteItem.length === 0 ) {
            throw new Error(`error on loading IO '${phone}'`);
        }
        try {
            const IO = <IO> JSON.parse( byteItem.toString() );
            return IO;

        } catch(err) {
            console.log(err);
            return undefined;
        }
    }

    async checkDisobeyed(context: Context) {
        const ts = context.stub.getTxTimestamp().seconds.low;
        const res = context.stub.getQueryResult(JSON.stringify({
            selector: {
                $and: [
                    {
                        out_ms: { $lt: 0 },
                    }, {
                        in_ms: { $lt: ts - (60 * 60 * 1000) }
                    }
                ]
            }
        }));
        const disobyeds: IO[] = [];
        for await (const {key, value} of res) {
            disobyeds.push(toItem(value));
        }
        console.log(`${disobyeds.length} customer(s) existing`);
        return disobyeds;
    }

    // if agreed to offer informations, register a customer with a phone number
    // record time as timestamp (millisecond)
    async gettingIn(context: Context, cafe: string, phone: string, agreeToOfferInfo: boolean) {
        if ( !agreeToOfferInfo ) {
            console.log('not available without agreeing to offer the information');
            return;
        }
        try {
            const io: IO = {
                key: this.generateKey(context, phone),
                cafe: cafe,
                phone: phone,
                in_ms: context.stub.getTxTimestamp().seconds.low,
                out_ms: -1,
                agreeToOfferInfo: agreeToOfferInfo
            };
            await context.stub.putState(io.key, stateValue(io));
            console.log('new IO generated');

        } catch(err) {
            console.log(err);
        }
    }

    async gettingOut(context: Context, phone: string) {
        try {
            const res = context.stub.getQueryResult(JSON.stringify({
                selector: {
                    phone: phone
                },
                limit: 1
            }));
            if ( !res ) throw 'could not find the given phone number';
            for await (const {key, value} of res) {
                const io = toItem(value);
                io.out_ms = context.stub.getTxTimestamp().seconds.low;

                if ( io.out_ms - io.in_ms > 60 * 60 * 1000 ) {
                    console.log(`the customer '${io.phone}' stayed in the cafe '${io.cafe}' over 1 hour`);
                }
                await context.stub.putState(io.key, stateValue(io));
                return;
            }

        } catch(err) {
            console.log(err);
        }
    }

    async editIO(context: Context, key: string, editItem: any) {
        const byteItem = await context.stub.getState(key);
        if ( !byteItem || byteItem.length === 0 ) {
            throw new Error(`IO '${key}' does not exist`);
        }

        try {
            const io = await getItem(context, key);
            if ( !io ) {
                console.log('could not get the item');
                return;
            }
            Object.keys(editItem).map(col => {
                io[col] = editItem[col];
            });
            await context.stub.putState(key, stateValue(io));

        } catch(err) {
            console.log(err);
        }
    }

    async delete(context: Context, key: string) {
        try {
            await context.stub.deleteState(key);
            console.log(`IO '${key}' successfully deleted`);
        } catch(err) {
            console.log(err);
        }
    }

    private generateKey(context: Context, phone: string) {
        const ts = context.stub.getTxTimestamp().seconds.low;
        return `C-${phone.substring(3)}-${ts}`;
    }

}

