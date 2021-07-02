import { Context } from "fabric-contract-api";

export function stateValue(value: any) {
    return Buffer.from(JSON.stringify(value));
}

export function toItem(item: Uint8Array) {
    return JSON.parse(item.toString());
}

export function dateFormat(date: Date) {
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    return `${year}-${month}-${day}`;
}
