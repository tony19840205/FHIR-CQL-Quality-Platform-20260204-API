/**
 * A custom error that holds additional information and a more explicit message
 * to simplify tracking down errors that occur during execution
 */
export declare class AnnotatedError extends Error {
    expressionName: string;
    libraryName: string;
    localId?: string | undefined;
    locator?: string | undefined;
    cause: Error;
    constructor(originalError: Error, expressionName: string, libraryName: string, localId?: string | undefined, locator?: string | undefined);
}
