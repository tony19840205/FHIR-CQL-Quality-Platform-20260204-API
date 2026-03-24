import { Parameter } from '../types/runtime.types';
export declare class Library {
    source: any;
    usings: any;
    parameters: Parameter;
    codesystems: any;
    valuesets: any;
    codes: any;
    concepts: any;
    expressions: any;
    functions: any;
    includes: any;
    constructor(json: any, libraryManager?: any);
    getFunction(identifier: string): any;
    get(identifier: string): any;
    getValueSet(identifier: string, libraryName: string): any;
    getCodeSystem(identifier: string): any;
    getCode(identifier: string): any;
    getConcept(identifier: string): any;
    getParameter(name: string): any;
}
