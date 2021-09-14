export class Record {
    key?: string;
    car_num: string;
    timestamp: number;
    tollgate: string;
    money: number;
}

export class Car {
    key?: string;
    car_num: string;    // can be a key
    car_type: string;
    car_name: string;
    owner: string;
}

export class Driver {
    key?: string;
    phone: string;
    charged: number;
}
