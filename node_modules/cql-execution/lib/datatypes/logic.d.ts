export declare class ThreeValuedLogic {
    static and(...val: (boolean | null)[]): boolean | null;
    static or(...val: (boolean | null)[]): boolean | null;
    static xor(...val: (boolean | null)[]): boolean | null;
    static not(val: boolean | null): boolean | null;
}
