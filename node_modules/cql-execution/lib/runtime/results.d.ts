export declare class Results {
    patientResults: any;
    unfilteredResults: any;
    localIdPatientResultsMap: any;
    patientEvaluatedRecords: any;
    constructor();
    get evaluatedRecords(): never[];
    recordPatientResults(patient_ctx: any, resultMap: any): void;
    recordUnfilteredResults(resultMap: any): void;
}
