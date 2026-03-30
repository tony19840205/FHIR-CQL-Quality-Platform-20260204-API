export declare class Code {
    code: string;
    system?: string | undefined;
    version?: string | undefined;
    display?: string | undefined;
    constructor(code: string, system?: string | undefined, version?: string | undefined, display?: string | undefined);
    get isCode(): boolean;
    hasMatch(code: any): any;
}
export declare class Concept {
    codes: any[];
    display?: string | undefined;
    constructor(codes: any[], display?: string | undefined);
    get isConcept(): boolean;
    hasMatch(code: any): any;
}
export declare class ValueSet {
    oid: string;
    version?: string | undefined;
    codes: any[];
    constructor(oid: string, version?: string | undefined, codes?: any[]);
    get isValueSet(): boolean;
    hasMatch(code: any): any;
}
export declare class CodeSystem {
    id: string;
    version?: string | undefined;
    constructor(id: string, version?: string | undefined);
}
