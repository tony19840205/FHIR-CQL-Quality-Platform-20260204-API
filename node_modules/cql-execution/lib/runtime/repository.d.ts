import { Library } from '../elm/library';
export declare class Repository {
    data: any;
    libraries: any[];
    constructor(data: any);
    resolve(path: string, version?: string): Library | undefined;
}
