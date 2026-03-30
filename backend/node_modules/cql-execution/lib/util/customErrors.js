"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AnnotatedError = void 0;
/**
 * A custom error that holds additional information and a more explicit message
 * to simplify tracking down errors that occur during execution
 */
class AnnotatedError extends Error {
    constructor(originalError, expressionName, libraryName, localId, locator) {
        super(`Encountered unexpected error during execution.\n\n\tError Message:\t${originalError.message}\n\tCQL Library:\t${libraryName}\n\tExpression:\t${expressionName}${localId ? `\n\tELM Local ID:\t${localId}` : ''}${locator ? `\n\tCQL Locator:\t${locator}` : ''}\n`);
        this.expressionName = expressionName;
        this.libraryName = libraryName;
        this.localId = localId;
        this.locator = locator;
        this.cause = originalError;
    }
}
exports.AnnotatedError = AnnotatedError;
//# sourceMappingURL=customErrors.js.map