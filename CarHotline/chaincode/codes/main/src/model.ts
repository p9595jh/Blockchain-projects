export class Car {
    key?: string;
    num: string;
    type: string;
    color: string;
    owner: number;
    conversations: string[];
}

export class Record {
    key?: string;
    timestamp: number;
    channelOwner: number;
    participant: number;
}

export class Report {
    key?: string;
    timestamp: number;
    recordId: string;
    description: string;
    handled: number;
    result: string;
}
