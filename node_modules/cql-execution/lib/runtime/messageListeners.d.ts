export declare class NullMessageListener {
    onMessage(_source: any, _code: string, _severity: string, _message: string): void;
}
export declare class ConsoleMessageListener {
    logSourceOnTrace: boolean;
    constructor(logSourceOnTrace?: boolean);
    onMessage(source: any, code: string, severity: string, message: string): void;
}
export declare type MessageListener = NullMessageListener | ConsoleMessageListener;
