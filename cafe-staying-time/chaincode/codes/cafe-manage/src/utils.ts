import { Context } from "fabric-contract-api";
import { IO } from "./io";

export function stateValue(value: any) {
    return Buffer.from(JSON.stringify(value));
}

export function toItem(item: Uint8Array) {
    return <IO> JSON.parse(item.toString());
}

export async function getItem(context: Context, key: string) {
    try {
        const byteItem = await context.stub.getState(key);
        if ( !byteItem || byteItem.length === 0 ) {
            return undefined;
        }
        return toItem(byteItem);

    } catch(err) {
        console.log(err);
        return undefined;
    }
}
