import * as DT from './datatypes/datatypes';
import { DataProvider, NamedTypeSpecifier, PatientObject, RecordObject } from './types';
export declare class Record implements RecordObject {
    json: any;
    id: string;
    constructor(json: any);
    _is(typeSpecifier: NamedTypeSpecifier): boolean;
    _typeHierarchy(): NamedTypeSpecifier[];
    _recursiveGet(field: any): any;
    get(field: any): any;
    getId(): string;
    getDate(field: any): DT.DateTime | null;
    getInterval(field: any): DT.Interval | undefined;
    getDateOrInterval(field: any): DT.DateTime | DT.Interval | null | undefined;
    getCode(field: any): DT.Code | undefined;
}
export declare class Patient extends Record implements PatientObject {
    name?: string;
    gender?: string;
    birthDate?: DT.DateTime | null;
    records: {
        [recordType: string]: Record[];
    };
    constructor(json: any);
    findRecords(profile: string | null): Record[];
}
export declare class PatientSource implements DataProvider {
    patients: any[];
    current?: Patient;
    constructor(patients: any);
    currentPatient(): Patient | undefined;
    nextPatient(): Patient | undefined;
}
