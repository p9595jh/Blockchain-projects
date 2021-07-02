import { Context, Contract } from "fabric-contract-api";
import { Record, Car, Driver } from "./record";

export class Tollgate extends Contract {

    private rand_int(min: number, max: number) {
        return Math.floor( Math.random() * (max - min + 1) ) + min;
    }

    private generateCarNum() {
        const first = this.rand_int(10, 999);
        const letter = String.fromCharCode(this.rand_int(65, 90));
        const last = this.rand_int(1000, 9999);
        return `${first}${letter}${last}`;
    }

    private generatePhone() {
        return `010${this.rand_int(1000, 9999)}${this.rand_int(1000, 9999)}`;
    }

    private getMoney(type: string) {
        switch (type) {
            case 'small': return 600;
            case 'compact': return 1000;
            case 'middle': return 1400;
            case 'large': return 1800;
            case 'big': return 2200;
            case 'SUV': return 2200;
            default: return 0;
        }
    }

    async initLedger(context: Context) {
        console.log('initializing the chaincode');

        const cars = [
            {
                name: 'K3',
                type: 'compact'
            }, {
                name: 'K5',
                type: 'middle'
            }, {
                name: 'K7',
                type: 'large'
            }, {
                name: 'K9',
                type: 'big'
            }, {
                name: 'G70',
                type: 'large'
            }, {
                name: 'GV80',
                type: 'SUV'
            }, {
                name: 'SM3',
                type: 'compact'
            }, {
                name: 'SM7',
                type: 'large'
            }, {
                name: 'Morning',
                type: 'small'
            }
        ];

        const people: string[] = [];
        for (let i=0; i<cars.length; i++) people.push(this.generatePhone());

        const ts = context.stub.getTxTimestamp().seconds.low;
        for (let [i, item] of cars.entries()) {
            const car: Car = {
                car_num: this.generateCarNum(),
                car_name: item.name,
                car_type: item.type,
                owner: people[i]
            };
            car.key = car.car_num;
            await context.stub.putState(car.key, Buffer.from(JSON.stringify(car)));

            const driver: Driver = {
                key: car.owner,
                phone: car.owner,
                charged: this.rand_int(0, 100000)
            };
            await context.stub.putState(driver.key, Buffer.from(JSON.stringify(driver)));

            const record: Record = {
                key: 'ABC-' + ts,
                car_num: car.car_num,
                timestamp: ts,
                tollgate: 'ABC-IC',
                money: this.getMoney(car.car_type)
            };
            await context.stub.putState(record.key, Buffer.from(JSON.stringify(record)));
        }

        console.log('initialized');
    }

    async charge(context: Context, car_num: string, tollgate: string) {
        try {
            const car = await this.getCar(context, car_num);
            const driver = await this.getDriver(context, car.owner);

            driver.charged += this.getMoney(car.car_type);
            await context.stub.putState(driver.key, Buffer.from(JSON.stringify(driver)));

            const ts = context.stub.getTxTimestamp().seconds.low;
            const record: Record = {
                key: tollgate + '-' + ts,
                car_num: car_num,
                timestamp: ts,
                tollgate: tollgate + '-IC',
                money: this.getMoney(car.car_type)
            };
            await context.stub.putState(record.key, Buffer.from(JSON.stringify(record)));

            console.log(`charged`);

        } catch(err) {
            console.log(err);
            return undefined;
        }
    }

    async getCar(context: Context, key: string) {
        const byteItem = await context.stub.getState(key);
        if ( !byteItem || byteItem.length === 0 ) {
            throw new Error(`error on loading thing '${key}'`);
        }
        try {
            const thing = <Car> JSON.parse( byteItem.toString() );
            return thing;

        } catch(err) {
            console.log(err);
            return undefined;
        }
    }

    async getDriver(context: Context, key: string) {
        const byteItem = await context.stub.getState(key);
        if ( !byteItem || byteItem.length === 0 ) {
            throw new Error(`error on loading thing '${key}'`);
        }
        try {
            const thing = <Driver> JSON.parse( byteItem.toString() );
            return thing;

        } catch(err) {
            console.log(err);
            return undefined;
        }
    }

    async pay(context: Context, phone: string, payed: number) {
        const driver = await this.getDriver(context, phone);
        driver.charged -= payed;
        await context.stub.putState(driver.key, Buffer.from(JSON.stringify(driver)));
    }

}

