library InfectiousDisease_Influenza_Surveillance version '1.0.0'

using FHIR version '4.0.1'

include FHIRHelpers version '4.0.1' called FHIRHelpers

codesystem "ICD-9-CM": 'http://hl7.org/fhir/sid/icd-9-cm'
codesystem "ICD-10-CM": 'http://hl7.org/fhir/sid/icd-10-cm'
codesystem "SNOMEDCT": 'http://snomed.info/sct'
codesystem "LOINC": 'http://loinc.org'
codesystem "ActCode": 'http://terminology.hl7.org/CodeSystem/v3-ActCode'

// 參數定義
parameter "Measurement Period" Interval<DateTime> default Interval[@1900-01-01T00:00:00.0, @2100-12-31T23:59:59.0]
parameter "Lookback Days" Integer default 60

// ============================================
// 流感相關代碼定義 (圖一 & 圖二)
// ============================================

// ICD-9-CM 代碼 - 流感 (RODS源流感)
code "ICD9 Meningococcal infection 003.22": '003.22' from "ICD-9-CM" display 'Salmonella pneumonia'
code "ICD9 Whooping cough 010": '010' from "ICD-9-CM" display 'Primary tuberculous infection'
code "ICD9 Respiratory tuberculosis 010.0": '010.0' from "ICD-9-CM" display 'Primary tuberculous infection, unspecified'
code "ICD9 Tuberculosis of lung 010.00": '010.00' from "ICD-9-CM" display 'Primary tuberculous infection, unspecified, unspecified examination'
code "ICD9 Tuberculosis 010.01": '010.01' from "ICD-9-CM" display 'Primary tuberculous infection, unspecified, bacteriological or histological examination not done'
code "ICD9 Tuberculosis 010.02": '010.02' from "ICD-9-CM" display 'Primary tuberculous infection, unspecified, bacteriological or histological examination unknown'
code "ICD9 Tuberculosis 010.03": '010.03' from "ICD-9-CM" display 'Primary tuberculous infection, unspecified, tubercle bacilli found by microscopy'
code "ICD9 Tuberculosis 010.04": '010.04' from "ICD-9-CM" display 'Primary tuberculous infection, unspecified, tubercle bacilli found by bacterial culture'
code "ICD9 Tuberculosis 010.05": '010.05' from "ICD-9-CM" display 'Primary tuberculous infection, unspecified, tubercle bacilli confirmed histologically'
code "ICD9 Tuberculosis 010.06": '010.06' from "ICD-9-CM" display 'Primary tuberculous infection, unspecified, tubercle bacilli found by other methods'
code "ICD9 Tuberculosis 010.1": '010.1' from "ICD-9-CM" display 'Primary tuberculous complex'
code "ICD9 Tuberculosis 010.10": '010.10' from "ICD-9-CM" display 'Primary tuberculous complex, unspecified'
code "ICD9 Tuberculosis 010.11": '010.11' from "ICD-9-CM" display 'Primary tuberculous complex, no examination'
code "ICD9 Tuberculosis 010.12": '010.12' from "ICD-9-CM" display 'Primary tuberculous complex, examination unknown'
code "ICD9 Tuberculosis 010.13": '010.13' from "ICD-9-CM" display 'Primary tuberculous complex, microscopy'
code "ICD9 Tuberculosis 011": '011' from "ICD-9-CM" display 'Pulmonary tuberculosis'
code "ICD9 Tuberculosis of lung 011.0": '011.0' from "ICD-9-CM" display 'Tuberculosis of lung, infiltrative'
code "ICD9 Tuberculosis 011.00": '011.00' from "ICD-9-CM" display 'Tuberculosis of lung, infiltrative, unspecified'
code "ICD9 Tuberculosis 011.01": '011.01' from "ICD-9-CM" display 'Tuberculosis of lung, infiltrative, no examination'
code "ICD9 Tuberculosis 011.02": '011.02' from "ICD-9-CM" display 'Tuberculosis of lung, infiltrative, examination unknown'
code "ICD9 Tuberculosis 011.03": '011.03' from "ICD-9-CM" display 'Tuberculosis of lung, infiltrative, microscopy'
code "ICD9 Tuberculosis 011.04": '011.04' from "ICD-9-CM" display 'Tuberculosis of lung, infiltrative, culture'
code "ICD9 Tuberculosis 011.05": '011.05' from "ICD-9-CM" display 'Tuberculosis of lung, infiltrative, histology'
code "ICD9 Tuberculosis 011.06": '011.06' from "ICD-9-CM" display 'Tuberculosis of lung, infiltrative, other methods'
code "ICD9 Tuberculosis 011.1": '011.1' from "ICD-9-CM" display 'Tuberculosis of lung, nodular'
code "ICD9 Tuberculosis 011.10": '011.10' from "ICD-9-CM" display 'Tuberculosis of lung, nodular, unspecified'
code "ICD9 Tuberculosis 011.11": '011.11' from "ICD-9-CM" display 'Tuberculosis of lung, nodular, no examination'
code "ICD9 Tuberculosis 011.12": '011.12' from "ICD-9-CM" display 'Tuberculosis of lung, nodular, examination unknown'
code "ICD9 Tuberculosis 011.13": '011.13' from "ICD-9-CM" display 'Tuberculosis of lung, nodular, microscopy'
code "ICD9 Tuberculosis 011.14": '011.14' from "ICD-9-CM" display 'Tuberculosis of lung, nodular, culture'
code "ICD9 Tuberculosis 011.15": '011.15' from "ICD-9-CM" display 'Tuberculosis of lung, nodular, histology'
code "ICD9 Tuberculosis 011.16": '011.16' from "ICD-9-CM" display 'Tuberculosis of lung, nodular, other methods'
code "ICD9 Tuberculosis 011.2": '011.2' from "ICD-9-CM" display 'Tuberculosis of lung with cavitation'
code "ICD9 Tuberculosis 011.20": '011.20' from "ICD-9-CM" display 'Tuberculosis of lung with cavitation, unspecified'
code "ICD9 Tuberculosis 011.21": '011.21' from "ICD-9-CM" display 'Tuberculosis of lung with cavitation, no examination'
code "ICD9 Tuberculosis 011.22": '011.22' from "ICD-9-CM" display 'Tuberculosis of lung with cavitation, examination unknown'
code "ICD9 Tuberculosis 011.23": '011.23' from "ICD-9-CM" display 'Tuberculosis of lung with cavitation, microscopy'
code "ICD9 Tuberculosis 011.24": '011.24' from "ICD-9-CM" display 'Tuberculosis of lung with cavitation, culture'
code "ICD9 Tuberculosis 011.25": '011.25' from "ICD-9-CM" display 'Tuberculosis of lung with cavitation, histology'
code "ICD9 Tuberculosis 011.26": '011.26' from "ICD-9-CM" display 'Tuberculosis of lung with cavitation, other methods'
code "ICD9 Tuberculosis 011.3": '011.3' from "ICD-9-CM" display 'Tuberculosis of bronchus'
code "ICD9 Tuberculosis 011.30": '011.30' from "ICD-9-CM" display 'Tuberculosis of bronchus, unspecified'
code "ICD9 Tuberculosis 011.31": '011.31' from "ICD-9-CM" display 'Tuberculosis of bronchus, no examination'
code "ICD9 Tuberculosis 011.32": '011.32' from "ICD-9-CM" display 'Tuberculosis of bronchus, examination unknown'
code "ICD9 Tuberculosis 011.33": '011.33' from "ICD-9-CM" display 'Tuberculosis of bronchus, microscopy'
code "ICD9 Tuberculosis 011.34": '011.34' from "ICD-9-CM" display 'Tuberculosis of bronchus, culture'
code "ICD9 Tuberculosis 011.35": '011.35' from "ICD-9-CM" display 'Tuberculosis of bronchus, histology'
code "ICD9 Tuberculosis 011.4": '011.4' from "ICD-9-CM" display 'Tuberculous fibrosis of lung'
code "ICD9 Tuberculosis 011.40": '011.40' from "ICD-9-CM" display 'Tuberculous fibrosis of lung, unspecified'
code "ICD9 Tuberculosis 011.41": '011.41' from "ICD-9-CM" display 'Tuberculous fibrosis of lung, no examination'
code "ICD9 Tuberculosis 011.42": '011.42' from "ICD-9-CM" display 'Tuberculous fibrosis of lung, examination unknown'
code "ICD9 Tuberculosis 011.43": '011.43' from "ICD-9-CM" display 'Tuberculous fibrosis of lung, microscopy'
code "ICD9 Tuberculosis 011.44": '011.44' from "ICD-9-CM" display 'Tuberculous fibrosis of lung, culture'
code "ICD9 Tuberculosis 011.45": '011.45' from "ICD-9-CM" display 'Tuberculous fibrosis of lung, histology'
code "ICD9 Tuberculosis 011.46": '011.46' from "ICD-9-CM" display 'Tuberculous fibrosis of lung, other methods'
code "ICD9 Tuberculosis 011.5": '011.5' from "ICD-9-CM" display 'Tuberculous bronchiectasis'
code "ICD9 Tuberculosis 011.50": '011.50' from "ICD-9-CM" display 'Tuberculous bronchiectasis, unspecified'
code "ICD9 Tuberculosis 011.51": '011.51' from "ICD-9-CM" display 'Tuberculous bronchiectasis, no examination'
code "ICD9 Tuberculosis 011.52": '011.52' from "ICD-9-CM" display 'Tuberculous bronchiectasis, examination unknown'
code "ICD9 Tuberculosis 011.53": '011.53' from "ICD-9-CM" display 'Tuberculous bronchiectasis, microscopy'
code "ICD9 Tuberculosis 011.54": '011.54' from "ICD-9-CM" display 'Tuberculous bronchiectasis, culture'
code "ICD9 Tuberculosis 011.55": '011.55' from "ICD-9-CM" display 'Tuberculous bronchiectasis, histology'
code "ICD9 Tuberculosis 011.56": '011.56' from "ICD-9-CM" display 'Tuberculous bronchiectasis, other methods'
code "ICD9 Tuberculosis 011.6": '011.6' from "ICD-9-CM" display 'Tuberculous pneumonia'
code "ICD9 Tuberculosis 011.60": '011.60' from "ICD-9-CM" display 'Tuberculous pneumonia, unspecified'
code "ICD9 Tuberculosis 011.61": '011.61' from "ICD-9-CM" display 'Tuberculous pneumonia, no examination'
code "ICD9 Tuberculosis 011.62": '011.62' from "ICD-9-CM" display 'Tuberculous pneumonia, examination unknown'
code "ICD9 Tuberculosis 011.63": '011.63' from "ICD-9-CM" display 'Tuberculous pneumonia, microscopy'
code "ICD9 Tuberculosis 011.64": '011.64' from "ICD-9-CM" display 'Tuberculous pneumonia, culture'
code "ICD9 Tuberculosis 011.65": '011.65' from "ICD-9-CM" display 'Tuberculous pneumonia, histology'
code "ICD9 Tuberculosis 011.66": '011.66' from "ICD-9-CM" display 'Tuberculous pneumonia, other methods'
code "ICD9 Tuberculosis 011.7": '011.7' from "ICD-9-CM" display 'Tuberculous pneumothorax'
code "ICD9 Tuberculosis 011.70": '011.70' from "ICD-9-CM" display 'Tuberculous pneumothorax, unspecified'
code "ICD9 Tuberculosis 011.71": '011.71' from "ICD-9-CM" display 'Tuberculous pneumothorax, no examination'
code "ICD9 Tuberculosis 011.72": '011.72' from "ICD-9-CM" display 'Tuberculous pneumothorax, examination unknown'
code "ICD9 Tuberculosis 011.73": '011.73' from "ICD-9-CM" display 'Tuberculous pneumothorax, microscopy'
code "ICD9 Tuberculosis 011.74": '011.74' from "ICD-9-CM" display 'Tuberculous pneumothorax, culture'
code "ICD9 Tuberculosis 011.75": '011.75' from "ICD-9-CM" display 'Tuberculous pneumothorax, histology'
code "ICD9 Tuberculosis 011.76": '011.76' from "ICD-9-CM" display 'Tuberculous pneumothorax, other methods'
code "ICD9 Tuberculosis 011.8": '011.8' from "ICD-9-CM" display 'Other specified pulmonary tuberculosis'
code "ICD9 Tuberculosis 011.80": '011.80' from "ICD-9-CM" display 'Other specified pulmonary tuberculosis, unspecified'
code "ICD9 Tuberculosis 011.81": '011.81' from "ICD-9-CM" display 'Other specified pulmonary tuberculosis, no examination'
code "ICD9 Tuberculosis 011.82": '011.82' from "ICD-9-CM" display 'Other specified pulmonary tuberculosis, examination unknown'
code "ICD9 Tuberculosis 011.83": '011.83' from "ICD-9-CM" display 'Other specified pulmonary tuberculosis, microscopy'
code "ICD9 Tuberculosis 011.84": '011.84' from "ICD-9-CM" display 'Other specified pulmonary tuberculosis, culture'
code "ICD9 Tuberculosis 011.85": '011.85' from "ICD-9-CM" display 'Other specified pulmonary tuberculosis, histology'
code "ICD9 Tuberculosis 011.86": '011.86' from "ICD-9-CM" display 'Other specified pulmonary tuberculosis, other methods'
code "ICD9 Tuberculosis 011.9": '011.9' from "ICD-9-CM" display 'Pulmonary tuberculosis, unspecified'
code "ICD9 Tuberculosis 011.90": '011.90' from "ICD-9-CM" display 'Pulmonary tuberculosis, unspecified, unspecified'
code "ICD9 Tuberculosis 011.91": '011.91' from "ICD-9-CM" display 'Pulmonary tuberculosis, unspecified, no examination'
code "ICD9 Tuberculosis 011.92": '011.92' from "ICD-9-CM" display 'Pulmonary tuberculosis, unspecified, examination unknown'
code "ICD9 Tuberculosis 011.93": '011.93' from "ICD-9-CM" display 'Pulmonary tuberculosis, unspecified, microscopy'
code "ICD9 Tuberculosis 011.94": '011.94' from "ICD-9-CM" display 'Pulmonary tuberculosis, unspecified, culture'
code "ICD9 Tuberculosis 011.95": '011.95' from "ICD-9-CM" display 'Pulmonary tuberculosis, unspecified, histology'
code "ICD9 Tuberculosis 011.96": '011.96' from "ICD-9-CM" display 'Pulmonary tuberculosis, unspecified, other methods'
code "ICD9 Tuberculosis 034.0": '034.0' from "ICD-9-CM" display 'Streptococcal sore throat'
code "ICD9 Scarlet fever 052.1": '052.1' from "ICD-9-CM" display 'Varicella pneumonitis'
code "ICD9 Chickenpox 055.1": '055.1' from "ICD-9-CM" display 'Postmeasles pneumonia'
code "ICD9 Measles 073.0": '073.0' from "ICD-9-CM" display 'Ornithosis with pneumonia'
code "ICD9 Ornithosis 074.1": '074.1' from "ICD-9-CM" display 'Epidemic pleurodynia'
code "ICD9 Epidemic pleurodynia 079.81": '079.81' from "ICD-9-CM" display 'Hantavirus infection'
code "ICD9 Hantavirus infection 079.88": '079.88' from "ICD-9-CM" display 'Other specified viral infection'
code "ICD9 Viral infection unspecified 079.89": '079.89' from "ICD-9-CM" display 'Other specified viral infection'
code "ICD9 Pneumococcal pneumonia 481": '481' from "ICD-9-CM" display 'Pneumococcal pneumonia'
code "ICD9 Other bacterial pneumonia 482": '482' from "ICD-9-CM" display 'Other bacterial pneumonia'
code "ICD9 H influenzae pneumonia 482.2": '482.2' from "ICD-9-CM" display 'Pneumonia due to Hemophilus influenzae'
code "ICD9 Streptococcus pneumonia 482.30": '482.30' from "ICD-9-CM" display 'Pneumonia due to Streptococcus, unspecified'
code "ICD9 Streptococcus pneumoniae 482.31": '482.31' from "ICD-9-CM" display 'Pneumonia due to Streptococcus, group A'
code "ICD9 Other Streptococcus pneumonia 482.32": '482.32' from "ICD-9-CM" display 'Pneumonia due to Streptococcus, group B'
code "ICD9 Staphylococcus pneumonia 482.39": '482.39' from "ICD-9-CM" display 'Pneumonia due to other Streptococcus'
code "ICD9 Staphylococcus pneumonia 482.40": '482.40' from "ICD-9-CM" display 'Pneumonia due to Staphylococcus, unspecified'
code "ICD9 Staphylococcus aureus pneumonia 482.41": '482.41' from "ICD-9-CM" display 'Methicillin susceptible pneumonia due to Staphylococcus aureus'
code "ICD9 MRSA pneumonia 482.42": '482.42' from "ICD-9-CM" display 'Methicillin resistant pneumonia due to Staphylococcus aureus'
code "ICD9 Other Staphylococcus pneumonia 482.49": '482.49' from "ICD-9-CM" display 'Other Staphylococcus pneumonia'
code "ICD9 Pneumonia due to SARS 482.83": '482.83' from "ICD-9-CM" display 'Pneumonia due to SARS-associated coronavirus'
code "ICD9 Legionnaires disease 482.84": '482.84' from "ICD-9-CM" display 'Pneumonia due to Legionnaires disease'
code "ICD9 Pneumonia Gram-negative bacteria 482.89": '482.89' from "ICD-9-CM" display 'Pneumonia due to other specified bacteria'
code "ICD9 Bronchopneumonia organism unspecified 485": '485' from "ICD-9-CM" display 'Bronchopneumonia, organism unspecified'
code "ICD9 Pneumonia organism unspecified 486": '486' from "ICD-9-CM" display 'Pneumonia, organism unspecified'
code "ICD9 Influenza 487": '487' from "ICD-9-CM" display 'Influenza'
code "ICD9 Influenza with pneumonia 487.0": '487.0' from "ICD-9-CM" display 'Influenza with pneumonia'
code "ICD9 Influenza with respiratory manifestations 487.1": '487.1' from "ICD-9-CM" display 'Influenza with other respiratory manifestations'
code "ICD9 Influenza with other manifestations 487.8": '487.8' from "ICD-9-CM" display 'Influenza with other manifestations'
code "ICD9 Upper respiratory infection acute 465.9": '465.9' from "ICD-9-CM" display 'Acute upper respiratory infections of unspecified site'

// ICD-10-CM 代碼 - 流感
code "ICD10 Influenza J09": 'J09' from "ICD-10-CM" display 'Influenza due to certain identified influenza viruses'
code "ICD10 Influenza due to identified novel influenza A J09": 'J09' from "ICD-10-CM" display 'Influenza due to identified novel influenza A virus'
code "ICD10 Influenza with pneumonia J10": 'J10' from "ICD-10-CM" display 'Influenza due to other identified influenza virus'
code "ICD10 Influenza with other respiratory J10": 'J10' from "ICD-10-CM" display 'Influenza due to other identified influenza virus with other respiratory manifestations'
code "ICD10 Influenza with other manifestations J10": 'J10' from "ICD-10-CM" display 'Influenza due to other identified influenza virus with other manifestations'
code "ICD10 Influenza virus not identified J11": 'J11' from "ICD-10-CM" display 'Influenza due to unidentified influenza virus'
code "ICD10 Influenza with pneumonia unidentified J11": 'J11' from "ICD-10-CM" display 'Influenza due to unidentified influenza virus with pneumonia'
code "ICD10 Influenza with respiratory manifestations J11": 'J11' from "ICD-10-CM" display 'Influenza due to unidentified influenza virus with other respiratory manifestations'
code "ICD10 Influenza J12": 'J12' from "ICD-10-CM" display 'Viral pneumonia, not elsewhere classified'
code "ICD10 Influenza J13": 'J13' from "ICD-10-CM" display 'Pneumonia due to Streptococcus pneumoniae'
code "ICD10 Influenza J14": 'J14' from "ICD-10-CM" display 'Pneumonia due to Hemophilus influenzae'
code "ICD10 Bacterial pneumonia J15": 'J15' from "ICD-10-CM" display 'Bacterial pneumonia, not elsewhere classified'
code "ICD10 Pneumonia other infectious organisms J16": 'J16' from "ICD-10-CM" display 'Pneumonia due to other infectious organisms, not elsewhere classified'
code "ICD10 Pneumonia in diseases B25": 'B25' from "ICD-10-CM" display 'Cytomegaloviral disease'
code "ICD10 SARS A37": 'A37' from "ICD-10-CM" display 'Whooping cough'
code "ICD10 Avian influenza A22": 'A22' from "ICD-10-CM" display 'Anthrax'
code "ICD10 Avian influenza B44": 'B44' from "ICD-10-CM" display 'Aspergillosis'
code "ICD10 Influenza J17": 'J17' from "ICD-10-CM" display 'Pneumonia in diseases classified elsewhere'
code "ICD10 Influenza J18": 'J18' from "ICD-10-CM" display 'Pneumonia, unspecified organism'
code "ICD10 Acute upper respiratory infection J06.9": 'J06.9' from "ICD-10-CM" display 'Acute upper respiratory infection, unspecified'

// SNOMED CT 代碼
code "SNOMED Influenza": '6142004' from "SNOMEDCT" display 'Influenza'
code "SNOMED Influenza with pneumonia": '442438000' from "SNOMEDCT" display 'Influenza with pneumonia'
code "SNOMED Influenza with respiratory manifestations": '195878008' from "SNOMEDCT" display 'Influenza with respiratory manifestation'
code "SNOMED Seasonal influenza": '442696006' from "SNOMEDCT" display 'Influenza caused by seasonal influenza virus'
code "SNOMED Influenza A": '442696006' from "SNOMEDCT" display 'Influenza due to Influenza A virus'
code "SNOMED Influenza B": '722499003' from "SNOMEDCT" display 'Influenza caused by Influenza B virus'
code "SNOMED H1N1 influenza": '442696006' from "SNOMEDCT" display 'Influenza due to Influenza A virus subtype H1N1'
code "SNOMED H3N2 influenza": '442696006' from "SNOMEDCT" display 'Influenza due to Influenza A virus subtype H3N2'
code "SNOMED Avian influenza": '442438000' from "SNOMEDCT" display 'Influenza due to Influenza A virus subtype H5N1'
code "SNOMED Novel influenza A": '442696006' from "SNOMEDCT" display 'Influenza due to identified novel influenza A virus'
code "SNOMED Influenza-like illness": '95891005' from "SNOMEDCT" display 'Influenza-like illness'
code "SNOMED Acute respiratory infection": '50417007' from "SNOMEDCT" display 'Acute respiratory tract infection'
code "SNOMED Viral pneumonia": '290142005' from "SNOMEDCT" display 'Viral pneumonia'
code "SNOMED Pneumonia": '233604007' from "SNOMEDCT" display 'Pneumonia'
code "SNOMED Bacterial pneumonia": '53084003' from "SNOMEDCT" display 'Bacterial pneumonia'
code "SNOMED Pneumococcal pneumonia": '16814004' from "SNOMEDCT" display 'Pneumococcal pneumonia'
code "SNOMED Haemophilus influenzae pneumonia": '70036007' from "SNOMEDCT" display 'Haemophilus influenzae pneumonia'
code "SNOMED Upper respiratory tract infection": '54150009' from "SNOMEDCT" display 'Upper respiratory infection'

// LOINC 實驗室檢驗代碼
code "LOINC Influenza A RNA": '92142-9' from "LOINC" display 'Influenza virus A RNA [Presence] in Respiratory specimen by NAA with probe detection'
code "LOINC Influenza B RNA": '92141-1' from "LOINC" display 'Influenza virus B RNA [Presence] in Respiratory specimen by NAA with probe detection'
code "LOINC Influenza A+B Ag": '80382-5' from "LOINC" display 'Influenza virus A and B Ag panel - Respiratory specimen by Rapid immunoassay'
code "LOINC Influenza A Ag": '49661-6' from "LOINC" display 'Influenza virus A Ag [Presence] in Specimen'
code "LOINC Influenza B Ag": '49662-4' from "LOINC" display 'Influenza virus B Ag [Presence] in Specimen'
code "LOINC Influenza A H1 RNA": '82174-6' from "LOINC" display 'Influenza virus A H1 RNA [Presence] in Respiratory specimen by NAA with probe detection'
code "LOINC Influenza A H3 RNA": '82175-3' from "LOINC" display 'Influenza virus A H3 RNA [Presence] in Respiratory specimen by NAA with probe detection'
code "LOINC Influenza A 2009 H1N1 RNA": '64204-7' from "LOINC" display 'Influenza virus A pandemic 2009 H1N1 RNA [Presence] in Specimen by NAA with probe detection'
code "LOINC Influenza virus culture": '548-8' from "LOINC" display 'Influenza virus identified in Specimen by Organism specific culture'
code "LOINC Influenza A+B panel": '85477-8' from "LOINC" display 'Influenza virus A and B and SARS-CoV-2 (COVID-19) RNA panel - Respiratory specimen by NAA with probe detection'
code "LOINC Respiratory virus panel": '85478-6' from "LOINC" display 'Respiratory pathogens DNA and RNA panel - Respiratory specimen by NAA with probe detection'
code "LOINC Influenza A subtyping": '88534-3' from "LOINC" display 'Influenza virus A subtyping panel - Specimen'
code "LOINC Influenza serology": '5848-6' from "LOINC" display 'Influenza virus A Ab [Units/volume] in Serum'
code "LOINC Influenza virus RNA": '92131-2' from "LOINC" display 'Influenza virus RNA [Presence] in Respiratory specimen by NAA with probe detection'
code "LOINC Influenza A H5 RNA": '60274-8' from "LOINC" display 'Influenza virus A H5 RNA [Presence] in Specimen by NAA with probe detection'
code "LOINC Influenza A H7 RNA": '60275-5' from "LOINC" display 'Influenza virus A H7 RNA [Presence] in Specimen by NAA with probe detection'

// ActCode 就醫類型
code "ActCode Outpatient": 'AMB' from "ActCode" display 'Ambulatory/Outpatient'
code "ActCode Emergency": 'EMER' from "ActCode" display 'Emergency'
code "ActCode Inpatient": 'IMP' from "ActCode" display 'Inpatient encounter'

// ============================================
// 值集定義
// ============================================

valueset "Influenza ICD9 Codes": {
  "ICD9 Meningococcal infection 003.22",
  "ICD9 Whooping cough 010",
  "ICD9 Respiratory tuberculosis 010.0",
  "ICD9 Tuberculosis of lung 010.00",
  "ICD9 Tuberculosis 010.01",
  "ICD9 Tuberculosis 010.02",
  "ICD9 Tuberculosis 010.03",
  "ICD9 Tuberculosis 010.04",
  "ICD9 Tuberculosis 010.05",
  "ICD9 Tuberculosis 010.06",
  "ICD9 Tuberculosis 010.1",
  "ICD9 Tuberculosis 010.10",
  "ICD9 Tuberculosis 010.11",
  "ICD9 Tuberculosis 010.12",
  "ICD9 Tuberculosis 010.13",
  "ICD9 Tuberculosis 011",
  "ICD9 Tuberculosis of lung 011.0",
  "ICD9 Tuberculosis 011.00",
  "ICD9 Tuberculosis 011.01",
  "ICD9 Tuberculosis 011.02",
  "ICD9 Tuberculosis 011.03",
  "ICD9 Tuberculosis 011.04",
  "ICD9 Tuberculosis 011.05",
  "ICD9 Tuberculosis 011.06",
  "ICD9 Tuberculosis 011.1",
  "ICD9 Tuberculosis 011.10",
  "ICD9 Tuberculosis 011.11",
  "ICD9 Tuberculosis 011.12",
  "ICD9 Tuberculosis 011.13",
  "ICD9 Tuberculosis 011.14",
  "ICD9 Tuberculosis 011.15",
  "ICD9 Tuberculosis 011.16",
  "ICD9 Tuberculosis 011.2",
  "ICD9 Tuberculosis 011.20",
  "ICD9 Tuberculosis 011.21",
  "ICD9 Tuberculosis 011.22",
  "ICD9 Tuberculosis 011.23",
  "ICD9 Tuberculosis 011.24",
  "ICD9 Tuberculosis 011.25",
  "ICD9 Tuberculosis 011.26",
  "ICD9 Tuberculosis 011.3",
  "ICD9 Tuberculosis 011.30",
  "ICD9 Tuberculosis 011.31",
  "ICD9 Tuberculosis 011.32",
  "ICD9 Tuberculosis 011.33",
  "ICD9 Tuberculosis 011.34",
  "ICD9 Tuberculosis 011.35",
  "ICD9 Tuberculosis 011.4",
  "ICD9 Tuberculosis 011.40",
  "ICD9 Tuberculosis 011.41",
  "ICD9 Tuberculosis 011.42",
  "ICD9 Tuberculosis 011.43",
  "ICD9 Tuberculosis 011.44",
  "ICD9 Tuberculosis 011.45",
  "ICD9 Tuberculosis 011.46",
  "ICD9 Tuberculosis 011.5",
  "ICD9 Tuberculosis 011.50",
  "ICD9 Tuberculosis 011.51",
  "ICD9 Tuberculosis 011.52",
  "ICD9 Tuberculosis 011.53",
  "ICD9 Tuberculosis 011.54",
  "ICD9 Tuberculosis 011.55",
  "ICD9 Tuberculosis 011.56",
  "ICD9 Tuberculosis 011.6",
  "ICD9 Tuberculosis 011.60",
  "ICD9 Tuberculosis 011.61",
  "ICD9 Tuberculosis 011.62",
  "ICD9 Tuberculosis 011.63",
  "ICD9 Tuberculosis 011.64",
  "ICD9 Tuberculosis 011.65",
  "ICD9 Tuberculosis 011.66",
  "ICD9 Tuberculosis 011.7",
  "ICD9 Tuberculosis 011.70",
  "ICD9 Tuberculosis 011.71",
  "ICD9 Tuberculosis 011.72",
  "ICD9 Tuberculosis 011.73",
  "ICD9 Tuberculosis 011.74",
  "ICD9 Tuberculosis 011.75",
  "ICD9 Tuberculosis 011.76",
  "ICD9 Tuberculosis 011.8",
  "ICD9 Tuberculosis 011.80",
  "ICD9 Tuberculosis 011.81",
  "ICD9 Tuberculosis 011.82",
  "ICD9 Tuberculosis 011.83",
  "ICD9 Tuberculosis 011.84",
  "ICD9 Tuberculosis 011.85",
  "ICD9 Tuberculosis 011.86",
  "ICD9 Tuberculosis 011.9",
  "ICD9 Tuberculosis 011.90",
  "ICD9 Tuberculosis 011.91",
  "ICD9 Tuberculosis 011.92",
  "ICD9 Tuberculosis 011.93",
  "ICD9 Tuberculosis 011.94",
  "ICD9 Tuberculosis 011.95",
  "ICD9 Tuberculosis 011.96",
  "ICD9 Tuberculosis 034.0",
  "ICD9 Scarlet fever 052.1",
  "ICD9 Chickenpox 055.1",
  "ICD9 Measles 073.0",
  "ICD9 Ornithosis 074.1",
  "ICD9 Epidemic pleurodynia 079.81",
  "ICD9 Hantavirus infection 079.88",
  "ICD9 Viral infection unspecified 079.89",
  "ICD9 Pneumococcal pneumonia 481",
  "ICD9 Other bacterial pneumonia 482",
  "ICD9 H influenzae pneumonia 482.2",
  "ICD9 Streptococcus pneumonia 482.30",
  "ICD9 Streptococcus pneumoniae 482.31",
  "ICD9 Other Streptococcus pneumonia 482.32",
  "ICD9 Staphylococcus pneumonia 482.39",
  "ICD9 Staphylococcus pneumonia 482.40",
  "ICD9 Staphylococcus aureus pneumonia 482.41",
  "ICD9 MRSA pneumonia 482.42",
  "ICD9 Other Staphylococcus pneumonia 482.49",
  "ICD9 Pneumonia due to SARS 482.83",
  "ICD9 Legionnaires disease 482.84",
  "ICD9 Pneumonia Gram-negative bacteria 482.89",
  "ICD9 Bronchopneumonia organism unspecified 485",
  "ICD9 Pneumonia organism unspecified 486",
  "ICD9 Influenza 487",
  "ICD9 Influenza with pneumonia 487.0",
  "ICD9 Influenza with respiratory manifestations 487.1",
  "ICD9 Influenza with other manifestations 487.8",
  "ICD9 Upper respiratory infection acute 465.9"
}

valueset "Influenza ICD10 Codes": {
  "ICD10 Influenza J09",
  "ICD10 Influenza due to identified novel influenza A J09",
  "ICD10 Influenza with pneumonia J10",
  "ICD10 Influenza with other respiratory J10",
  "ICD10 Influenza with other manifestations J10",
  "ICD10 Influenza virus not identified J11",
  "ICD10 Influenza with pneumonia unidentified J11",
  "ICD10 Influenza with respiratory manifestations J11",
  "ICD10 Influenza J12",
  "ICD10 Influenza J13",
  "ICD10 Influenza J14",
  "ICD10 Bacterial pneumonia J15",
  "ICD10 Pneumonia other infectious organisms J16",
  "ICD10 Pneumonia in diseases B25",
  "ICD10 SARS A37",
  "ICD10 Avian influenza A22",
  "ICD10 Avian influenza B44",
  "ICD10 Influenza J17",
  "ICD10 Influenza J18",
  "ICD10 Acute upper respiratory infection J06.9"
}

valueset "Influenza SNOMED Codes": {
  "SNOMED Influenza",
  "SNOMED Influenza with pneumonia",
  "SNOMED Influenza with respiratory manifestations",
  "SNOMED Seasonal influenza",
  "SNOMED Influenza A",
  "SNOMED Influenza B",
  "SNOMED H1N1 influenza",
  "SNOMED H3N2 influenza",
  "SNOMED Avian influenza",
  "SNOMED Novel influenza A",
  "SNOMED Influenza-like illness",
  "SNOMED Acute respiratory infection",
  "SNOMED Viral pneumonia",
  "SNOMED Pneumonia",
  "SNOMED Bacterial pneumonia",
  "SNOMED Pneumococcal pneumonia",
  "SNOMED Haemophilus influenzae pneumonia",
  "SNOMED Upper respiratory tract infection"
}

valueset "Influenza Lab Codes": {
  "LOINC Influenza A RNA",
  "LOINC Influenza B RNA",
  "LOINC Influenza A+B Ag",
  "LOINC Influenza A Ag",
  "LOINC Influenza B Ag",
  "LOINC Influenza A H1 RNA",
  "LOINC Influenza A H3 RNA",
  "LOINC Influenza A 2009 H1N1 RNA",
  "LOINC Influenza virus culture",
  "LOINC Influenza A+B panel",
  "LOINC Respiratory virus panel",
  "LOINC Influenza A subtyping",
  "LOINC Influenza serology",
  "LOINC Influenza virus RNA",
  "LOINC Influenza A H5 RNA",
  "LOINC Influenza A H7 RNA"
}

valueset "Encounter Type Codes": {
  "ActCode Outpatient",
  "ActCode Emergency",
  "ActCode Inpatient"
}

// ============================================
// 核心邏輯：患者與事件定義
// ============================================

context Patient

// 所有流感診斷條件 (Condition resources)
define "Influenza Diagnosis Conditions":
  [Condition: "Influenza ICD9 Codes"]
    union [Condition: "Influenza ICD10 Codes"]
    union [Condition: "Influenza SNOMED Codes"]

// 所有流感實驗室檢驗 (Observation resources)
define "Influenza Lab Results":
  [Observation: "Influenza Lab Codes"] Lab
    where Lab.status in {'final', 'amended', 'corrected'}
      and Lab.value is not null

// 所有就醫記錄 (無時間限制)
define "All Encounters":
  [Encounter] E
    where E.status = 'finished'

// 合併所有流感相關事件 (診斷 + 檢驗)
define "All Influenza Events":
  (
    "Influenza Diagnosis Conditions" C
      return Tuple {
        eventDate: Coalesce(C.onset as FHIR.dateTime, C.recordedDate),
        eventType: 'Diagnosis',
        code: C.code,
        encounterId: C.encounter.reference
      }
  )
  union
  (
    "Influenza Lab Results" L
      return Tuple {
        eventDate: Coalesce(L.effective as FHIR.dateTime, L.issued),
        eventType: 'Laboratory',
        code: L.code,
        encounterId: L.encounter.reference
      }
  )

// 取得事件對應的就醫記錄
define function "GetEncounterForEvent"(event Tuple { eventDate DateTime, eventType String, code Concept, encounterId String }):
  First(
    "All Encounters" E
      where 'Encounter/' + E.id = event.encounterId
  )

// 取得就醫記錄的結束日期 (住院用)
define function "GetEncounterEndDate"(encounter Encounter):
  Coalesce(
    encounter.period.end,
    encounter.period.start
  )

// 判斷是否為住院
define function "IsInpatientEncounter"(encounter Encounter):
  encounter.class ~ "ActCode Inpatient"

// ============================================
// Episode 邏輯：30天內事件合併（住院延長）
// ============================================

// 計算 Episode 結束日期：確診日 + 30天，若有住院則為出院日 + 30天
define function "CalculateEpisodeEndDate"(eventDate DateTime, encounter Encounter):
  if "IsInpatientEncounter"(encounter) then
    "GetEncounterEndDate"(encounter) + 30 days
  else
    eventDate + 30 days

// 排序所有事件（按時間）
define "Sorted Influenza Events":
  "All Influenza Events" E
    where E.eventDate is not null
    sort by eventDate

// 去重複：30天內算一次 (Episode Window Logic)
define "Unique Influenza Episodes":
  "Sorted Influenza Events" CurrentEvent
    let 
      encounter: "GetEncounterForEvent"(CurrentEvent),
      episodeEnd: "CalculateEpisodeEndDate"(CurrentEvent.eventDate, encounter),
      // 檢查前面是否有事件在同一 Episode 內 (Lookback)
      priorEventsInSameEpisode: 
        "Sorted Influenza Events" PriorEvent
          where PriorEvent.eventDate < CurrentEvent.eventDate
            and PriorEvent.eventDate >= (CurrentEvent.eventDate - ("Lookback Days" days)
            and difference in days between PriorEvent.eventDate and CurrentEvent.eventDate <= 30
    // 只保留新 Episode 的首次事件
    where Count(priorEventsInSameEpisode) = 0
    return Tuple {
      episodeStartDate: CurrentEvent.eventDate,
      episodeEndDate: episodeEnd,
      eventType: CurrentEvent.eventType,
      code: CurrentEvent.code,
      encounter: encounter,
      encounterId: CurrentEvent.encounterId
    }

// ============================================
// 輸出結果：年齡、性別、就醫類型
// ============================================

// 計算年齡（以事件發生時為準）
define function "CalculateAgeAtEvent"(eventDate DateTime):
  AgeInYearsAt(eventDate)

// 取得性別
define "Patient Gender":
  Patient.gender.value

// 判斷就醫類型（門診/急診/住院）
define function "GetEncounterType"(encounter Encounter):
  case
    when encounter.class ~ "ActCode Inpatient" then '住院'
    when encounter.class ~ "ActCode Emergency" then '急診'
    when encounter.class ~ "ActCode Outpatient" then '門診'
    else '其他'
  end

// 判斷病毒種類（標準化：會從 code 或 display 嘗試判斷常見病毒）
define function "DetermineVirusType"(code Concept):
  let firstCoding: Coalesce(code.coding[0], {})
  let display: ToLower(Coalesce(firstCoding.display.value, ''))
  let codeValue: Coalesce(firstCoding.code.value, '')
  case
    when display contains 'influenza a' then 'Influenza A'
    when display contains 'influenza b' then 'Influenza B'
    when display contains 'influenza' then 'Influenza'
    when display contains 'sars' or display contains 'covid' then 'SARS-CoV-2'
    when display contains 'rotavirus' then 'Rotavirus'
    when display contains 'norovirus' or display contains 'norwalk' then 'Norovirus'
    when display contains 'adenovirus' then 'Adenovirus'
    when display contains 'enterovirus' or display contains 'coxsackie' or display contains 'echovirus' then 'Enterovirus'
    else Coalesce(firstCoding.display.value, firstCoding.code.value)
  end

// 最終輸出結果
define "Influenza Surveillance Results":
  "Unique Influenza Episodes" Episode
    return Tuple {
      患者ID: Patient.id,
      事件日期: ToString(Episode.episodeStartDate),
      Episode結束日期: ToString(Episode.episodeEndDate),
      年齡: "CalculateAgeAtEvent"(Episode.episodeStartDate),
      性別: "Patient Gender",
      就醫類型: "GetEncounterType"(Episode.encounter),
      病毒種類: "DetermineVirusType"(Episode.code),
      事件類型: Episode.eventType,
      診斷代碼: Episode.code.coding[0].code.value,
      診斷名稱: Episode.code.coding[0].display.value
    }

// 計數統計
define "Total Unique Episodes":
  Count("Unique Influenza Episodes")

define "Episode Count By Gender":
  {
    男性: Count("Unique Influenza Episodes" E where "Patient Gender" = 'male'),
    女性: Count("Unique Influenza Episodes" E where "Patient Gender" = 'female')
  }

define "Episode Count By Encounter Type":
  {
    門診: Count("Unique Influenza Episodes" E where "GetEncounterType"(E.encounter) = '門診'),
    急診: Count("Unique Influenza Episodes" E where "GetEncounterType"(E.encounter) = '急診'),
    住院: Count("Unique Influenza Episodes" E where "GetEncounterType"(E.encounter) = '住院')
  }
