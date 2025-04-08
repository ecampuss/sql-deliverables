WITH fbl3n AS ( 
SELECT
   bseg.bukrs AS "Comp. Code"
   ,bseg.werks AS "Plant"
   ,bseg.kunnr AS "Customer"
   ,bseg.lifnr AS "Vendor"
   ,bseg.vbund AS "Trading Partner"
   ,bseg.zuonr AS "Assignment"
   ,bseg.hkont AS "G/L Account"
   ,bkpf.usnam AS "User name"
   ,bseg.bupla AS "Business Place"
   ,bkpf.blart AS "Document Type"
   ,bkpf.waers AS "Currency"
   ,bseg.belnr AS "Document Number"
   ,bseg.buzei AS "Line Item"
   ,CONCAT(YEAR(TRY_TO_DATE(bkpf.budat, 'YYYYMMDD')),'/',MONTH(TRY_TO_DATE(bkpf.budat, 'YYYYMMDD'))) AS "Year/Month"
   ,TRY_TO_DATE(bkpf.budat, 'YYYYMMDD') AS "Posting Date"
   ,TRY_TO_DATE(bkpf.bldat, 'YYYYMMDD') AS "Document Date"
   ,bseg.kostl AS "Cost Center"
   ,IFF(bseg.shkzg = 'S', bseg.dmbtr, (bseg.dmbtr * -1)) AS "Amount in local cur."
   ,IFF(bseg.shkzg = 'S', bseg.dmbe3, (bseg.dmbe3 * -1)) AS "Valuated amt loc curr 3"
   ,bkpf.xblnr AS "Reference"
   ,bseg.sgtxt AS "Text"
   ,DATEDIFF(DAY, "Document Date", GETDATE()) AS "Aging"
   ,IFF("Aging" < 30, 'Current'
   ,IFF("Aging" = 30, 'Over 30 Days'
   ,IFF("Aging" > 30 AND "Aging" <= 59, '31-59 Days'
   ,IFF("Aging" > 59 AND "Aging" <= 90, '60-90 Days*'
   ,IFF("Aging" > 90, 'Over 91 Days*', ''))))) AS "Aging Category"
   ,'Still Open Item' AS "Open Item Category"
FROM 
    DW_STAGING.SAP_SABEV.BSEG 
INNER JOIN DW_STAGING.SAP_SABEV.BKPF bkpf
    ON bseg.belnr = bkpf.belnr AND bseg.bukrs = bkpf.bukrs AND bseg.gjahr = bkpf.gjahr AND bkpf.mandt = '300'
WHERE
    bseg.mandt = '300'
    AND bseg.bukrs IN ('1000','1001','1002','1003','1004','1005','1006','1007')
    AND bseg.hkont IN ('0112410101', '0212200101')
    AND bseg.vbund IN ('121001', '121002', '121003', '121004', '121005', '121006', '121007', '126020')
    AND bkpf.budat >= 20140101
    AND bseg.augbl = ''
HAVING
    CONCAT(YEAR(TRY_TO_DATE(bkpf.budat, 'YYYYMMDD')),'/',MONTH(TRY_TO_DATE(bkpf.budat, 'YYYYMMDD'))) <> CONCAT(YEAR(CURRENT_DATE()),'/',MONTH(CURRENT_DATE()))

    UNION ALL

SELECT
   bseg.bukrs AS "Comp. Code"
   ,bseg.werks AS "Plant"
   ,bseg.kunnr AS "Customer"
   ,bseg.lifnr AS "Vendor"
   ,bseg.vbund AS "Trading Partner"
   ,bseg.zuonr AS "Assignment"
   ,bseg.hkont AS "G/L Account"
   ,bkpf.usnam AS "User name"
   ,bseg.bupla AS "Business Place"
   ,bkpf.blart AS "Document Type"
   ,bkpf.waers AS "Currency"
   ,bseg.belnr AS "Document Number"
   ,bseg.buzei AS "Line Item"
   ,CONCAT(YEAR(TRY_TO_DATE(bkpf.budat, 'YYYYMMDD')),'/',MONTH(TRY_TO_DATE(bkpf.budat, 'YYYYMMDD'))) AS "Year/Month"
   ,TRY_TO_DATE(bkpf.budat, 'YYYYMMDD') AS "Posting Date"
   ,TRY_TO_DATE(bkpf.bldat, 'YYYYMMDD') AS "Document Date"
   ,bseg.kostl AS "Cost Center"
   ,IFF(bseg.shkzg = 'S', bseg.dmbtr, (bseg.dmbtr * -1)) AS "Amount in local cur."
   ,IFF(bseg.shkzg = 'S', bseg.dmbe3, (bseg.dmbe3 * -1)) AS "Valuated amt loc curr 3"
   ,bkpf.xblnr AS "Reference"
   ,bseg.sgtxt AS "Text"
   ,DATEDIFF(DAY, "Document Date", GETDATE()) AS "Aging"
   ,IFF("Aging" < 30, 'Current'
   ,IFF("Aging" = 30, 'Over 30 Days'
   ,IFF("Aging" > 30 AND "Aging" <= 59, '31-59 Days'
   ,IFF("Aging" > 59 AND "Aging" <= 90, '60-90 Days*'
   ,IFF("Aging" > 90, 'Over 91 Days*', ''))))) AS "Aging Category"
   ,'Open Item cleared in current month' AS "Open Item Category"
FROM 
    DW_STAGING.SAP_SABEV.BSEG 
INNER JOIN DW_STAGING.SAP_SABEV.BKPF bkpf
    ON bseg.belnr = bkpf.belnr AND bseg.bukrs = bkpf.bukrs AND bseg.gjahr = bkpf.gjahr AND bkpf.mandt = '300'
WHERE
    bseg.mandt = '300'
    AND bseg.bukrs IN ('1000','1001','1002','1003','1004','1005','1006','1007')
    AND bseg.hkont IN ('0112410101', '0212200101')
    AND bseg.vbund IN ('121001', '121002', '121003', '121004', '121005', '121006', '121007', '126020')
    AND bkpf.budat >= 20140101
    AND CONCAT(YEAR(TRY_TO_DATE(bseg.augdt)),'/',MONTH(TRY_TO_DATE(bseg.augdt))) = CONCAT(YEAR(CURRENT_DATE()),'/',MONTH(CURRENT_DATE()))
HAVING
    CONCAT(YEAR(TRY_TO_DATE(bkpf.budat, 'YYYYMMDD')),'/',MONTH(TRY_TO_DATE(bkpf.budat, 'YYYYMMDD'))) <> CONCAT(YEAR(CURRENT_DATE()),'/',MONTH(CURRENT_DATE()))
),

ztco0018_prep AS (
SELECT
    ce1bcsa.perde AS "Period"
    ,TRY_TO_DATE(vbrk.fkdat, 'YYYYMMDD') AS "Data fatura"
    ,ce1bcsa.artnr AS "Material Number"
    ,ce1bcsa.wwnnf AS "Nota Fiscal"
    ,ce1bcsa.bukrs AS "Comp. Code"
    ,ce1bcsa.werks AS "Plant"
    ,ce1bcsa.kdgrp AS "Customer Group"
    ,ce1bcsa.kndnr AS "Customer"
    ,ce1bcsa.mtart AS "Material Type"
    ,ce1bcsa.matkl AS "Material Group"
    ,ce1bcsa.VV211 AS "Sales Quantity"
    ,ce1bcsa.vv211_me AS "Base Unit of Measure"
    ,ce1bcsa.vv100 AS "Sales"
    ,ce1bcsa.vv140 AS "UNUSED Rebate 1"
    ,ce1bcsa.vv210 AS "UNUSED Condition 2"
    ,ce1bcsa.vv180 AS "UNEXPECTED SD"
    ,ce1bcsa.vv170 AS "UNUSED Rebate 4"
    ,ce1bcsa.rec_waers AS "Currency of record"
    ,kna1.name1 AS "Name 1"
    ,vbrk.fksto AS "Documento Estornado"
FROM "DW_STAGING"."SAP_SABEV"."VBRK" vbrk
    INNER JOIN "DW_STAGING"."SAP_SABEV"."VBRP" vbrp ON vbrp.vbeln = vbrk.vbeln AND vbrp.mandt = '300'
    INNER JOIN "DW_STAGING"."SAP_SABEV"."T001" t001 ON t001.bukrs = vbrk.bukrs AND t001.mandt = '300'
    INNER JOIN "DW_STAGING"."SAP_SABEV"."KNA1" kna1 ON kna1.kunnr = vbrk.kunag AND kna1.mandt = '300'
    LEFT JOIN "DW_STAGING"."SAP_SABEV"."KNVV" knvv ON knvv.kunnr = kna1.kunnr AND knvv.vkorg = vbrk.vkorg AND knvv.vtweg = vbrk.vtweg AND knvv.spart = vbrk.spart AND knvv.mandt = '300'
    INNER JOIN "DW_STAGING"."SAP_SABEV"."MARA" mara ON mara.matnr = vbrp.matnr AND mara.mandt = '300'
    LEFT JOIN "DW_STAGING"."SAP_SABEV"."MVKE" mvke ON mvke.vkorg = vbrk.vkorg AND mvke.vtweg = vbrk.vtweg AND mvke.matnr = vbrp.matnr AND mvke.mandt = '300'
    INNER JOIN "DW_STAGING"."SAP_SABEV"."CE1BCSA" ce1bcsa ON vbrp.vbeln = ce1bcsa.rbeln AND vbrp.posnr = ce1bcsa.rposn AND ce1bcsa.paledger = '01' AND ce1bcsa.mandt = '300'
    LEFT JOIN "DW_STAGING"."SAP_SABEV"."T023T" t023t ON t023t.matkl = mara.matkl AND t023t.mandt = '300' AND t023t.SPRAS = 'P' 
    LEFT JOIN "DW_STAGING"."SAP_SABEV"."MAKT" makt ON mara.matnr = makt.matnr AND makt.mandt = '300' AND makt.SPRAS = 'P'
WHERE
    vbrk.bukrs IN ('1000', '1001', '1002', '1003', '1004', '1005', '1006', '1007', '1008', '1021', '1022', '1025')
    AND ce1bcsa.rec_waers IN ('USD')
    AND vbrk.fkdat >= 20170601
    AND CONCAT(YEAR(TRY_TO_DATE(vbrk.fkdat, 'YYYYMMDD')),MONTH(TRY_TO_DATE(vbrk.fkdat, 'YYYYMMDD'))) <> CONCAT(YEAR(CURRENT_DATE()),MONTH(CURRENT_DATE()))
    AND "Sales Quantity" <> '0.000'
    AND "Nota Fiscal" <> ' '
),

--ADD TO REPORT - ZTCO0018 BASE
ztco0018 AS (
SELECT 
    z."Nota Fiscal"
    ,z."Comp. Code"
    ,z."Plant"
    ,z."Customer Group"
    ,z."Customer"
    ,z."Name 1"
    ,z."Material Type"
    ,z."Material Group"
    ,z."Material Number"
    ,z."Period"
    ,z."Data fatura"
    ,z."Sales Quantity"
    ,z."Base Unit of Measure"
    ,z."Sales" AS "Sum Sales"
    ,z."UNUSED Rebate 1"
    ,z."UNUSED Condition 2"
    ,z."UNEXPECTED SD"
    ,z."UNUSED Rebate 4"
    ,(z."Sales" - z."UNUSED Condition 2" - z."UNEXPECTED SD" - z."UNUSED Rebate 4") AS "Revenue/Net Revenue"
    ,z."Currency of record"
FROM 
    ztco0018_prep z   
),

--ADD TO REPORT - ZTCO0018 BASE FROM PREVIOUS MONTH - SEPARATED FILE - TRANSITO LAYOUT
ztco0018_previous_month AS (
SELECT 
    z."Nota Fiscal"
    ,z."Comp. Code"
    ,z."Plant"
    ,z."Customer Group"
    ,z."Customer"
    ,z."Name 1"
    ,z."Material Type"
    ,z."Material Group"
    ,z."Material Number"
    ,z."Period"
    ,z."Data fatura"
    ,z."Sales Quantity"
    ,z."Base Unit of Measure"
    ,z."Sales" AS "Sum Sales"
    ,z."UNUSED Rebate 1"
    ,z."UNUSED Condition 2"
    ,z."UNEXPECTED SD"
    ,z."UNUSED Rebate 4"
    ,(z."Sales" - z."UNUSED Condition 2" - z."UNEXPECTED SD" - z."UNUSED Rebate 4") AS "Revenue/Net Revenue"
    ,z."Currency of record"
FROM 
    ztco0018_prep z 
WHERE
    IFF(MONTH(CURRENT_DATE()) = 1, YEAR(TRY_TO_DATE(z."Data fatura")) = YEAR(CURRENT_DATE())-1 AND MONTH(TRY_TO_DATE(z."Data fatura")) = 12, YEAR(TRY_TO_DATE(z."Data fatura")) = YEAR(CURRENT_DATE()) AND MONTH(TRY_TO_DATE(z."Data fatura")) = MONTH(CURRENT_DATE())-1 )
),

doc_balance AS (
SELECT 
   f."Reference"
   ,SUM(f."Amount in local cur.") AS "Balance Amount"
   ,IFF("Balance Amount" = 0, 'ZERO', 'BALANCE') AS "Balance Result"
FROM 
    fbl3n f
GROUP BY ALL
ORDER BY 2
),

doc_balance_preanalysis AS (
SELECT
   f."Comp. Code"
   ,f."Customer"
   ,f."Vendor"
   ,f."Trading Partner"
   ,f."Assignment"
   ,f."G/L Account"
   ,f."User name"
   ,f."Business Place"
   ,f."Document Type"
   ,f."Currency"
   ,f."Document Number"
   ,f."Year/Month"
   ,f."Posting Date"
   ,f."Document Date"
   ,f."Cost Center"
   ,f."Amount in local cur."
   ,f."Valuated amt loc curr 3"
   ,f."Reference"
   ,f."Text"
   ,f."Aging"
   ,f."Aging Category"
   ,db."Balance Result"
FROM 
    fbl3n f
INNER JOIN doc_balance db ON f."Reference" = db."Reference"
WHERE
    f."Document Type" NOT IN ('DG', 'DR', 'R1', 'KR')
),

debit_notes AS (
SELECT
   f."Comp. Code"
   ,f."Customer"
   ,f."Vendor"
   ,f."Trading Partner"
   ,f."Assignment"
   ,f."G/L Account"
   ,f."User name"
   ,f."Business Place"
   ,f."Document Type"
   ,f."Currency"
   ,f."Document Number"
   ,f."Year/Month"
   ,f."Posting Date"
   ,f."Document Date"
   ,f."Cost Center"
   ,f."Amount in local cur."
   ,f."Valuated amt loc curr 3"
   ,f."Reference"
   ,CASE
        WHEN f."Reference" LIKE 'DEBIT NOTE %' THEN RIGHT(f."Reference",LEN(f."Reference") - 11)
        WHEN f."Reference" LIKE 'ND %' THEN RIGHT(f."Reference",LEN(f."Reference") - 3)
        ELSE f."Reference"
    END AS "Reference - Debit Note"
   ,f."Text"
   ,f."Aging"
   ,f."Aging Category"
FROM 
    fbl3n f
WHERE
    "Document Type" IN ('DR','RE', 'KR')
),

debit_notes_balance AS (
SELECT 
    dn."Reference - Debit Note"
    ,SUM(dn."Amount in local cur.") AS "Balance Amount"
    ,IFF("Balance Amount" = 0, 'ZERO', 'BALANCE') AS "Balance Result"
FROM 
    debit_notes dn
GROUP BY ALL
ORDER BY 2
),

debit_notes_balance_analysis AS (
SELECT
   dn."Comp. Code"
   ,dn."Customer"
   ,dn."Vendor"
   ,dn."Trading Partner"
   ,dn."Assignment"
   ,dn."G/L Account"
   ,dn."User name"
   ,dn."Business Place"
   ,dn."Document Type"
   ,dn."Currency"
   ,dn."Document Number"
   ,dn."Year/Month"
   ,dn."Posting Date"
   ,dn."Document Date"
   ,dn."Cost Center"
   ,dn."Amount in local cur."
   ,dn."Valuated amt loc curr 3"
   ,dn."Reference"
   ,dn."Text"
   ,dn."Aging"
   ,dn."Aging Category"
   ,dnb."Balance Result"
FROM 
    debit_notes dn
INNER JOIN debit_notes_balance dnb ON dn."Reference - Debit Note" = dnb."Reference - Debit Note"
),

credit_notes AS (
SELECT
   f."Comp. Code"
   ,f."Customer"
   ,f."Vendor"
   ,f."Trading Partner"
   ,f."Assignment"
   ,f."G/L Account"
   ,f."User name"
   ,f."Business Place"
   ,f."Document Type"
   ,f."Currency"
   ,f."Document Number"
   ,f."Year/Month"
   ,f."Posting Date"
   ,f."Document Date"
   ,f."Cost Center"
   ,f."Amount in local cur."
   ,f."Valuated amt loc curr 3"
   ,f."Reference"
   ,CASE
        WHEN f."Reference" LIKE 'NC %' THEN RIGHT(f."Reference",LEN(f."Reference") - 3)
        ELSE f."Reference"
    END AS "Reference - Credit Note"
   ,f."Text"
   ,f."Aging"
   ,f."Aging Category"
FROM 
    fbl3n f
WHERE
    "Document Type" IN ('DG', 'R1')
),

credit_notes_balance AS (
SELECT 
    cr."Reference - Credit Note"
    ,SUM(cr."Amount in local cur.") AS "Balance Amount"
    ,IFF("Balance Amount" = 0, 'ZERO', 'BALANCE') AS "Balance Result"
FROM 
    credit_notes cr
GROUP BY ALL
ORDER BY 2
),

credit_notes_balance_analysis AS (
SELECT
   cn."Comp. Code"
   ,cn."Customer"
   ,cn."Vendor"
   ,cn."Trading Partner"
   ,cn."Assignment"
   ,cn."G/L Account"
   ,cn."User name"
   ,cn."Business Place"
   ,cn."Document Type"
   ,cn."Currency"
   ,cn."Document Number"
   ,cn."Year/Month"
   ,cn."Posting Date"
   ,cn."Document Date"
   ,cn."Cost Center"
   ,cn."Amount in local cur."
   ,cn."Valuated amt loc curr 3"
   ,cn."Reference"
   ,cn."Text"
   ,cn."Aging"
   ,cn."Aging Category"
   ,cnb."Balance Result"
FROM 
    credit_notes cn
INNER JOIN credit_notes_balance cnb ON cn."Reference - Credit Note" = cnb."Reference - Credit Note"
),

doc_balance_textcheck AS (
SELECT
    dba."Text"
    ,SUM(dba."Amount in local cur.") AS "Balance Amount"
    ,IFF("Balance Amount" BETWEEN -0.1 AND 0.1, 'ZERO', 'BALANCE') AS "Balance Text Result"
FROM 
    doc_balance_preanalysis dba
WHERE
    dba."Balance Result" = 'BALANCE'
GROUP BY ALL
),

--ADD TO REPORT - ZERO BASE MONTH
zero_balance_analysis AS (
SELECT
   dba."Comp. Code"
   ,dba."Customer"
   ,dba."Vendor"
   ,dba."Trading Partner"
   ,dba."Assignment"
   ,dba."G/L Account"
   ,dba."User name"
   ,dba."Business Place"
   ,dba."Document Type"
   ,dba."Currency"
   ,dba."Document Number"
   ,dba."Year/Month"
   ,dba."Posting Date"
   ,dba."Document Date"
   ,dba."Cost Center"
   ,dba."Amount in local cur."
   ,dba."Valuated amt loc curr 3"
   ,dba."Reference"
   ,dba."Text"
   ,dba."Aging"
   ,dba."Aging Category"
   ,dba."Balance Result"
   ,'Reference' AS "Balance Type"
FROM 
    doc_balance_preanalysis dba
WHERE
    dba."Balance Result" = 'ZERO'

    UNION ALL

SELECT
   dba."Comp. Code"
   ,dba."Customer"
   ,dba."Vendor"
   ,dba."Trading Partner"
   ,dba."Assignment"
   ,dba."G/L Account"
   ,dba."User name"
   ,dba."Business Place"
   ,dba."Document Type"
   ,dba."Currency"
   ,dba."Document Number"
   ,dba."Year/Month"
   ,dba."Posting Date"
   ,dba."Document Date"
   ,dba."Cost Center"
   ,dba."Amount in local cur."
   ,dba."Valuated amt loc curr 3"
   ,dba."Reference"
   ,dba."Text"
   ,dba."Aging"
   ,dba."Aging Category"
   ,dbt."Balance Text Result" AS "Balance Result"
   ,'Text' AS "Balance Type"
FROM 
    doc_balance_preanalysis dba
INNER JOIN doc_balance_textcheck dbt ON dba."Text" = dbt."Text"
WHERE
    dbt."Balance Text Result" = 'ZERO'

    UNION ALL

SELECT
    cnba."Comp. Code"
    ,cnba."Customer"
    ,cnba."Vendor"
    ,cnba."Trading Partner"
    ,cnba."Assignment"
    ,cnba."G/L Account"
    ,cnba."User name"
    ,cnba."Business Place"
    ,cnba."Document Type"
    ,cnba."Currency"
    ,cnba."Document Number"
    ,cnba."Year/Month"
    ,cnba."Posting Date"
    ,cnba."Document Date"
    ,cnba."Cost Center"
    ,cnba."Amount in local cur."
    ,cnba."Valuated amt loc curr 3"
    ,cnba."Reference"
    ,cnba."Text"
    ,cnba."Aging"
    ,cnba."Aging Category"
    ,cnba."Balance Result"
    ,'Reference' AS "Balance Type"
FROM 
    credit_notes_balance_analysis cnba
WHERE
    cnba."Balance Result" = 'ZERO'
    
    UNION ALL

SELECT
    dnba."Comp. Code"
    ,dnba."Customer"
    ,dnba."Vendor"
    ,dnba."Trading Partner"
    ,dnba."Assignment"
    ,dnba."G/L Account"
    ,dnba."User name"
    ,dnba."Business Place"
    ,dnba."Document Type"
    ,dnba."Currency"
    ,dnba."Document Number"
    ,dnba."Year/Month"
    ,dnba."Posting Date"
    ,dnba."Document Date"
    ,dnba."Cost Center"
    ,dnba."Amount in local cur."
    ,dnba."Valuated amt loc curr 3"
    ,dnba."Reference"
    ,dnba."Text"
    ,dnba."Aging"
    ,dnba."Aging Category"
    ,dnba."Balance Result"
    ,'Reference' AS "Balance Type"
FROM 
    debit_notes_balance_analysis dnba
WHERE
    dnba."Balance Result" = 'ZERO'
),

doc_balance_analysis AS (
SELECT
   dba."Comp. Code"
   ,dba."Customer"
   ,dba."Vendor"
   ,dba."Trading Partner"
   ,dba."Assignment"
   ,dba."G/L Account"
   ,dba."User name"
   ,dba."Business Place"
   ,dba."Document Type"
   ,dba."Currency"
   ,dba."Document Number"
   ,dba."Year/Month"
   ,dba."Posting Date"
   ,dba."Document Date"
   ,dba."Cost Center"
   ,dba."Amount in local cur."
   ,dba."Valuated amt loc curr 3"
   ,dba."Reference"
   ,dba."Text"
   ,dba."Aging"
   ,dba."Aging Category"
   ,dba."Balance Result"
   ,'Reference' AS "Balance Type"
FROM 
    doc_balance_preanalysis dba
WHERE
    dba."Balance Result" <> 'ZERO'

    UNION ALL

SELECT
   dba."Comp. Code"
   ,dba."Customer"
   ,dba."Vendor"
   ,dba."Trading Partner"
   ,dba."Assignment"
   ,dba."G/L Account"
   ,dba."User name"
   ,dba."Business Place"
   ,dba."Document Type"
   ,dba."Currency"
   ,dba."Document Number"
   ,dba."Year/Month"
   ,dba."Posting Date"
   ,dba."Document Date"
   ,dba."Cost Center"
   ,dba."Amount in local cur."
   ,dba."Valuated amt loc curr 3"
   ,dba."Reference"
   ,dba."Text"
   ,dba."Aging"
   ,dba."Aging Category"
   ,dbt."Balance Text Result" AS "Balance Result"
   ,'Text' AS "Balance Type"
FROM 
    doc_balance_preanalysis dba
INNER JOIN doc_balance_textcheck dbt ON dba."Text" = dbt."Text"
WHERE
    dbt."Balance Text Result" <> 'ZERO'

    UNION ALL

SELECT
    cnba."Comp. Code"
    ,cnba."Customer"
    ,cnba."Vendor"
    ,cnba."Trading Partner"
    ,cnba."Assignment"
    ,cnba."G/L Account"
    ,cnba."User name"
    ,cnba."Business Place"
    ,cnba."Document Type"
    ,cnba."Currency"
    ,cnba."Document Number"
    ,cnba."Year/Month"
    ,cnba."Posting Date"
    ,cnba."Document Date"
    ,cnba."Cost Center"
    ,cnba."Amount in local cur."
    ,cnba."Valuated amt loc curr 3"
    ,cnba."Reference"
    ,cnba."Text"
    ,cnba."Aging"
    ,cnba."Aging Category"
    ,cnba."Balance Result"
    ,'Reference' AS "Balance Type"
FROM 
    credit_notes_balance_analysis cnba
WHERE
    cnba."Balance Result" <> 'ZERO'
    
    UNION ALL

SELECT
    dnba."Comp. Code"
    ,dnba."Customer"
    ,dnba."Vendor"
    ,dnba."Trading Partner"
    ,dnba."Assignment"
    ,dnba."G/L Account"
    ,dnba."User name"
    ,dnba."Business Place"
    ,dnba."Document Type"
    ,dnba."Currency"
    ,dnba."Document Number"
    ,dnba."Year/Month"
    ,dnba."Posting Date"
    ,dnba."Document Date"
    ,dnba."Cost Center"
    ,dnba."Amount in local cur."
    ,dnba."Valuated amt loc curr 3"
    ,dnba."Reference"
    ,dnba."Text"
    ,dnba."Aging"
    ,dnba."Aging Category"
    ,dnba."Balance Result"
    ,'Reference' AS "Balance Type"
FROM 
    debit_notes_balance_analysis dnba
WHERE
    dnba."Balance Result" <> 'ZERO'
),

zero_balances_double_check AS (
SELECT
   z."Comp. Code"
   ,z."Customer"
   ,z."Vendor"
   ,z."Trading Partner"
   ,z."Assignment"
   ,z."G/L Account"
   ,z."User name"
   ,z."Business Place"
   ,z."Document Type"
   ,z."Currency"
   ,z."Document Number"
   ,z."Year/Month"
   ,z."Posting Date"
   ,z."Document Date"
   ,z."Cost Center"
   ,z."Amount in local cur."
   ,z."Valuated amt loc curr 3"
   ,z."Reference"
   ,z."Text"
   ,z."Aging"
   ,z."Aging Category"
   ,z."Balance Result"
   ,z."Balance Type"
FROM 
    doc_balance_analysis z
WHERE
    CONCAT(z."Comp. Code", z."Document Number", z."Year/Month") NOT IN (SELECT CONCAT(dba."Comp. Code", dba."Document Number", dba."Year/Month") FROM zero_balance_analysis dba)
),

--this table prepares the layout of the ztco0018
ztco0018_amounts AS (
SELECT
    z."Nota Fiscal"
    ,z."Comp. Code"
    ,z."Plant"
    ,z."Customer Group"
    ,z."Data fatura"
    ,z."Material Group"
    ,SUM(z."Revenue/Net Revenue") AS "Revenue/Net Revenue"
    ,SUM(z."Sales Quantity") AS "Quantity"
    ,SUM(z."Sum Sales" + z."UNUSED Rebate 1") AS "Sales + Rebate 1"  
FROM
    ztco0018 z
GROUP BY ALL
HAVING
    SUM(z."Revenue/Net Revenue") <> 0
),

--ADD TO REPORT - FBL3N WITHOUT ZEROS
fbl3n_amounts AS (
SELECT
    f."Comp. Code"
   ,f."Customer"
   ,f."Vendor"
   ,f."Trading Partner"
   ,f."Assignment"
   ,f."G/L Account"
   ,f."User name"
   ,f."Business Place"
   ,f."Document Type"
   ,f."Currency"
   ,f."Document Number"
   ,f."Line Item"
   ,f."Year/Month"
   ,f."Posting Date"
   ,f."Document Date"
   ,f."Cost Center"
   ,f."Amount in local cur."
   ,f."Valuated amt loc curr 3"
   ,f."Reference"
   ,f."Text"
   ,f."Aging"
   ,f."Aging Category"
FROM
    fbl3n f
WHERE
    f."Document Number" IN (SELECT "Document Number" FROM zero_balances_double_check)
),

--ADD TO REPORT - IN
ztco0018_pre_summary AS (
SELECT
    z."Nota Fiscal"
    ,z."Comp. Code"
    ,z."Plant"
    ,z."Data fatura"
    ,f."Document Number"
    ,f."Document Date"
    ,z."Material Group"
    ,z."Quantity"
    ,z."Revenue/Net Revenue"
    ,z."Sales + Rebate 1"
    ,f."Valuated amt loc curr 3"
    ,(z."Sales + Rebate 1" - f."Valuated amt loc curr 3") AS "Check"
    ,CONCAT(f."Reference", f."Valuated amt loc curr 3") AS "PK1"
    ,CONCAT(z."Nota Fiscal", z."Sales + Rebate 1") AS "PK2"
FROM
    ztco0018_amounts z 
--INNER JOIN fbl3n_amounts f ON CONCAT(f."Reference", f."Valuated amt loc curr 3") = CONCAT(z."Nota Fiscal", z."Sales + Rebate 1")
INNER JOIN fbl3n_amounts f ON f."Reference" = z."Nota Fiscal"
),

ztco0018_summary AS (
SELECT
    z."Nota Fiscal"
    ,z."Comp. Code"
    ,z."Plant"
    ,z."Customer Group"
    ,z."Data fatura"
    ,f."Document Number"
    ,f."Document Date"
    ,z."Material Group"
    ,IFF(z."Data fatura" = f."Document Date", 'Same Dates', 'Diff Dates') AS "Dates Comparison"
    ,z."Quantity"
    ,z."Revenue/Net Revenue"
    ,z."Sales + Rebate 1"
    ,f."Valuated amt loc curr 3"
    ,(z."Sales + Rebate 1" - f."Valuated amt loc curr 3") AS "Check"
    ,IFF("Check" BETWEEN -0.1 AND 0.1, 'Zero Difference', 'Difference') AS "Balance Check"
FROM
    ztco0018_amounts z 
INNER JOIN fbl3n_amounts f ON f."Reference" = z."Nota Fiscal"
WHERE
    "Dates Comparison" = 'Same Dates'
    AND "Balance Check" = 'Zero Difference'
),

--ADD TO REPORT - SAP BASE
sap_base AS (
SELECT
    f."Comp. Code"
   ,f."Customer"
   ,z."Customer Group"
   ,f."Vendor"
   ,f."Trading Partner"
   ,f."Assignment"
   ,f."G/L Account"
   ,f."User name"
   ,f."Business Place"
   ,f."Document Type"
   ,f."Currency"
   ,f."Document Number"
   ,f."Line Item"
   ,f."Year/Month"
   ,f."Posting Date"
   ,f."Document Date"
   ,f."Cost Center"
   ,f."Amount in local cur."
   ,f."Valuated amt loc curr 3"
   ,f."Reference"
   ,f."Text"
   ,f."Aging"
   ,f."Aging Category"
   ,z."Material Group" AS "Produto"
   ,IFF(IFNULL(z."Material Group", 1) = 1, 'ACERTO CTB', 
        IFF(z."Material Group" LIKE '8%', z."Material Group",
        IFF(z."Material Group" LIKE '9%', z."Material Group",
        IFF(z."Material Group" LIKE 'A%', z."Material Group",
            'OTHER')))) AS "Produto2"
   ,IFF(IFNULL(z."Material Group", 1) = 1, 0, z."Quantity") AS "Quantity"
   ,IFF(IFNULL(z."Material Group", 1) = 1, f."Valuated amt loc curr 3", z."Revenue/Net Revenue") AS "Revenue/Net Revenue"
FROM
    fbl3n_amounts f
LEFT JOIN ztco0018_summary z ON f."Document Number" = z."Document Number" AND f."Reference" = z."Nota Fiscal" AND f."Comp. Code" = z."Comp. Code"
),

fbl3n_pivot AS(
SELECT
    IFF(f."Produto" <> NULL, f."Produto", f."Produto2") AS "Produto"
    ,f."Customer Group"
    ,SUM(f."Quantity") AS "Sum Quantity"
    ,SUM(f."Amount in local cur.") AS "Sum Amount in local cur."
    ,SUM(f."Valuated amt loc curr 3") AS "Sum Valuated amt loc curr 3"
    ,SUM(f."Revenue/Net Revenue") AS "Total Net Revenue"
FROM 
    sap_base f
GROUP BY ALL
),

pre_pivot AS (
SELECT
    CASE
        WHEN f."Produto" LIKE '8%' THEN f."Produto"
        WHEN f."Produto" LIKE '9%' THEN f."Produto"
        WHEN f."Produto" LIKE 'A%' THEN f."Produto"
        ELSE 'OTHER'
    END AS "Produto"
    ,f."Customer Group"
    ,f."Sum Quantity"
    ,f."Sum Amount in local cur."
    ,f."Sum Valuated amt loc curr 3"
    ,f."Total Net Revenue"
    ,ROUND(DIV0(f."Total Net Revenue", f."Sum Quantity"), 2) AS "Average Cost"
FROM 
    fbl3n_pivot f
),

pivot AS (
SELECT
    f."Produto"
    ,SUM(f."Sum Quantity") AS "Sum Quantity"
    ,SUM(f."Sum Amount in local cur.") AS "Sum Amount in local cur."
    ,SUM(f."Sum Valuated amt loc curr 3") AS "Sum Valuated amt loc curr 3"
    ,SUM(f."Total Net Revenue") AS "Total Net Revenue"
    --,SUM(f."Average Cost") AS "Average Cost"
FROM 
    pre_pivot f
GROUP BY ALL
)

--ADD TO THE REPORT - PIVOT
SELECT
    p."Produto"
    ,p."Sum Quantity"
    ,p."Sum Amount in local cur."
    ,p."Sum Valuated amt loc curr 3"
    ,p."Total Net Revenue"
    ,ROUND(DIV0(p."Total Net Revenue", "Sum Quantity"),2) AS "Average Cost"
FROM 
    pivot p
GROUP BY ALL
ORDER BY 1
;