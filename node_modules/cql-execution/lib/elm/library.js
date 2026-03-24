"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Library = void 0;
const expressions_1 = require("./expressions");
class Library {
    constructor(json, libraryManager) {
        this.source = json;
        // usings
        const usingDefs = (json.library.usings && json.library.usings.def) || [];
        this.usings = usingDefs
            .filter((u) => u.localIdentifier !== 'System')
            .map((u) => {
            return { name: u.localIdentifier, version: u.version };
        });
        // parameters
        const paramDefs = (json.library.parameters && json.library.parameters.def) || [];
        this.parameters = {};
        for (const param of paramDefs) {
            this.parameters[param.name] = new expressions_1.ParameterDef(param);
        }
        // code systems
        const csDefs = (json.library.codeSystems && json.library.codeSystems.def) || [];
        this.codesystems = {};
        for (const codesystem of csDefs) {
            this.codesystems[codesystem.name] = new expressions_1.CodeSystemDef(codesystem);
        }
        // value sets
        const vsDefs = (json.library.valueSets && json.library.valueSets.def) || [];
        this.valuesets = {};
        for (const valueset of vsDefs) {
            this.valuesets[valueset.name] = new expressions_1.ValueSetDef(valueset);
        }
        // codes
        const codeDefs = (json.library.codes && json.library.codes.def) || [];
        this.codes = {};
        for (const code of codeDefs) {
            this.codes[code.name] = new expressions_1.CodeDef(code);
        }
        // concepts
        const conceptDefs = (json.library.concepts && json.library.concepts.def) || [];
        this.concepts = {};
        for (const concept of conceptDefs) {
            this.concepts[concept.name] = new expressions_1.ConceptDef(concept);
        }
        // expressions
        const exprDefs = (json.library.statements && json.library.statements.def) || [];
        this.expressions = {};
        this.functions = {};
        for (const expr of exprDefs) {
            if (expr.type === 'FunctionDef') {
                if (!this.functions[expr.name]) {
                    this.functions[expr.name] = [];
                }
                this.functions[expr.name].push(new expressions_1.FunctionDef(expr));
            }
            else {
                this.expressions[expr.name] = new expressions_1.ExpressionDef(expr);
            }
        }
        // includes
        const inclDefs = (json.library.includes && json.library.includes.def) || [];
        this.includes = {};
        for (const incl of inclDefs) {
            if (libraryManager) {
                this.includes[incl.localIdentifier] = libraryManager.resolve(incl.path, incl.version);
            }
        }
        // Include codesystems from includes
        for (const iProperty in this.includes) {
            if (this.includes[iProperty] && this.includes[iProperty].codesystems) {
                for (const csProperty in this.includes[iProperty].codesystems) {
                    this.codesystems[csProperty] = this.includes[iProperty].codesystems[csProperty];
                }
            }
        }
    }
    getFunction(identifier) {
        return this.functions[identifier];
    }
    get(identifier) {
        return (this.expressions[identifier] || this.includes[identifier] || this.getFunction(identifier));
    }
    getValueSet(identifier, libraryName) {
        if (this.valuesets[identifier] != null) {
            return this.valuesets[identifier];
        }
        return this.includes[libraryName] != null
            ? this.includes[libraryName].valuesets[identifier]
            : undefined;
    }
    getCodeSystem(identifier) {
        return this.codesystems[identifier];
    }
    getCode(identifier) {
        return this.codes[identifier];
    }
    getConcept(identifier) {
        return this.concepts[identifier];
    }
    getParameter(name) {
        return this.parameters[name];
    }
}
exports.Library = Library;
//# sourceMappingURL=library.js.map