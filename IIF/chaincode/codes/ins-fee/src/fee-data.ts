export class FeeData {
    key?: string;
    // YYYY-MM-dd
    date: string;
    // G-{timestamp}-{random value (0~999)}
    // if edited, {existing key}-{sequence}
    num: string;
    // company code table is needed
    companyCode: string;
    // name of the product
    product: string;
    // its fee
    fee: number;
}
