library InfectiousDisease_AcuteDiarrhea_Surveillance version '1.0.0'

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
// 急性腹瀉相關代碼定義 (圖一 & 圖二)
// ============================================

// ICD-9-CM 代碼 - 急性腸炎
code "ICD9 Cholera 001": '001' from "ICD-9-CM" display 'Cholera'
code "ICD9 Cholera due to V cholerae 001.0": '001.0' from "ICD-9-CM" display 'Cholera due to Vibrio cholerae'
code "ICD9 Cholera due to V cholerae el tor 001.1": '001.1' from "ICD-9-CM" display 'Cholera due to Vibrio cholerae el tor'
code "ICD9 Cholera unspecified 001.9": '001.9' from "ICD-9-CM" display 'Cholera, unspecified'
code "ICD9 Typhoid fever 002": '002' from "ICD-9-CM" display 'Typhoid and paratyphoid fevers'
code "ICD9 Typhoid fever 002.0": '002.0' from "ICD-9-CM" display 'Typhoid fever'
code "ICD9 Paratyphoid fever A 002.1": '002.1' from "ICD-9-CM" display 'Paratyphoid fever A'
code "ICD9 Paratyphoid fever B 002.2": '002.2' from "ICD-9-CM" display 'Paratyphoid fever B'
code "ICD9 Paratyphoid fever C 002.3": '002.3' from "ICD-9-CM" display 'Paratyphoid fever C'
code "ICD9 Paratyphoid fever unspecified 002.9": '002.9' from "ICD-9-CM" display 'Paratyphoid fever, unspecified'
code "ICD9 Salmonellosis 003": '003' from "ICD-9-CM" display 'Other salmonella infections'
code "ICD9 Salmonella gastroenteritis 003.0": '003.0' from "ICD-9-CM" display 'Salmonella gastroenteritis'
code "ICD9 Salmonella septicemia 003.1": '003.1' from "ICD-9-CM" display 'Salmonella septicemia'
code "ICD9 Salmonella localized infection 003.2": '003.2' from "ICD-9-CM" display 'Localized salmonella infections'
code "ICD9 Salmonella localized infection 003.20": '003.20' from "ICD-9-CM" display 'Localized salmonella infection, unspecified'
code "ICD9 Salmonella localized infection 003.21": '003.21' from "ICD-9-CM" display 'Salmonella meningitis'
code "ICD9 Salmonella localized infection 003.22": '003.22' from "ICD-9-CM" display 'Salmonella pneumonia'
code "ICD9 Salmonella localized infection 003.23": '003.23' from "ICD-9-CM" display 'Salmonella arthritis'
code "ICD9 Salmonella localized infection 003.24": '003.24' from "ICD-9-CM" display 'Salmonella osteomyelitis'
code "ICD9 Salmonella localized infection 003.29": '003.29' from "ICD-9-CM" display 'Other localized salmonella infections'
code "ICD9 Shigellosis 004": '004' from "ICD-9-CM" display 'Shigellosis'
code "ICD9 Shigella dysenteriae 004.0": '004.0' from "ICD-9-CM" display 'Shigella dysenteriae'
code "ICD9 Shigella flexneri 004.1": '004.1' from "ICD-9-CM" display 'Shigella flexneri'
code "ICD9 Shigella boydii 004.2": '004.2' from "ICD-9-CM" display 'Shigella boydii'
code "ICD9 Shigella sonnei 004.3": '004.3' from "ICD-9-CM" display 'Shigella sonnei'
code "ICD9 Shigella unspecified 004.9": '004.9' from "ICD-9-CM" display 'Shigellosis, unspecified'
code "ICD9 Food poisoning 005": '005' from "ICD-9-CM" display 'Other food poisoning (bacterial)'
code "ICD9 Staphylococcal food poisoning 005.0": '005.0' from "ICD-9-CM" display 'Staphylococcal food poisoning'
code "ICD9 Botulism 005.1": '005.1' from "ICD-9-CM" display 'Botulism'
code "ICD9 Food poisoning Clostridium perfringens 005.2": '005.2' from "ICD-9-CM" display 'Food poisoning due to Clostridium perfringens'
code "ICD9 Food poisoning other Clostridia 005.3": '005.3' from "ICD-9-CM" display 'Food poisoning due to other Clostridia'
code "ICD9 Food poisoning V parahaemolyticus 005.4": '005.4' from "ICD-9-CM" display 'Food poisoning due to Vibrio parahaemolyticus'
code "ICD9 Food poisoning V vulnificus 005.81": '005.81' from "ICD-9-CM" display 'Food poisoning due to Vibrio vulnificus'
code "ICD9 Food poisoning other organisms 005.89": '005.89' from "ICD-9-CM" display 'Other bacterial food poisoning'
code "ICD9 Food poisoning unspecified 005.9": '005.9' from "ICD-9-CM" display 'Food poisoning, unspecified'
code "ICD9 Amoebiasis 006": '006' from "ICD-9-CM" display 'Amoebiasis'
code "ICD9 Acute amoebic dysentery 006.0": '006.0' from "ICD-9-CM" display 'Acute amebic dysentery without mention of abscess'
code "ICD9 Chronic intestinal amoebiasis 006.1": '006.1' from "ICD-9-CM" display 'Chronic intestinal amebiasis without mention of abscess'
code "ICD9 Amoebic nondysenteric colitis 006.2": '006.2' from "ICD-9-CM" display 'Amebic nondysenteric colitis'
code "ICD9 Amoebic liver abscess 006.3": '006.3' from "ICD-9-CM" display 'Amebic liver abscess'
code "ICD9 Amoebic lung abscess 006.4": '006.4' from "ICD-9-CM" display 'Amebic lung abscess'
code "ICD9 Other intestinal protozoal diseases 007": '007' from "ICD-9-CM" display 'Other protozoal intestinal diseases'
code "ICD9 Balantidiasis 007.0": '007.0' from "ICD-9-CM" display 'Balantidiasis'
code "ICD9 Giardiasis 007.1": '007.1' from "ICD-9-CM" display 'Giardiasis'
code "ICD9 Coccidiosis 007.2": '007.2' from "ICD-9-CM" display 'Coccidiosis'
code "ICD9 Intestinal trichomoniasis 007.3": '007.3' from "ICD-9-CM" display 'Intestinal trichomoniasis'
code "ICD9 Cryptosporidiosis 007.4": '007.4' from "ICD-9-CM" display 'Cryptosporidiosis'
code "ICD9 Cyclosporiasis 007.5": '007.5' from "ICD-9-CM" display 'Cyclosporiasis'
code "ICD9 Intestinal infection E coli 008": '008' from "ICD-9-CM" display 'Intestinal infections due to other organisms'
code "ICD9 E coli intestinal infection 008.0": '008.0' from "ICD-9-CM" display 'Intestinal infection due to E. coli'
code "ICD9 E coli enteropathogenic 008.00": '008.00' from "ICD-9-CM" display 'E. coli, unspecified'
code "ICD9 E coli enterotoxigenic 008.01": '008.01' from "ICD-9-CM" display 'Enteropathogenic E. coli'
code "ICD9 E coli enteroinvasive 008.02": '008.02' from "ICD-9-CM" display 'Enterotoxigenic E. coli'
code "ICD9 E coli enterohemorrhagic 008.03": '008.03' from "ICD-9-CM" display 'Enteroinvasive E. coli'
code "ICD9 E coli other 008.04": '008.04' from "ICD-9-CM" display 'Enterohemorrhagic E. coli'
code "ICD9 Arizona group bacteria 008.1": '008.1' from "ICD-9-CM" display 'Arizona group of paracolon bacilli'
code "ICD9 Aerobacter aerogenes 008.2": '008.2' from "ICD-9-CM" display 'Aerobacter aerogenes'
code "ICD9 Proteus mirabilis 008.3": '008.3' from "ICD-9-CM" display 'Proteus (mirabilis) (morganii)'
code "ICD9 Other gram negative bacteria 008.4": '008.4' from "ICD-9-CM" display 'Other specified bacteria'
code "ICD9 Pseudomonas 008.42": '008.42' from "ICD-9-CM" display 'Pseudomonas'
code "ICD9 Campylobacter 008.43": '008.43' from "ICD-9-CM" display 'Campylobacter'
code "ICD9 Yersinia enterocolitica 008.44": '008.44' from "ICD-9-CM" display 'Yersinia enterocolitica'
code "ICD9 C difficile 008.45": '008.45' from "ICD-9-CM" display 'Clostridium difficile'
code "ICD9 Other anaerobes 008.46": '008.46' from "ICD-9-CM" display 'Other anaerobes'
code "ICD9 Other gram negative 008.47": '008.47' from "ICD-9-CM" display 'Other gram-negative bacteria'
code "ICD9 Bacterial enteritis unspecified 008.5": '008.5' from "ICD-9-CM" display 'Bacterial enteritis, unspecified'
code "ICD9 Viral enteritis 008.6": '008.6' from "ICD-9-CM" display 'Enteritis due to specified virus'
code "ICD9 Rotavirus enteritis 008.61": '008.61' from "ICD-9-CM" display 'Rotavirus'
code "ICD9 Adenovirus enteritis 008.62": '008.62' from "ICD-9-CM" display 'Adenovirus'
code "ICD9 Norwalk virus enteritis 008.63": '008.63' from "ICD-9-CM" display 'Norwalk virus'
code "ICD9 Other small round virus 008.64": '008.64' from "ICD-9-CM" display 'Other small round viruses'
code "ICD9 Calicivirus 008.65": '008.65' from "ICD-9-CM" display 'Calicivirus'
code "ICD9 Astrovirus 008.66": '008.66' from "ICD-9-CM" display 'Astrovirus'
code "ICD9 Other viral enteritis 008.69": '008.69' from "ICD-9-CM" display 'Other viral enteritis'
code "ICD9 Other organism enteritis 008.8": '008.8' from "ICD-9-CM" display 'Other organism, not elsewhere classified'
code "ICD9 Ill-defined intestinal infection 009": '009' from "ICD-9-CM" display 'Ill-defined intestinal infections'
code "ICD9 Infectious colitis enteritis gastroenteritis 009.0": '009.0' from "ICD-9-CM" display 'Infectious colitis, enteritis, and gastroenteritis'
code "ICD9 Colitis enteritis gastroenteritis presumed infectious 009.1": '009.1' from "ICD-9-CM" display 'Colitis, enteritis, and gastroenteritis of presumed infectious origin'
code "ICD9 Infectious diarrhea 009.2": '009.2' from "ICD-9-CM" display 'Infectious diarrhea'
code "ICD9 Diarrhea presumed infectious 009.3": '009.3' from "ICD-9-CM" display 'Diarrhea of presumed infectious origin'
code "ICD9 Intestinal infection unspecified organism 558.9": '558.9' from "ICD-9-CM" display 'Other and unspecified noninfectious gastroenteritis and colitis'
code "ICD9 Noninfectious diarrhea 787.91": '787.91' from "ICD-9-CM" display 'Diarrhea'
code "ICD9 Noninfectious gastroenteritis 558": '558' from "ICD-9-CM" display 'Other and unspecified noninfectious gastroenteritis and colitis'

// ICD-10-CM 代碼 - 腹瀉
code "ICD10 Infectious diarrhea A09": 'A09' from "ICD-10-CM" display 'Infectious gastroenteritis and colitis, unspecified'
code "ICD10 Diarrhea K52": 'K52' from "ICD-10-CM" display 'Other and unspecified noninfective gastroenteritis and colitis'
code "ICD10 Diarrhea R19.7": 'R19.7' from "ICD-10-CM" display 'Diarrhea, unspecified'
code "ICD10 Noninfective gastroenteritis K52.9": 'K52.9' from "ICD-10-CM" display 'Noninfective gastroenteritis and colitis, unspecified'
code "ICD10 Functional diarrhea K59.1": 'K59.1' from "ICD-10-CM" display 'Functional diarrhea'
code "ICD10 Cholera A00": 'A00' from "ICD-10-CM" display 'Cholera'
code "ICD10 Typhoid fever A01.0": 'A01.0' from "ICD-10-CM" display 'Typhoid fever'
code "ICD10 Paratyphoid fever A01.1": 'A01.1' from "ICD-10-CM" display 'Paratyphoid fever A'
code "ICD10 Salmonella enteritis A02.0": 'A02.0' from "ICD-10-CM" display 'Salmonella enteritis'
code "ICD10 Shigellosis A03": 'A03' from "ICD-10-CM" display 'Shigellosis'
code "ICD10 Bacterial food poisoning A05": 'A05' from "ICD-10-CM" display 'Other bacterial foodborne intoxications'
code "ICD10 Amoebiasis A06": 'A06' from "ICD-10-CM" display 'Amoebiasis'
code "ICD10 Giardiasis A07.1": 'A07.1' from "ICD-10-CM" display 'Giardiasis [lambliasis]'
code "ICD10 Cryptosporidiosis A07.2": 'A07.2' from "ICD-10-CM" display 'Cryptosporidiosis'
code "ICD10 Rotavirus enteritis A08.0": 'A08.0' from "ICD-10-CM" display 'Rotaviral enteritis'
code "ICD10 Norovirus A08.1": 'A08.1' from "ICD-10-CM" display 'Acute gastroenteropathy due to Norwalk agent'
code "ICD10 Adenovirus enteritis A08.2": 'A08.2' from "ICD-10-CM" display 'Adenoviral enteritis'

// SNOMED CT 代碼
code "SNOMED Acute diarrhea": '111939009' from "SNOMEDCT" display 'Acute diarrhea'
code "SNOMED Infectious diarrhea": '62315008' from "SNOMEDCT" display 'Diarrhea'
code "SNOMED Gastroenteritis": '25374005' from "SNOMEDCT" display 'Gastroenteritis'
code "SNOMED Acute gastroenteritis": '41345002' from "SNOMEDCT" display 'Acute gastroenteritis'
code "SNOMED Infectious gastroenteritis": '4602008' from "SNOMEDCT" display 'Infectious gastroenteritis'
code "SNOMED Viral gastroenteritis": '70524001' from "SNOMEDCT" display 'Viral gastroenteritis'
code "SNOMED Bacterial gastroenteritis": '409825003' from "SNOMEDCT" display 'Bacterial gastroenteritis'
code "SNOMED Cholera": '63650001' from "SNOMEDCT" display 'Cholera'
code "SNOMED Typhoid fever": '4834000' from "SNOMEDCT" display 'Typhoid fever'
code "SNOMED Salmonella infection": '302231008' from "SNOMEDCT" display 'Salmonella infection'
code "SNOMED Salmonella gastroenteritis": '3992009' from "SNOMEDCT" display 'Salmonella gastroenteritis'
code "SNOMED Shigellosis": '36188001' from "SNOMEDCT" display 'Shigellosis'
code "SNOMED Campylobacter enteritis": '186024005' from "SNOMEDCT" display 'Campylobacter enteritis'
code "SNOMED E coli enteritis": '84794001' from "SNOMEDCT" display 'Enteritis due to Escherichia coli'
code "SNOMED Rotavirus gastroenteritis": '186561008' from "SNOMEDCT" display 'Rotavirus enteritis'
code "SNOMED Norovirus gastroenteritis": '52886002' from "SNOMEDCT" display 'Norwalk agent gastroenteritis'
code "SNOMED C difficile colitis": '186431008' from "SNOMEDCT" display 'Clostridium difficile colitis'
code "SNOMED Giardiasis": '4855003' from "SNOMEDCT" display 'Giardiasis'
code "SNOMED Cryptosporidiosis": '7406009' from "SNOMEDCT" display 'Cryptosporidiosis'
code "SNOMED Amoebiasis": '65415000' from "SNOMEDCT" display 'Amebiasis'

// LOINC 實驗室檢驗代碼
code "LOINC Stool culture": '625-4' from "LOINC" display 'Bacteria identified in Stool by Culture'
code "LOINC Stool O&P": '673-4' from "LOINC" display 'Ova and parasites [Presence] in Stool by Light microscopy'
code "LOINC Rotavirus Ag stool": '6575-4' from "LOINC" display 'Rotavirus Ag [Presence] in Stool'
code "LOINC Norovirus RNA": '75756-7' from "LOINC" display 'Norovirus RNA [Presence] in Stool by NAA with probe detection'
code "LOINC C difficile toxin": '17583-0' from "LOINC" display 'Clostridium difficile toxin A+B [Presence] in Stool'
code "LOINC Salmonella culture": '630-4' from "LOINC" display 'Salmonella sp identified in Stool by Culture'
code "LOINC Shigella culture": '535-5' from "LOINC" display 'Shigella sp identified in Stool by Culture'
code "LOINC Campylobacter culture": '595-9' from "LOINC" display 'Campylobacter sp identified in Stool by Culture'
code "LOINC E coli O157": '625-4' from "LOINC" display 'Escherichia coli O157 [Presence] in Stool by Culture'
code "LOINC Giardia Ag": '6571-3' from "LOINC" display 'Giardia lamblia Ag [Presence] in Stool'
code "LOINC Cryptosporidium Ag": '6568-9' from "LOINC" display 'Cryptosporidium sp Ag [Presence] in Stool'
code "LOINC Enteric pathogen panel": '82208-6' from "LOINC" display 'Enteric bacterial pathogens panel - Stool by NAA with probe detection'
code "LOINC GI pathogen panel": '75757-5' from "LOINC" display 'Bacteria and Viruses panel - Stool by NAA with probe detection'
code "LOINC Viral gastroenteritis panel": '88462-7' from "LOINC" display 'Gastrointestinal pathogens panel - Stool by NAA with probe detection'
code "LOINC Fecal leukocytes": '9829-3' from "LOINC" display 'Leukocytes [Presence] in Stool'
code "LOINC Fecal lactoferrin": '27157-7' from "LOINC" display 'Lactoferrin [Mass/volume] in Stool'
code "LOINC Stool WBC": '821-6' from "LOINC" display 'Leukocytes [#/area] in Stool by Microscopy high power field'

// ActCode 就醫類型
code "ActCode Outpatient": 'AMB' from "ActCode" display 'Ambulatory/Outpatient'
code "ActCode Emergency": 'EMER' from "ActCode" display 'Emergency'
code "ActCode Inpatient": 'IMP' from "ActCode" display 'Inpatient encounter'

// ============================================
// 值集定義
// ============================================

valueset "Acute Diarrhea ICD9 Codes": {
  "ICD9 Cholera 001",
  "ICD9 Cholera due to V cholerae 001.0",
  "ICD9 Cholera due to V cholerae el tor 001.1",
  "ICD9 Cholera unspecified 001.9",
  "ICD9 Typhoid fever 002",
  "ICD9 Typhoid fever 002.0",
  "ICD9 Paratyphoid fever A 002.1",
  "ICD9 Paratyphoid fever B 002.2",
  "ICD9 Paratyphoid fever C 002.3",
  "ICD9 Paratyphoid fever unspecified 002.9",
  "ICD9 Salmonellosis 003",
  "ICD9 Salmonella gastroenteritis 003.0",
  "ICD9 Salmonella septicemia 003.1",
  "ICD9 Salmonella localized infection 003.2",
  "ICD9 Salmonella localized infection 003.20",
  "ICD9 Salmonella localized infection 003.21",
  "ICD9 Salmonella localized infection 003.22",
  "ICD9 Salmonella localized infection 003.23",
  "ICD9 Salmonella localized infection 003.24",
  "ICD9 Salmonella localized infection 003.29",
  "ICD9 Shigellosis 004",
  "ICD9 Shigella dysenteriae 004.0",
  "ICD9 Shigella flexneri 004.1",
  "ICD9 Shigella boydii 004.2",
  "ICD9 Shigella sonnei 004.3",
  "ICD9 Shigella unspecified 004.9",
  "ICD9 Food poisoning 005",
  "ICD9 Staphylococcal food poisoning 005.0",
  "ICD9 Botulism 005.1",
  "ICD9 Food poisoning Clostridium perfringens 005.2",
  "ICD9 Food poisoning other Clostridia 005.3",
  "ICD9 Food poisoning V parahaemolyticus 005.4",
  "ICD9 Food poisoning V vulnificus 005.81",
  "ICD9 Food poisoning other organisms 005.89",
  "ICD9 Food poisoning unspecified 005.9",
  "ICD9 Amoebiasis 006",
  "ICD9 Acute amoebic dysentery 006.0",
  "ICD9 Chronic intestinal amoebiasis 006.1",
  "ICD9 Amoebic nondysenteric colitis 006.2",
  "ICD9 Amoebic liver abscess 006.3",
  "ICD9 Amoebic lung abscess 006.4",
  "ICD9 Other intestinal protozoal diseases 007",
  "ICD9 Balantidiasis 007.0",
  "ICD9 Giardiasis 007.1",
  "ICD9 Coccidiosis 007.2",
  "ICD9 Intestinal trichomoniasis 007.3",
  "ICD9 Cryptosporidiosis 007.4",
  "ICD9 Cyclosporiasis 007.5",
  "ICD9 Intestinal infection E coli 008",
  "ICD9 E coli intestinal infection 008.0",
  "ICD9 E coli enteropathogenic 008.00",
  "ICD9 E coli enterotoxigenic 008.01",
  "ICD9 E coli enteroinvasive 008.02",
  "ICD9 E coli enterohemorrhagic 008.03",
  "ICD9 E coli other 008.04",
  "ICD9 Arizona group bacteria 008.1",
  "ICD9 Aerobacter aerogenes 008.2",
  "ICD9 Proteus mirabilis 008.3",
  "ICD9 Other gram negative bacteria 008.4",
  "ICD9 Pseudomonas 008.42",
  "ICD9 Campylobacter 008.43",
  "ICD9 Yersinia enterocolitica 008.44",
  "ICD9 C difficile 008.45",
  "ICD9 Other anaerobes 008.46",
  "ICD9 Other gram negative 008.47",
  "ICD9 Bacterial enteritis unspecified 008.5",
  "ICD9 Viral enteritis 008.6",
  "ICD9 Rotavirus enteritis 008.61",
  "ICD9 Adenovirus enteritis 008.62",
  "ICD9 Norwalk virus enteritis 008.63",
  "ICD9 Other small round virus 008.64",
  "ICD9 Calicivirus 008.65",
  "ICD9 Astrovirus 008.66",
  "ICD9 Other viral enteritis 008.69",
  "ICD9 Other organism enteritis 008.8",
  "ICD9 Ill-defined intestinal infection 009",
  "ICD9 Infectious colitis enteritis gastroenteritis 009.0",
  "ICD9 Colitis enteritis gastroenteritis presumed infectious 009.1",
  "ICD9 Infectious diarrhea 009.2",
  "ICD9 Diarrhea presumed infectious 009.3",
  "ICD9 Intestinal infection unspecified organism 558.9",
  "ICD9 Noninfectious diarrhea 787.91",
  "ICD9 Noninfectious gastroenteritis 558"
}

valueset "Acute Diarrhea ICD10 Codes": {
  "ICD10 Infectious diarrhea A09",
  "ICD10 Diarrhea K52",
  "ICD10 Diarrhea R19.7",
  "ICD10 Noninfective gastroenteritis K52.9",
  "ICD10 Functional diarrhea K59.1",
  "ICD10 Cholera A00",
  "ICD10 Typhoid fever A01.0",
  "ICD10 Paratyphoid fever A01.1",
  "ICD10 Salmonella enteritis A02.0",
  "ICD10 Shigellosis A03",
  "ICD10 Bacterial food poisoning A05",
  "ICD10 Amoebiasis A06",
  "ICD10 Giardiasis A07.1",
  "ICD10 Cryptosporidiosis A07.2",
  "ICD10 Rotavirus enteritis A08.0",
  "ICD10 Norovirus A08.1",
  "ICD10 Adenovirus enteritis A08.2"
}

valueset "Acute Diarrhea SNOMED Codes": {
  "SNOMED Acute diarrhea",
  "SNOMED Infectious diarrhea",
  "SNOMED Gastroenteritis",
  "SNOMED Acute gastroenteritis",
  "SNOMED Infectious gastroenteritis",
  "SNOMED Viral gastroenteritis",
  "SNOMED Bacterial gastroenteritis",
  "SNOMED Cholera",
  "SNOMED Typhoid fever",
  "SNOMED Salmonella infection",
  "SNOMED Salmonella gastroenteritis",
  "SNOMED Shigellosis",
  "SNOMED Campylobacter enteritis",
  "SNOMED E coli enteritis",
  "SNOMED Rotavirus gastroenteritis",
  "SNOMED Norovirus gastroenteritis",
  "SNOMED C difficile colitis",
  "SNOMED Giardiasis",
  "SNOMED Cryptosporidiosis",
  "SNOMED Amoebiasis"
}

valueset "Acute Diarrhea Lab Codes": {
  "LOINC Stool culture",
  "LOINC Stool O&P",
  "LOINC Rotavirus Ag stool",
  "LOINC Norovirus RNA",
  "LOINC C difficile toxin",
  "LOINC Salmonella culture",
  "LOINC Shigella culture",
  "LOINC Campylobacter culture",
  "LOINC E coli O157",
  "LOINC Giardia Ag",
  "LOINC Cryptosporidium Ag",
  "LOINC Enteric pathogen panel",
  "LOINC GI pathogen panel",
  "LOINC Viral gastroenteritis panel",
  "LOINC Fecal leukocytes",
  "LOINC Fecal lactoferrin",
  "LOINC Stool WBC"
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

// 所有急性腹瀉診斷條件 (Condition resources)
define "Acute Diarrhea Diagnosis Conditions":
  [Condition: "Acute Diarrhea ICD9 Codes"]
    union [Condition: "Acute Diarrhea ICD10 Codes"]
    union [Condition: "Acute Diarrhea SNOMED Codes"]

// 所有急性腹瀉實驗室檢驗 (Observation resources)
define "Acute Diarrhea Lab Results":
  [Observation: "Acute Diarrhea Lab Codes"] Lab
    where Lab.status in {'final', 'amended', 'corrected'}
      and Lab.value is not null

// 所有就醫記錄 (無時間限制)
define "All Encounters":
  [Encounter] E
    where E.status = 'finished'

// 合併所有急性腹瀉相關事件 (診斷 + 檢驗)
define "All Acute Diarrhea Events":
  (
    "Acute Diarrhea Diagnosis Conditions" C
      return Tuple {
        eventDate: Coalesce(C.onset as FHIR.dateTime, C.recordedDate),
        eventType: 'Diagnosis',
        code: C.code,
        encounterId: C.encounter.reference
      }
  )
  union
  (
    "Acute Diarrhea Lab Results" L
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
define "Sorted Acute Diarrhea Events":
  "All Acute Diarrhea Events" E
    where E.eventDate is not null
    sort by eventDate

// 去重複：30天內算一次 (Episode Window Logic)
define "Unique Acute Diarrhea Episodes":
  "Sorted Acute Diarrhea Events" CurrentEvent
    let 
      encounter: "GetEncounterForEvent"(CurrentEvent),
      episodeEnd: "CalculateEpisodeEndDate"(CurrentEvent.eventDate, encounter),
      // 檢查前面是否有事件在同一 Episode 內 (Lookback)
      priorEventsInSameEpisode: 
        "Sorted Acute Diarrhea Events" PriorEvent
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
    when display contains 'rotavirus' then 'Rotavirus'
    when display contains 'norovirus' or display contains 'norwalk' then 'Norovirus'
    when display contains 'adenovirus' then 'Adenovirus'
    when display contains 'c difficile' or display contains 'clostridium difficile' then 'C. difficile'
    when display contains 'enterovirus' or display contains 'coxsackie' or display contains 'echovirus' then 'Enterovirus'
    else Coalesce(firstCoding.display.value, firstCoding.code.value)
  end

// 最終輸出結果
define "Acute Diarrhea Surveillance Results":
  "Unique Acute Diarrhea Episodes" Episode
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
  Count("Unique Acute Diarrhea Episodes")

define "Episode Count By Gender":
  {
    男性: Count("Unique Acute Diarrhea Episodes" E where "Patient Gender" = 'male'),
    女性: Count("Unique Acute Diarrhea Episodes" E where "Patient Gender" = 'female')
  }

define "Episode Count By Encounter Type":
  {
    門診: Count("Unique Acute Diarrhea Episodes" E where "GetEncounterType"(E.encounter) = '門診'),
    急診: Count("Unique Acute Diarrhea Episodes" E where "GetEncounterType"(E.encounter) = '急診'),
    住院: Count("Unique Acute Diarrhea Episodes" E where "GetEncounterType"(E.encounter) = '住院')
  }
