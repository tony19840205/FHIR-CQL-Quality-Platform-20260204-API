import { ValueSet } from './datatypes/datatypes';
import { TerminologyProvider, ValueSetDictionary, ValueSetObject } from './types';
export declare class CodeService implements TerminologyProvider {
    valueSets: ValueSetObject;
    constructor(valueSetsJson?: ValueSetDictionary);
    findValueSetsByOid(oid: string): ValueSet[];
    findValueSet(oid: string, version?: string): ValueSet | null;
}
