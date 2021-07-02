import { Context, Contract } from "fabric-contract-api";
import { Stock } from "./car";

export class TestCC extends Contract {

    public async initLedger(context: Context) {
        console.log('initializing the chaincode');
        const stocks: Stock[] = [
            {
                s: 's1',
                // n: Math.floor( Math.random() * 100 )
                n: 10
            }, {
                s: 's2',
                // n: Math.floor( Math.random() * 100 )
                n: 20
            }, {
                s: 's3',
                // n: Math.floor( Math.random() * 100 )
                n: 30
            }
        ];

        for (let [i, stock] of stocks.entries()) {
            stock.key = this.generateKey(context) + i;
            await context.stub.putState(stock.key, Buffer.from(JSON.stringify(stock)));
            console.log(`added item:`);
            console.log(stock);
            console.log();
        }
        console.log('initialized');
    }

    public async getStocks(context: Context) {
        const startKey = '';
        const endKey = '';
        const results: Stock[] = [];

        for await (const {key, value} of context.stub.getStateByRange(startKey, endKey)) {
            const strValue = Buffer.from(value).toString('utf8');
            let record: Stock;
            try {
                record = JSON.parse(strValue);
                record.key = key;
            } catch(err) {
                console.log(err);
                record = new Stock();
                record.key = key;
            }
            results.push(record);
        }
        return results;
    }

    public async getStock(context: Context, key: string) {
        const byteItem = await context.stub.getState(key);
        if ( !byteItem || byteItem.length === 0 ) {
            throw new Error(`error on loading stock '${key}'`);
        }
        try {
            const stock = <Stock> JSON.parse( byteItem.toString() );
            return stock;

        } catch(err) {
            console.log(err);
            return undefined;
        }
    }

    public async test(context: Context, a: any) {
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

    // public async createStock(context: Context, stock: Stock, key: string) {
    //     try {
    //         // if ( !key ) key = `${this.generateKey()}`;
    //         await context.stub.putState(key, Buffer.from(JSON.stringify(stock)));
    //         console.log(`new stock generated`);

    //     } catch(err) {
    //         console.log(err);
    //         return undefined;
    //     }
    // }

    public async createStock(context: Context, s: string, n: number) {
        try {
            const stock: Stock = {
                key: this.generateKey(context),
                s: s,
                n: n
            };
            await context.stub.putState(stock.key, Buffer.from(JSON.stringify(stock)));
            console.log('new stock generated');

        } catch(err) {
            console.log(err);
            return undefined;
        }
    }

    // public async editStock(context: Context, key: string, editItem: any) {
    //     const byteItem = await context.stub.getState(key);
    //     if ( !byteItem || byteItem.length === 0 ) {
    //         throw new Error(`stock '${key}' does not exist`);
    //     }

    //     try {
    //         const stock = <Stock> JSON.parse(byteItem.toString());
    //         Object.keys(editItem).map(col => {
    //             stock[col] = editItem[col];
    //         });
    //         await context.stub.putState(key, Buffer.from(JSON.stringify(stock)));

    //     } catch(err) {
    //         console.log(err);
    //         return undefined;
    //     }
    // }

    public async delete(context: Context, key: string) {
        try {
            await context.stub.deleteState(key);
            console.log(`stock '${key}' successfully deleted`);
        } catch(err) {
            console.log(err);
        }
    }

    private generateKey(context: Context) {
        return 'STK' + context.stub.getTxTimestamp().seconds.low;
    }

}

