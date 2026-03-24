export declare function checkUnit(unit: any, allowEmptyUnits?: boolean, allowCQLDateUnits?: boolean): any;
export declare function convertUnit(fromVal: any, fromUnit: any, toUnit: any, adjustPrecision?: boolean): string | number | undefined;
export declare function normalizeUnitsWhenPossible(val1: any, unit1: any, val2: any, unit2: any): any[];
export declare function convertToCQLDateUnit(unit: any): any;
export declare function compareUnits(unit1: any, unit2: any): 1 | 0 | -1 | null;
export declare function getProductOfUnits(unit1: any, unit2: any): any;
export declare function getQuotientOfUnits(unit1: any, unit2: any): any;
