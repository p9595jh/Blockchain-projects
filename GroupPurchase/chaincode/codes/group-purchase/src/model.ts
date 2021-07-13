export class Seller {
    id: number;
    sellingItem: number;
}

export class Item {
    category: string;
    name: string;
    id: number;
    stock: number;
    price: number;
}

export class Customer {
    id: number;
    numberOfBought: number;
}

export class Deal {
    item: number;
    date: string;
    seller: number;
    customers: number[];
}
