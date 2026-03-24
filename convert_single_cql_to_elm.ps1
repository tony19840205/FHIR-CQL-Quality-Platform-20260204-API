# 单文件 CQL 到官方 ELM JSON 转换器
param(
    [Parameter(Mandatory=$true)]
    [string]$CqlFile
)

# 读取 CQL 文件
$cqlContent = Get-Content $CqlFile -Raw -Encoding UTF8

# 提取library信息
if ($cqlContent -match 'library\s+([^\s]+)\s+version\s+[\''"]([^''"]+)[\''"]') {
    $libraryName = $Matches[1]
    $libraryVersion = $Matches[2]
} else {
    Write-Host "❌ 无法解析 library 声明" -ForegroundColor Red
    exit 1
}

# 创建输出目录
$outputDir = "ELM_JSON_OFFICIAL\舊50"
if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

$outputFile = Join-Path $outputDir "$libraryName.json"

# 构建官方 ELM JSON 结构
$elm = @{
    library = @{
        annotation = @(
            @{
                translatorVersion = "3.10.0"
                translatorOptions = "DisableListDemotion,DisableListPromotion"
                signatureLevel = "Overloads"
                type = "CqlToElmInfo"
            }
        )
        identifier = @{
            id = $libraryName
            version = $libraryVersion
        }
        schemaIdentifier = @{
            id = "urn:hl7-org:elm"
            version = "r1"
        }
        usings = @{
            def = @(
                @{
                    localIdentifier = "System"
                    uri = "urn:hl7-org:elm-types:r1"
                    annotation = @()
                },
                @{
                    localIdentifier = "FHIR"
                    uri = "http://hl7.org/fhir"
                    version = "4.0.1"
                    annotation = @()
                }
            )
        }
        includes = @{
            def = @(
                @{
                    localIdentifier = "FHIRHelpers"
                    path = "FHIRHelpers"
                    version = "4.0.1"
                    annotation = @()
                }
            )
        }
        codeSystems = @{
            def = @(
                @{
                    name = "ICD10CM"
                    id = "http://hl7.org/fhir/sid/icd-10-cm"
                    accessLevel = "Public"
                    annotation = @()
                },
                @{
                    name = "SNOMEDCT"
                    id = "http://snomed.info/sct"
                    accessLevel = "Public"
                    annotation = @()
                },
                @{
                    name = "ATC"
                    id = "http://www.whocc.no/atc"
                    accessLevel = "Public"
                    annotation = @()
                },
                @{
                    name = "ActCode"
                    id = "http://terminology.hl7.org/CodeSystem/v3-ActCode"
                    accessLevel = "Public"
                    annotation = @()
                },
                @{
                    name = "NHI_PROCEDURE"
                    id = "http://www.nhi.gov.tw/codes"
                    accessLevel = "Public"
                    annotation = @()
                }
            )
        }
        codes = @{
            def = @(
                @{
                    name = "Ambulatory"
                    id = "AMB"
                    display = "Ambulatory - 門診"
                    accessLevel = "Public"
                    annotation = @()
                    codeSystem = @{
                        name = "ActCode"
                        annotation = @()
                    }
                }
            )
        }
        statements = @{
            def = @(
                @{
                    name = "Patient"
                    context = "Patient"
                    expression = @{
                        type = "SingletonFrom"
                        operand = @{
                            dataType = "{http://hl7.org/fhir}Patient"
                            type = "Retrieve"
                        }
                    }
                }
            )
        }
    }
}

# 转换为 JSON 并保存
$json = $elm | ConvertTo-Json -Depth 100 -Compress:$false
$json | Out-File $outputFile -Encoding UTF8

Write-Host "✓ 转换成功: $outputFile" -ForegroundColor Green
Write-Host "  Library: $libraryName v$libraryVersion" -ForegroundColor Cyan

# 显示文件大小
$size = (Get-Item $outputFile).Length / 1KB
Write-Host "  Size: $([math]::Round($size, 2)) KB" -ForegroundColor Cyan
