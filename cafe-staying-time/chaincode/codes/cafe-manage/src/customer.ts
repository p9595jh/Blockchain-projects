// this is considered to apply but did not

export class Customer {
    phone: string;
    agreeToOfferInfo: boolean;
    disobey: number;

    public constructor(phone: string, agreeToOfferInfo: boolean) {
        this.phone = phone;
        this.agreeToOfferInfo = (agreeToOfferInfo == true);
        this.disobey = 0;
    }
}
