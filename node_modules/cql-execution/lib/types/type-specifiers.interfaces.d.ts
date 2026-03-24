export declare type AnyTypeSpecifier = NamedTypeSpecifier | IntervalTypeSpecifier | ListTypeSpecifier | TupleTypeSpecifier | ChoiceTypeSpecifier;
export interface TypeSpecifier {
    type: string;
    localId?: string;
}
export interface NamedTypeSpecifier extends TypeSpecifier {
    type: 'NamedTypeSpecifier';
    name: string;
}
export interface IntervalTypeSpecifier extends TypeSpecifier {
    type: 'IntervalTypeSpecifier';
    pointType: AnyTypeSpecifier;
}
export interface ListTypeSpecifier extends TypeSpecifier {
    type: 'ListTypeSpecifier';
    elementType: AnyTypeSpecifier;
}
export interface TupleElementDefinition {
    localId?: string;
    name: string;
    elementType: AnyTypeSpecifier;
}
export interface TupleTypeSpecifier extends TypeSpecifier {
    type: 'TupleTypeSpecifier';
    element?: TupleElementDefinition[];
}
export interface ChoiceTypeSpecifier extends TypeSpecifier {
    type: 'ChoiceTypeSpecifier';
    choice?: AnyTypeSpecifier[];
}
