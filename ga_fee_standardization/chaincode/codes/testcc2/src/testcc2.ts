import { Context, Contract } from "fabric-contract-api";
import { Thing } from "./thing";

export class TestCC2 extends Contract {

    async initLedger(context: Context) {
        console.log('initializing the chaincode');
        // const things: Thing[] = [];
        // for (let i=0; i<10; i++) things.push(this.createData());

        // for (let [i, thing] of things.entries()) {
        //     await context.stub.putState(`${this.generateKey(i)}`, Buffer.from(JSON.stringify(thing)));
        //     console.log(`added item:`);
        //     console.log(thing);
        //     console.log();
        // }

        const ts = context.stub.getTxTimestamp().seconds.low;
        for (let i=0; i<3; i++) {
            const t: Thing = {
                a: i.toString(16),
                b: i,
                c: i % 2 == 0
            };
            // t.key = this.generateKey(i);
            t.key = 'THI' + (ts + i);
            await context.stub.putState(t.key, Buffer.from(JSON.stringify(t)));
            console.log(`added item:`);
            console.log(t);
            console.log();
        }
        
        const c: Thing = {"a":"asdf","b":123,"c":true,"key":"THI1616249563"};
        await context.stub.putState(c.key, Buffer.from(JSON.stringify(c)));

        console.log('initialized');
    }

    async getThings(context: Context) {
        const startKey = '';
        const endKey = '';
        const results: Thing[] = [];

        for await (const {key, value} of context.stub.getStateByRange(startKey, endKey)) {
            const strValue = Buffer.from(value).toString('utf8');
            let record: Thing;
            try {
                record = JSON.parse(strValue);
                record.key = key;
            } catch(err) {
                console.log(err);
                record = new Thing();
                record.key = key;
            }
            results.push(record);
        }
        return results;
    }

    async getThing(context: Context, key: string) {
        const byteItem = await context.stub.getState(key);
        if ( !byteItem || byteItem.length === 0 ) {
            throw new Error(`error on loading thing '${key}'`);
        }
        try {
            const thing = <Thing> JSON.parse( byteItem.toString() );
            return thing;

        } catch(err) {
            console.log(err);
            return undefined;
        }
    }

    async test(context: Context, a: any) {
        console.log(context.stub.getTxTimestamp());
        console.log(a);
        // newLogger('');
        // const c = newLogger('asdf');
        // c.debug(context.stub.getTxTimestamp());
        // c.info(a);
        return {
            a: a,
            type: typeof a,
            t: context.stub.getTxTimestamp()
        };
    }

    async createThing(context: Context, s: string) {
        try {
            const thing: Thing = JSON.parse(s);
            // if ( !thing.key ) thing.key = this.generateKey(this.ID++);
            console.log(thing);
            thing.key = 'THI' + context.stub.getTxTimestamp().seconds.low;
            await context.stub.putState(thing.key, Buffer.from(JSON.stringify(thing)));
            console.log(`new thing generated`);
            return thing;

        } catch(err) {
            console.log(err);
            return undefined;
        }
    }

    async create(ctx: Context, a: string, b: string, c: string) {
        const thing: Thing = {
            a: a,
            b: parseInt(b),
            c: Boolean(c)
        };
        console.log(thing);
        const key = 'THI' + ctx.stub.getTxTimestamp().seconds.low;
        thing.key = key;
        await ctx.stub.putState(key, Buffer.from(JSON.stringify(thing)));
        console.info('thing created');
        return thing;
    }

    async editThing(context: Context, key: string, editItem: string) {
        const byteItem = await context.stub.getState(key);
        if ( !byteItem || byteItem.length === 0 ) {
            throw new Error(`thing '${key}' does not exist`);
        }

        try {
            const thing = <Thing> JSON.parse(byteItem.toString());
            const edit = <Thing> JSON.parse(editItem);
            Object.keys(edit).map(col => {
                thing[col] = edit[col];
            });
            await context.stub.putState(key, Buffer.from(JSON.stringify(thing)));

        } catch(err) {
            console.log(err);
            return undefined;
        }
    }

    async delete(context: Context, key: string) {
        try {
            await context.stub.deleteState(key);
            console.log(`thing '${key}' successfully deleted`);
        } catch(err) {
            console.log(err);
        }
    }

    private generateKey(n: number) {
        // const date = new Date();
        // const y = String.fromCharCode( date.getFullYear() % 26 + 65 );
        // const m = String.fromCharCode( date.getMonth() + 65 );
        // const d = String.fromCharCode( date.getDate() % 26 + 65 );
        // const h = date.getTime().toString(16);
        // const s = h.substring(h.length - 7).toUpperCase();
        // return y + m + d + s;
        // return 'THI' + this.ID++;
        return 'THI' + n;
    }

}

