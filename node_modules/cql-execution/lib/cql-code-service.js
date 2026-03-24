"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CodeService = void 0;
const datatypes_1 = require("./datatypes/datatypes");
class CodeService {
    constructor(valueSetsJson = {}) {
        this.valueSets = {};
        for (const oid in valueSetsJson) {
            this.valueSets[oid] = {};
            for (const version in valueSetsJson[oid]) {
                const codes = valueSetsJson[oid][version].map((code) => new datatypes_1.Code(code.code, code.system, code.version));
                this.valueSets[oid][version] = new datatypes_1.ValueSet(oid, version, codes);
            }
        }
    }
    findValueSetsByOid(oid) {
        return this.valueSets[oid] ? Object.values(this.valueSets[oid]) : [];
    }
    findValueSet(oid, version) {
        if (version != null) {
            return this.valueSets[oid] != null ? this.valueSets[oid][version] : null;
        }
        else {
            const results = this.findValueSetsByOid(oid);
            if (results.length === 0) {
                return null;
            }
            else {
                return results.reduce((a, b) => {
                    if (a.version > b.version) {
                        return a;
                    }
                    else {
                        return b;
                    }
                });
            }
        }
    }
}
exports.CodeService = CodeService;
//# sourceMappingURL=cql-code-service.js.map