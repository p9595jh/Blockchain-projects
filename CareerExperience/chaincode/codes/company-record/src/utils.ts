export function stateValue(value: any) {
    return Buffer.from(JSON.stringify(value));
}

export function toItem(item: Uint8Array) {
    return JSON.parse(item.toString());
}

export function formatDate(ts: number) {
    const date = new Date(ts);
    return `${date.getFullYear()}${(date.getMonth() + 1).toString().padStart(2, '0')}${date.getDate().toString().padStart(2, '0')}`;
}
