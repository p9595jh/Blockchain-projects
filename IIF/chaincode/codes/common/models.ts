abstract class Abstract {
    key: string;

    abstract representedAs(): string;
    abstract keyField(): string;

    genKey() {
        this.key = `${this.representedAs()}-${this[this.keyField()]}`;
        return this.key;
    }
}

export class Constructor extends Abstract {
    id: string;
    type: string;   // ga or exclusive
    company: number;

    representedAs() {
        return 'CNS';
    }

    keyField() {
        return 'id';
    }
}

export abstract class Company extends Abstract {
    code: number;
    name: string;
    found: string;

    keyField() {
        return 'code';
    }
}

export class InsuranceCompany extends Company {
    representedAs() {
        return 'CMP';
    }
}

export class Ga extends Company {
    representedAs() {
        return 'GAC';
    }
}

export class FeeData extends Abstract {
    date: string;
    num: string;
    companyCode: number;
    product: string;
    fee: number;

    representedAs() {
        return 'FEE';
    }

    keyField() {
        return 'num';
    }
}

export class Customer extends Abstract {
    id: string;
    insurances: number[];

    representedAs() {
        return 'CST';
    }

    keyField() {
        return 'id';
    }
}

export class Insurance extends Abstract {
    id: string;
    name: string;
    company: number;

    representedAs() {
        return 'INS';
    }

    keyField() {
        return 'id';
    }
}
