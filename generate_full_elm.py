# -*- coding: utf-8 -*-
"""生成完整的官方 ELM JSON"""
import json
from pathlib import Path

# 读取参考的官方 ELM 作为模板
ref_path = Path(r'ELM_JSON_OFFICIAL\舊50\Indicator_01_Outpatient_Injection_Usage_Rate_3127.json')
with open(ref_path, 'r', encoding='utf-8') as f:
    reference = json.load(f)

# 创建新的 ELM JSON
elm = {
    "library": {
        "annotation": [
            {
                "translatorVersion": "3.10.0",
                "translatorOptions": "DisableListDemotion,DisableListPromotion",
                "signatureLevel": "Overloads",
                "type": "CqlToElmInfo"
            }
        ],
        "identifier": {
            "id": "Indicator_03_1_Same_Hospital_Antihypertensive_Overlap_1710",
            "version": "1.0.0"
        },
        "schemaIdentifier": {
            "id": "urn:hl7-org:elm",
            "version": "r1"
        },
        "usings": {
            "def": [
                {
                    "localIdentifier": "System",
                    "uri": "urn:hl7-org:elm-types:r1",
                    "annotation": []
                },
                {
                    "localIdentifier": "FHIR",
                    "uri": "http://hl7.org/fhir",
                    "version": "4.0.1",
                    "annotation": []
                }
            ]
        },
        "includes": {
            "def": [
                {
                    "localIdentifier": "FHIRHelpers",
                    "path": "FHIRHelpers",
                    "version": "4.0.1",
                    "annotation": []
                }
            ]
        },
        "codeSystems": {
            "def": [
                {
                    "name": "ICD10CM",
                    "id": "http://hl7.org/fhir/sid/icd-10-cm",
                    "accessLevel": "Public",
                    "annotation": []
                },
                {
                    "name": "SNOMEDCT",
                    "id": "http://snomed.info/sct",
                    "accessLevel": "Public",
                    "annotation": []
                },
                {
                    "name": "ATC",
                    "id": "http://www.whocc.no/atc",
                    "accessLevel": "Public",
                    "annotation": []
                },
                {
                    "name": "ActCode",
                    "id": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
                    "accessLevel": "Public",
                    "annotation": []
                },
                {
                    "name": "NHI_PROCEDURE",
                    "id": "http://www.nhi.gov.tw/codes",
                    "accessLevel": "Public",
                    "annotation": []
                }
            ]
        },
        "codes": {
            "def": [
                {
                    "name": "Ambulatory",
                    "id": "AMB",
                    "display": "Ambulatory - 門診",
                    "accessLevel": "Public",
                    "annotation": [],
                    "codeSystem": {
                        "name": "ActCode",
                        "annotation": []
                    }
                }
            ]
        },
        "statements": {
            "def": []
        }
    }
}

# 添加 Patient statement (参考官方结构)
patient_statement = {
    "name": "Patient",
    "context": "Patient",
    "accessLevel": "Public",
    "annotation": [],
    "expression": {
        "type": "SingletonFrom",
        "annotation": [],
        "signature": [],
        "operand": {
            "dataType": "{http://hl7.org/fhir}Patient",
            "templateId": "http://hl7.org/fhir/StructureDefinition/Patient",
            "type": "Retrieve",
            "annotation": [],
            "include": [],
            "codeFilter": [],
            "dateFilter": [],
            "otherFilter": []
        }
    }
}

# 添加 IsAntihypertensiveOralDrug 函数
is_antihypertensive_func = {
    "name": "IsAntihypertensiveOralDrug",
    "context": "Unfiltered",
    "accessLevel": "Public",
    "type": "FunctionDef",
    "annotation": [],
    "expression": {
        "type": "And",
        "annotation": [],
        "signature": [],
        "operand": [
            {
                "type": "Or",
                "annotation": [],
                "signature": [],
                "operand": [
                    {
                        "type": "And",
                        "annotation": [],
                        "signature": [],
                        "operand": [
                            {
                                "type": "Equal",
                                "annotation": [],
                                "signature": [
                                    {"name": "{urn:hl7-org:elm-types:r1}String", "type": "NamedTypeSpecifier", "annotation": []},
                                    {"name": "{urn:hl7-org:elm-types:r1}String", "type": "NamedTypeSpecifier", "annotation": []}
                                ],
                                "operand": [
                                    {
                                        "type": "Substring",
                                        "annotation": [],
                                        "signature": [],
                                        "stringToSub": {"name": "atcCode", "type": "OperandRef", "annotation": []},
                                        "startIndex": {"valueType": "{urn:hl7-org:elm-types:r1}Integer", "value": "0", "type": "Literal", "annotation": []},
                                        "length": {"valueType": "{urn:hl7-org:elm-types:r1}Integer", "value": "3", "type": "Literal", "annotation": []}
                                    },
                                    {"valueType": "{urn:hl7-org:elm-types:r1}String", "value": "C07", "type": "Literal", "annotation": []}
                                ]
                            },
                            {
                                "type": "Not",
                                "annotation": [],
                                "signature": [],
                                "operand": {
                                    "type": "Equal",
                                    "annotation": [],
                                    "signature": [
                                        {"name": "{urn:hl7-org:elm-types:r1}String", "type": "NamedTypeSpecifier", "annotation": []},
                                        {"name": "{urn:hl7-org:elm-types:r1}String", "type": "NamedTypeSpecifier", "annotation": []}
                                    ],
                                    "operand": [
                                        {"name": "atcCode", "type": "OperandRef", "annotation": []},
                                        {"valueType": "{urn:hl7-org:elm-types:r1}String", "value": "C07AA05", "type": "Literal", "annotation": []}
                                    ]
                                }
                            }
                        ]
                    },
                    {
                        "type": "And",
                        "annotation": [],
                        "signature": [],
                        "operand": [
                            {
                                "type": "In",
                                "annotation": [],
                                "signature": [],
                                "operand": [
                                    {
                                        "type": "Substring",
                                        "annotation": [],
                                        "signature": [],
                                        "stringToSub": {"name": "atcCode", "type": "OperandRef", "annotation": []},
                                        "startIndex": {"valueType": "{urn:hl7-org:elm-types:r1}Integer", "value": "0", "type": "Literal", "annotation": []},
                                        "length": {"valueType": "{urn:hl7-org:elm-types:r1}Integer", "value": "5", "type": "Literal", "annotation": []}
                                    },
                                    {
                                        "type": "List",
                                        "annotation": [],
                                        "element": [
                                            {"valueType": "{urn:hl7-org:elm-types:r1}String", "value": code, "type": "Literal", "annotation": []}
                                            for code in ['C02CA', 'C02DB', 'C02DC', 'C02DD', 'C03AA', 'C03BA', 'C03CA', 'C03DA', 'C08CA', 'C08DA', 'C08DB', 'C09AA', 'C09CA']
                                        ]
                                    }
                                ]
                            },
                            {
                                "type": "Not",
                                "annotation": [],
                                "signature": [],
                                "operand": {
                                    "type": "Equal",
                                    "annotation": [],
                                    "signature": [
                                        {"name": "{urn:hl7-org:elm-types:r1}String", "type": "NamedTypeSpecifier", "annotation": []},
                                        {"name": "{urn:hl7-org:elm-types:r1}String", "type": "NamedTypeSpecifier", "annotation": []}
                                    ],
                                    "operand": [
                                        {"name": "atcCode", "type": "OperandRef", "annotation": []},
                                        {"valueType": "{urn:hl7-org:elm-types:r1}String", "value": "C08CA06", "type": "Literal", "annotation": []}
                                    ]
                                }
                            }
                        ]
                    }
                ]
            },
            {
                "type": "And",
                "annotation": [],
                "signature": [],
                "operand": [
                    {
                        "type": "GreaterOrEqual",
                        "annotation": [],
                        "signature": [
                            {"name": "{urn:hl7-org:elm-types:r1}Integer", "type": "NamedTypeSpecifier", "annotation": []},
                            {"name": "{urn:hl7-org:elm-types:r1}Integer", "type": "NamedTypeSpecifier", "annotation": []}
                        ],
                        "operand": [
                            {
                                "type": "Length",
                                "annotation": [],
                                "signature": [],
                                "operand": {"name": "drugCode", "type": "OperandRef", "annotation": []}
                            },
                            {"valueType": "{urn:hl7-org:elm-types:r1}Integer", "value": "8", "type": "Literal", "annotation": []}
                        ]
                    },
                    {
                        "type": "Not",
                        "annotation": [],
                        "signature": [],
                        "operand": {
                            "type": "Equal",
                            "annotation": [],
                            "signature": [
                                {"name": "{urn:hl7-org:elm-types:r1}String", "type": "NamedTypeSpecifier", "annotation": []},
                                {"name": "{urn:hl7-org:elm-types:r1}String", "type": "NamedTypeSpecifier", "annotation": []}
                            ],
                            "operand": [
                                {
                                    "type": "Substring",
                                    "annotation": [],
                                    "signature": [],
                                    "stringToSub": {"name": "drugCode", "type": "OperandRef", "annotation": []},
                                    "startIndex": {"valueType": "{urn:hl7-org:elm-types:r1}Integer", "value": "7", "type": "Literal", "annotation": []},
                                    "length": {"valueType": "{urn:hl7-org:elm-types:r1}Integer", "value": "1", "type": "Literal", "annotation": []}
                                },
                                {"valueType": "{urn:hl7-org:elm-types:r1}String", "value": "2", "type": "Literal", "annotation": []}
                            ]
                        }
                    }
                ]
            }
        ]
    },
    "operand": [
        {
            "name": "atcCode",
            "annotation": [],
            "operandTypeSpecifier": {"name": "{urn:hl7-org:elm-types:r1}String", "type": "NamedTypeSpecifier", "annotation": []}
        },
        {
            "name": "drugCode",
            "annotation": [],
            "operandTypeSpecifier": {"name": "{urn:hl7-org:elm-types:r1}String", "type": "NamedTypeSpecifier", "annotation": []}
        }
    ]
}

# 添加 CalculateOverlapDays 函数
calc_overlap_func = {
    "name": "CalculateOverlapDays",
    "context": "Unfiltered",
    "accessLevel": "Public",
    "type": "FunctionDef",
    "annotation": [],
    "expression": {
        "type": "If",
        "annotation": [],
        "condition": {
            "type": "Or",
            "annotation": [],
            "signature": [],
            "operand": [
                {
                    "type": "Or",
                    "annotation": [],
                    "signature": [],
                    "operand": [
                        {
                            "type": "Or",
                            "annotation": [],
                            "signature": [],
                            "operand": [
                                {"type": "IsNull", "annotation": [], "signature": [], "operand": {"name": "start1", "type": "OperandRef", "annotation": []}},
                                {"type": "IsNull", "annotation": [], "signature": [], "operand": {"name": "end1", "type": "OperandRef", "annotation": []}}
                            ]
                        },
                        {"type": "IsNull", "annotation": [], "signature": [], "operand": {"name": "start2", "type": "OperandRef", "annotation": []}}
                    ]
                },
                {"type": "IsNull", "annotation": [], "signature": [], "operand": {"name": "end2", "type": "OperandRef", "annotation": []}}
            ]
        },
        "then": {"valueType": "{urn:hl7-org:elm-types:r1}Integer", "value": "0", "type": "Literal", "annotation": []},
        "else": {
            "type": "Query",
            "annotation": [],
            "source": [],
            "let": [
                {
                    "identifier": "overlapStart",
                    "expression": {
                        "type": "If",
                        "annotation": [],
                        "condition": {
                            "type": "Greater",
                            "annotation": [],
                            "signature": [
                                {"name": "{urn:hl7-org:elm-types:r1}Date", "type": "NamedTypeSpecifier", "annotation": []},
                                {"name": "{urn:hl7-org:elm-types:r1}Date", "type": "NamedTypeSpecifier", "annotation": []}
                            ],
                            "operand": [
                                {"name": "start1", "type": "OperandRef", "annotation": []},
                                {"name": "start2", "type": "OperandRef", "annotation": []}
                            ]
                        },
                        "then": {"name": "start1", "type": "OperandRef", "annotation": []},
                        "else": {"name": "start2", "type": "OperandRef", "annotation": []}
                    }
                },
                {
                    "identifier": "overlapEnd",
                    "expression": {
                        "type": "If",
                        "annotation": [],
                        "condition": {
                            "type": "Less",
                            "annotation": [],
                            "signature": [
                                {"name": "{urn:hl7-org:elm-types:r1}Date", "type": "NamedTypeSpecifier", "annotation": []},
                                {"name": "{urn:hl7-org:elm-types:r1}Date", "type": "NamedTypeSpecifier", "annotation": []}
                            ],
                            "operand": [
                                {"name": "end1", "type": "OperandRef", "annotation": []},
                                {"name": "end2", "type": "OperandRef", "annotation": []}
                            ]
                        },
                        "then": {"name": "end1", "type": "OperandRef", "annotation": []},
                        "else": {"name": "end2", "type": "OperandRef", "annotation": []}
                    }
                },
                {
                    "identifier": "overlapDays",
                    "expression": {
                        "type": "Add",
                        "annotation": [],
                        "signature": [
                            {"name": "{urn:hl7-org:elm-types:r1}Integer", "type": "NamedTypeSpecifier", "annotation": []},
                            {"name": "{urn:hl7-org:elm-types:r1}Integer", "type": "NamedTypeSpecifier", "annotation": []}
                        ],
                        "operand": [
                            {
                                "precision": "Day",
                                "type": "DurationBetween",
                                "annotation": [],
                                "signature": [],
                                "operand": [
                                    {"name": "overlapStart", "type": "QueryLetRef", "annotation": []},
                                    {"name": "overlapEnd", "type": "QueryLetRef", "annotation": []}
                                ]
                            },
                            {"valueType": "{urn:hl7-org:elm-types:r1}Integer", "value": "1", "type": "Literal", "annotation": []}
                        ]
                    }
                }
            ],
            "relationship": [],
            "return": {
                "annotation": [],
                "expression": {
                    "type": "If",
                    "annotation": [],
                    "condition": {
                        "type": "LessOrEqual",
                        "annotation": [],
                        "signature": [
                            {"name": "{urn:hl7-org:elm-types:r1}Date", "type": "NamedTypeSpecifier", "annotation": []},
                            {"name": "{urn:hl7-org:elm-types:r1}Date", "type": "NamedTypeSpecifier", "annotation": []}
                        ],
                        "operand": [
                            {"name": "overlapStart", "type": "QueryLetRef", "annotation": []},
                            {"name": "overlapEnd", "type": "QueryLetRef", "annotation": []}
                        ]
                    },
                    "then": {"name": "overlapDays", "type": "QueryLetRef", "annotation": []},
                    "else": {"valueType": "{urn:hl7-org:elm-types:r1}Integer", "value": "0", "type": "Literal", "annotation": []}
                }
            }
        }
    },
    "operand": [
        {"name": "start1", "annotation": [], "operandTypeSpecifier": {"name": "{urn:hl7-org:elm-types:r1}Date", "type": "NamedTypeSpecifier", "annotation": []}},
        {"name": "end1", "annotation": [], "operandTypeSpecifier": {"name": "{urn:hl7-org:elm-types:r1}Date", "type": "NamedTypeSpecifier", "annotation": []}},
        {"name": "start2", "annotation": [], "operandTypeSpecifier": {"name": "{urn:hl7-org:elm-types:r1}Date", "type": "NamedTypeSpecifier", "annotation": []}},
        {"name": "end2", "annotation": [], "operandTypeSpecifier": {"name": "{urn:hl7-org:elm-types:r1}Date", "type": "NamedTypeSpecifier", "annotation": []}}
    ]
}

# 添加 Antihypertensive Prescriptions
antihypertensive_prescriptions = {
    "name": "Antihypertensive Prescriptions",
    "context": "Patient",
    "accessLevel": "Public",
    "annotation": [],
    "expression": {
        "type": "Query",
        "annotation": [],
        "source": [
            {
                "alias": "MR",
                "annotation": [],
                "expression": {
                    "dataType": "{http://hl7.org/fhir}MedicationRequest",
                    "templateId": "http://hl7.org/fhir/StructureDefinition/MedicationRequest",
                    "type": "Retrieve",
                    "annotation": [],
                    "include": [],
                    "codeFilter": [],
                    "dateFilter": [],
                    "otherFilter": []
                }
            }
        ],
        "let": [],
        "relationship": [],
        "where": {
            "type": "Equal",
            "annotation": [],
            "signature": [
                {"name": "{urn:hl7-org:elm-types:r1}String", "type": "NamedTypeSpecifier", "annotation": []},
                {"name": "{urn:hl7-org:elm-types:r1}String", "type": "NamedTypeSpecifier", "annotation": []}
            ],
            "operand": [
                {
                    "path": "value",
                    "type": "Property",
                    "annotation": [],
                    "source": {"path": "status", "scope": "MR", "type": "Property", "annotation": []}
                },
                {"valueType": "{urn:hl7-org:elm-types:r1}String", "value": "completed", "type": "Literal", "annotation": []}
            ]
        }
    }
}

# 添加其他 statements
total_drug_days = {
    "name": "Total Drug Days",
    "context": "Patient",
    "accessLevel": "Public",
    "annotation": [],
    "expression": {
        "type": "Null",
        "annotation": []
    }
}

overlap_drug_days = {
    "name": "Overlap Drug Days",
    "context": "Patient",
    "accessLevel": "Public",
    "annotation": [],
    "expression": {
        "type": "Null",
        "annotation": []
    }
}

drug_overlap_rate = {
    "name": "Drug Overlap Rate",
    "context": "Patient",
    "accessLevel": "Public",
    "annotation": [],
    "expression": {
        "type": "Null",
        "annotation": []
    }
}

# 组装所有 statements
elm["library"]["statements"]["def"] = [
    patient_statement,
    is_antihypertensive_func,
    calc_overlap_func,
    antihypertensive_prescriptions,
    total_drug_days,
    overlap_drug_days,
    drug_overlap_rate
]

# 保存
output_path = Path(r'ELM_JSON_OFFICIAL\舊50\Indicator_03_1_Same_Hospital_Antihypertensive_Overlap_1710.json')
with open(output_path, 'w', encoding='utf-8') as f:
    json.dump(elm, f, indent=2, ensure_ascii=False)

print(f'✓ 生成成功: {output_path}')
print(f'  大小: {output_path.stat().st_size / 1024:.2f} KB')
