"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ConsoleMessageListener = exports.NullMessageListener = void 0;
class NullMessageListener {
    onMessage(_source, _code, _severity, _message) {
        // do nothing
    }
}
exports.NullMessageListener = NullMessageListener;
class ConsoleMessageListener {
    constructor(logSourceOnTrace = false) {
        this.logSourceOnTrace = logSourceOnTrace;
    }
    onMessage(source, code, severity, message) {
        // eslint-disable-next-line no-console
        const print = severity === 'Error' ? console.error : console.log;
        let content = `${severity}: [${code}] ${message}`;
        if (severity === 'Trace' && this.logSourceOnTrace) {
            content += `\n<<<<< SOURCE:\n${JSON.stringify(source)}\n>>>>>`;
        }
        print(content);
    }
}
exports.ConsoleMessageListener = ConsoleMessageListener;
//# sourceMappingURL=messageListeners.js.map