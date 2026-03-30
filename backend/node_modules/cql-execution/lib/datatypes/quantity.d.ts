export declare class Quantity {
    value: any;
    unit?: any;
    constructor(value: any, unit?: any);
    get isQuantity(): boolean;
    clone(): Quantity;
    toString(): string;
    sameOrBefore(other: any): boolean | null | undefined;
    sameOrAfter(other: any): boolean | null | undefined;
    after(other: any): boolean | null | undefined;
    before(other: any): boolean | null | undefined;
    equals(other: any): boolean | null | undefined;
    convertUnit(toUnit: any): Quantity;
    dividedBy(other: any): Quantity | null;
    multiplyBy(other: any): Quantity | null;
}
export declare function parseQuantity(str: string): Quantity | null;
export declare function doAddition(a: any, b: any): any;
export declare function doSubtraction(a: any, b: any): any;
export declare function doDivision(a: any, b: any): any;
export declare function doMultiplication(a: any, b: any): any;
