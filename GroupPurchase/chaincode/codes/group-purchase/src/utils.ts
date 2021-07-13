export function stateValue(value: any) {
    return Buffer.from(JSON.stringify(value));
}

export function toItem(item: Uint8Array) {
    return JSON.parse(item.toString());
}
