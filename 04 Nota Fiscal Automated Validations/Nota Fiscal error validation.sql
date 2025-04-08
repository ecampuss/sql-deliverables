-- GRC side

--table to store NF data from GRC environment
WITH grc_data01 AS (
SELECT
    chave_de_acesso AS "Chave 1"
    ,CONCAT(LPAD(numero_nfe, 9, 0), LPAD(cnpj_emitente,14, 0)) AS "Chave 2"
    ,processo AS "Processo"
    ,chave_de_acesso AS "Chave de Acesso"
    ,valor_total_do_frete AS "Valor Total do Frete"
    ,valor_total_do_seguro AS "Valor Total do Seguro"
    ,valor_total_do_desconto AS "Valor Total do Desconto"
    ,outros_custos_adicionais AS "Outros Custos Adicionais"
    ,LPAD(cnpj_dest,14, 0) AS "CNPJ Destinatário"
    ,LPAD(cnpj_emitente,14, 0) AS "CNPJ Emitente"
    ,valor_total_incl_impostos AS "Valor Total Incl Impostos"
    ,data_documento AS "Data Documento"
    ,numero_protocolo AS "Numero Protocolo"
    ,LPAD(numero_nfe, 9, 0) AS "Num NF"
    ,TRY_TO_DATE(LEFT(data_hora_emissao, 8), 'YYYYMMDD') AS "Data Emissao" 
FROM 
    DW_STAGING.RPA.SA_G3P_INVOICES grc
WHERE
    YEAR("Data Emissao") >= YEAR(GETDATE())-1 
),

-- SAP side

--table to store NF data from SAP environment
ecc_data01 AS (
SELECT 
    j_1bnfdoc.docnum AS "Doc Num"
    ,j_1bnfdoc.nftot AS "Valor Incl. Impostos"
    ,j_1bnflin.netwr AS "Vlr Item"
    ,CONCAT(j_1bnfe_active.regio, j_1bnfe_active.nfyear, j_1bnfe_active.nfmonth, j_1bnfe_active.stcd1, j_1bnfe_active.model, j_1bnfe_active.serie, j_1bnfe_active.nfnum9, j_1bnfe_active.docnum9, j_1bnfe_active.cdv) AS "Chave de Acesso"
    ,j_1bnfdoc.cnpj_bupla AS "CNPJ Ball"
    ,j_1bnfdoc.cgc AS "CNPJ Emitente"
    ,j_1bnflin.nffre AS "Vlr Frete"
    ,j_1bnflin.nfins AS "Vlr Seguro"
    ,j_1bnflin.nfdis AS "Vlr Desconto"
    ,j_1bnflin.nfoth AS "Vlr Outros Custos"
    ,TRY_TO_DATE(j_1bnfdoc.docdat, 'YYYYMMDD') AS "Data Emissao"
    ,j_1bnfdoc.nfenum AS "Num NF"
    ,j_1bnfdoc.crenam AS "Usuario"
    ,CONCAT(j_1bnfdoc.parid, ' - ', j_1bnfdoc.name1) AS "Parceiro"
    ,TRY_TO_DATE(j_1bnfdoc.pstdat, 'YYYYMMDD') AS "Data Lancamento"
    ,TRY_TO_DATE(j_1bnfdoc.credat, 'YYYYMMDD') AS "Data Criação"
    ,j_1bnfdoc.nfesrv AS "Flag NF Serv"
    ,j_1bnfdoc.belnr AS "Inv Doc Number"
    ,j_1bnfdoc.bukrs AS "Company Code"
    ,j_1bnfdoc.gjahr AS "Fiscal Year"
    ,SUBSTRING(j_1bnflin.itmnum,3,3) AS "Line Item"
    ,j_1bnfdoc.cancel AS "NF Cancelada"
FROM 
    DW_STAGING.SAP_SABEV.J_1BNFDOC j_1bnfdoc
LEFT JOIN DW_STAGING.SAP_SABEV.J_1BNFE_ACTIVE j_1bnfe_active ON j_1bnfdoc.docnum = j_1bnfe_active.docnum AND j_1bnfe_active.mandt = '300'
INNER JOIN DW_STAGING.SAP_SABEV.J_1BNFLIN j_1bnflin ON j_1bnfdoc.docnum = j_1bnflin.docnum AND j_1bnflin.mandt = '300'
WHERE 
    j_1bnfdoc.mandt = '300'
    AND YEAR("Data Lancamento") >= YEAR(GETDATE())-1 
    AND j_1bnfdoc.direct = '1'
    AND j_1bnfdoc.form = ' '
    AND j_1bnfdoc.model <> '57'
),

ecc_data02 AS (
SELECT 
    ecc."Chave de Acesso" AS "Chave 1"
    ,CONCAT(ecc."Num NF", ecc."CNPJ Emitente") AS "Chave 2"
    ,ecc."Doc Num"
    ,nfe_emails.centro AS "Centro"
    ,ecc."Valor Incl. Impostos"
    ,ecc."Vlr Item"
    ,ecc."Chave de Acesso" 
    ,nfe_emails.email AS "Email"
    ,ecc."CNPJ Ball"
    ,ecc."CNPJ Emitente"
    ,ecc."Vlr Frete"
    ,ecc."Vlr Seguro"
    ,ecc."Vlr Desconto"
    ,ecc."Vlr Outros Custos"
    ,ecc."Data Emissao"
    ,ecc."Num NF"
    ,ecc."Usuario"
    ,ecc."Parceiro"
    ,ecc."Data Lancamento"
    ,ecc."Data Criação"
    ,ecc."Flag NF Serv"
    ,ecc."Inv Doc Number"
    ,ecc."Company Code"
    ,ecc."Fiscal Year"
    ,ecc."Line Item"
    ,ecc."NF Cancelada"
FROM 
    ecc_data01 ecc
LEFT JOIN DW_STAGING.RPA.SA_EXCEL_TAX_PLANT_XREF nfe_emails ON ecc."CNPJ Ball" = nfe_emails.cnpj
),

/*
finance_details AS (
SELECT
    bkpf.belnr
    ,bkpf.bukrs
    ,bkpf.gjahr
    ,bkpf.budat
    ,bkpf.awkey
    ,IFF(bkpf.stblg = ' ', NULL, bkpf.stblg) AS stblg
    ,IFF(bkpf.stjah = '0000', NULL, bkpf.stjah) AS stjah
    ,bseg.buzei
    ,bseg.augdt
    ,bseg.augbl
FROM
    DW_STAGING.SAP_SABEV.BKPF bkpf
INNER JOIN DW_STAGING.SAP_SABEV.BSEG bseg ON bkpf.bukrs = bseg.bukrs AND bkpf.belnr = bseg.belnr AND bkpf.gjahr = bseg.gjahr AND bseg.mandt = '300'
WHERE
    bkpf.mandt = '300'
    AND YEAR(TRY_TO_DATE(bkpf.budat, 'YYYYMMDD')) >= YEAR(GETDATE())-1 
),
*/
--Calculations and Comparisons

--table to store the access keys. This list will be used to search if the NF exists in G3P system. If not, raise error message in nf_errors table.
nfs_ecc_only AS (
SELECT DISTINCT
    ecc."Doc Num"
    ,ecc."Chave de Acesso"
FROM
    ecc_data01 ecc
LEFT JOIN grc_data01 grc ON ecc."Chave de Acesso" = grc."Chave de Acesso" 
WHERE
    grc."Chave de Acesso" IS NULL
),

--table to store the access keys too but using a different method as a second attempt to match the records. This list will be used to search if the NF exists in G3P system. If not, raise error message in nf_errors table.
nfs_ecc_only2 AS (
SELECT DISTINCT
    ecc."Doc Num"
    ,grc."Num NF"
    ,grc."CNPJ Emitente"
    ,CONCAT(ecc."Num NF", ecc."CNPJ Emitente") AS "Check Key ECC"
    ,CONCAT(grc."Num NF", grc."CNPJ Emitente") AS "Check Key GRC"
FROM
    ecc_data01 ecc
LEFT JOIN grc_data01 grc ON ecc."Num NF" = grc."Num NF" AND ecc."CNPJ Emitente" = grc."CNPJ Emitente"
WHERE
    "Check Key GRC" IS NULL
),

--table to consolidate line items to header level for error analysis
ecc_hdr_data AS (
SELECT
    ecc."Chave 1"
    ,ecc."Chave 2"
    ,ecc."Doc Num"
    ,ecc."Centro"
    ,ecc."Valor Incl. Impostos"
    ,ecc."Chave de Acesso" 
    ,ecc."Email"
    ,ecc."CNPJ Ball"
    ,ecc."CNPJ Emitente"
    ,SUM(ecc."Vlr Frete") AS "Vlr Frete Total"
    ,SUM(ecc."Vlr Seguro") AS "Vlr Seguro Total"
    ,SUM(ecc."Vlr Desconto") AS "Vlr Desconto Total"
    ,SUM(ecc."Vlr Outros Custos") AS "Vlr Outros Custos Total"
    ,ecc."Data Emissao"
    ,ecc."Num NF"
    ,ecc."Usuario"
    ,ecc."Parceiro"
    ,ecc."Data Lancamento"
    ,ecc."Data Criação"
    ,ecc."Flag NF Serv"
    ,ecc."Inv Doc Number"
    ,ecc."Company Code"
    ,ecc."Fiscal Year"
    ,ecc."NF Cancelada"
FROM
    ecc_data02 ecc 
GROUP BY ALL
),

--table to store the validation rules and error messages related with the comparison between the SAP and GRC environments
nf_errors AS (
SELECT 
    ecc."Doc Num"
    ,ecc."Chave 1" AS "Chave"
    
    --Validations
    ,IFF(grc."Processo" IN ('CANCEL00', 'CANCEL01', 'CANCEL02'), 1, 0) AS "Error 01"
    ,IFF(ecc."CNPJ Ball" = '', 1, 0) AS "Error 02"
    ,IFF(ecc."CNPJ Ball" <> grc."CNPJ Destinatário", 1, 0) AS "Error 03"
    ,IFF(ecc."Chave de Acesso" = '', 1, 0) AS "Error 04"
    ,IFF(((ecc."Valor Incl. Impostos" - grc."Valor Total Incl Impostos") < -0.05) OR ((ecc."Valor Incl. Impostos" - grc."Valor Total Incl Impostos") > 0.05), 1, 0) AS "Error 05"
    ,IFF(((ecc."Vlr Frete Total" - grc."Valor Total do Frete") < -0.05) OR ((ecc."Vlr Frete Total" - grc."Valor Total do Frete") > 0.05), 1, 0) AS "Error 06"
    ,IFF(((ecc."Vlr Seguro Total" - grc."Valor Total do Seguro") < -0.05) OR ((ecc."Vlr Seguro Total" - grc."Valor Total do Seguro") > 0.05), 1, 0) AS "Error 07"
    ,IFF(((ecc."Vlr Desconto Total" - grc."Valor Total do Desconto") < -0.05) OR ((ecc."Vlr Desconto Total" - grc."Valor Total do Desconto") > 0.05), 1, 0) AS "Error 08"
    ,IFF(((ecc."Vlr Outros Custos Total" - grc."Outros Custos Adicionais") < -0.05) OR ((ecc."Vlr Outros Custos Total" - grc."Outros Custos Adicionais") > 0.05), 1, 0) AS "Error 09"
    ,IFF(((grc."Data Documento" IS NULL) OR (ecc."Data Emissao" = grc."Data Documento" OR ecc."Data Emissao" = grc."Data Emissao")), 0, 1) AS "Error 10.1"
    ,IFF((DATEDIFF(DAY, ecc."Data Emissao", grc."Data Documento") = 1) OR (DATEDIFF(DAY, ecc."Data Emissao", grc."Data Emissao") = 1)
    , 0, 1) AS "Error 10.2"
    ,CASE
        WHEN "Error 10.1" = 0 AND "Error 10.2" = 0 THEN 0
        WHEN "Error 10.1" = 0 AND "Error 10.2" = 1 THEN 0
        WHEN "Error 10.1" = 1 AND "Error 10.2" = 0 THEN 0
        ELSE 1
    END "Error 10"
    ,IFF(ecc."Data Emissao" > ecc."Data Lancamento", 1, 0) AS "Error 11"
    ,IFF(ecc."Data Lancamento" <> ecc."Data Criação" AND "Error 11" = 0, 1, 0) AS "Error 12"
    ,IFF(LEN(ecc."Chave de Acesso") = 44 AND ecc."Doc Num" IN (SELECT "Doc Num" FROM nfs_ecc_only) AND ecc."Doc Num" IN (SELECT "Doc Num" FROM nfs_ecc_only2), 1, 0) AS "Error 13"
    ,IFF(LEN(ecc."Chave de Acesso") = 44 AND (grc."Chave de Acesso" IS NULL) AND "Error 13" = 0, 1, 0) AS "Error 14"
    ,IFF(ecc."Flag NF Serv" = 'X', 1, 0) AS "Error 15"
    ,IFF(LEN(ecc."Chave de Acesso") < 44, 1,0) AS "Error 16"
    
    -- Error Messages
    ,IFF("Error 01" = 1, 'Existe um evento de cancelamento para o Doc Num. no GRC. ', '') AS "Reason 01"
    ,IFF("Error 02" = 1, 'Campo CNPJ Vazio. ', '') AS "Reason 02"
    ,IFF("Error 03" = 1, 'Diferença de CNPJ entre ECC e GRC. ', '') AS "Reason 03"
    ,IFF("Error 04" = 1, 'NF não possui chave de acesso. ', '') AS "Reason 04"
    ,IFF("Error 05" = 1, 'Existe uma diferença no Valor Total entre SAP e GRC. ', '') AS "Reason 05"
    ,IFF("Error 06" = 1, 'Existe uma diferença no Valor Frete entre SAP e GRC. ', '') AS "Reason 06"
    ,IFF("Error 07" = 1, 'Existe uma diferença no Valor Seguro entre SAP e GRC. ', '') AS "Reason 07"
    ,IFF("Error 08" = 1, 'Existe uma diferença no Valor Desconto entre SAP e GRC. ', '') AS "Reason 08"
    ,IFF("Error 09" = 1, 'Existe uma diferença no Valor Outros Custos entre SAP e GRC. ', '') AS "Reason 09"
    ,IFF("Error 10" = 1, 'Data de Emissão no ECC diferente da Data Emissão no GRC. ', '') AS "Reason 10"
    ,IFF("Error 11" = 1, 'Data de Emissão maior que Data de Lançamento. ', '') AS "Reason 11"
    ,IFF("Error 12" = 1, 'Data do Lançamento diferente da Data de Criação. ', '') AS "Reason 12"
    ,IFF("Error 13" = 1, 'NF não migrou para o G3P. ', '') AS "Reason 13"
    ,IFF("Error 14" = 1, 'Chave de acesso do ECC divergente da chave de acesso do XML. ', '') AS "Reason 14"
    ,IFF("Error 15" = 1, 'NF com flag de Serviço ativado. ', '') AS "Reason 15"
    ,IFF("Error 16" = 1, 'Chave de Acesso menor que 44 caracteres. ', '') AS "Reason 16"
    ,("Error 01" + "Error 02" + "Error 03" + "Error 04" 
    + "Error 05" + "Error 06" + "Error 07" + "Error 08" 
    + "Error 09" + "Error 10" + "Error 11" + "Error 12" 
    + "Error 13" + "Error 14" + "Error 15" + "Error 16") AS "Sum Errors"
    ,CONCAT("Reason 01", "Reason 02" 
    	   ,"Reason 03", "Reason 04"
           ,"Reason 05", "Reason 06"
           ,"Reason 07", "Reason 08"
           ,"Reason 09", "Reason 10"
           ,"Reason 11", "Reason 12"
           ,"Reason 13", "Reason 14"
           ,"Reason 15", "Reason 16") AS "Mensagem de Erro"
FROM
    ecc_hdr_data ecc
LEFT JOIN grc_data01 grc ON ecc."Chave 1" = grc."Chave 1"
),

--table to store the detailed data and the analysis of errors for each NF
ecc_data04 AS (
    SELECT
        ecc."Doc Num"
        ,ecc."Centro"
        ,ecc."Valor Incl. Impostos"
        ,ecc."Vlr Item"
        ,ecc."Chave de Acesso" 
        ,IFF(nf."Error 13" = 1 AND nf."Error 16" = 0, 'Não Carregada', IFF(nf."Sum Errors" <> 0, 'Incorreta', 'Correta')) AS "Indicador Status NF"
        ,ecc."Email"
        ,ecc."CNPJ Ball"
        ,ecc."CNPJ Emitente"
        ,ecc."Vlr Frete"
        ,ecc."Vlr Seguro"
        ,ecc."Vlr Desconto"
        ,ecc."Vlr Outros Custos"
        ,ecc."Data Emissao"
        ,ecc."Num NF"
        ,ecc."Usuario"
        ,ecc."Parceiro"
        ,ecc."Data Lancamento"
        ,ecc."Flag NF Serv"
        ,ecc."Inv Doc Number"
        --,ecc."Fin Doc Num"
        ,ecc."Company Code"
        ,ecc."Fiscal Year"
        ,ecc."Line Item"
        --,ecc."Doc Compensação"
        ,ecc."NF Cancelada"
        --,ecc."Pagamento"
    
    
        --GRC Data
        ,grc."Processo" AS "GRC Processo"
        ,grc."Chave de Acesso" AS "GRC Chave de Acesso"
        ,grc."Valor Total do Frete" AS "GRC Valor Total do Frete"
        ,grc."Valor Total do Seguro" AS "GRC Valor Total do Seguro"
        ,grc."Valor Total do Desconto" AS "GRC Valor Total do Desconto"
        ,grc."Outros Custos Adicionais" AS "GRC Outros Custos Adicionais"
        ,grc."CNPJ Destinatário" AS "GRC CNPJ Destinatário"
        ,grc."CNPJ Emitente" AS "GRC CNPJ Emitente"
        ,grc."Valor Total Incl Impostos" AS "GRC Valor Total Incl Impostos"
        ,grc."Data Documento" AS "GRC Data Documento"
        ,grc."Numero Protocolo" AS "GRC Numero Protocolo"
        ,grc."Num NF" AS "GRC Num NF"
        ,grc."Data Emissao" AS "GRC Data Emissao"
        ,nf."Mensagem de Erro" AS "Mensagem de Erro"
        --,IFF(nf."Error 13" = 1, 'NF não migrou para o G3P. ', nf."Mensagem de Erro") AS "Mensagem de Erro"
    FROM
        ecc_data02 ecc
    INNER JOIN nf_errors nf ON ecc."Chave de Acesso" = nf."Chave" AND ecc."Doc Num" = nf."Doc Num"
    LEFT JOIN grc_data01 grc ON ecc."Chave de Acesso" = grc."Chave de Acesso"

UNION
    
    SELECT
        ecc."Doc Num"
        ,ecc."Centro"
        ,ecc."Valor Incl. Impostos"
        ,ecc."Vlr Item"
        ,ecc."Chave de Acesso" 
        ,IFF(nf."Error 13" = 1 AND nf."Error 16" = 0, 'Não Carregada', IFF(nf."Sum Errors" <> 0, 'Incorreta', 'Correta')) AS "Indicador Status NF"
        ,ecc."Email"
        ,ecc."CNPJ Ball"
        ,ecc."CNPJ Emitente"
        ,ecc."Vlr Frete"
        ,ecc."Vlr Seguro"
        ,ecc."Vlr Desconto"
        ,ecc."Vlr Outros Custos"
        ,ecc."Data Emissao"
        ,ecc."Num NF"
        ,ecc."Usuario"
        ,ecc."Parceiro"
        ,ecc."Data Lancamento"
        ,ecc."Flag NF Serv"
        ,ecc."Inv Doc Number"
        --,ecc."Fin Doc Num"
        ,ecc."Company Code"
        ,ecc."Fiscal Year"
        ,ecc."Line Item"
        --,ecc."Doc Compensação"
        ,ecc."NF Cancelada"
        --,ecc."Pagamento"
    
    
        --GRC Data
        ,grc."Processo" AS "GRC Processo"
        ,grc."Chave de Acesso" AS "GRC Chave de Acesso"
        ,grc."Valor Total do Frete" AS "GRC Valor Total do Frete"
        ,grc."Valor Total do Seguro" AS "GRC Valor Total do Seguro"
        ,grc."Valor Total do Desconto" AS "GRC Valor Total do Desconto"
        ,grc."Outros Custos Adicionais" AS "GRC Outros Custos Adicionais"
        ,grc."CNPJ Destinatário" AS "GRC CNPJ Destinatário"
        ,grc."CNPJ Emitente" AS "GRC CNPJ Emitente"
        ,grc."Valor Total Incl Impostos" AS "GRC Valor Total Incl Impostos"
        ,grc."Data Documento" AS "GRC Data Documento"
        ,grc."Numero Protocolo" AS "GRC Numero Protocolo"
        ,grc."Num NF" AS "GRC Num NF"
        ,grc."Data Emissao" AS "GRC Data Emissao"
        ,nf."Mensagem de Erro" AS "Mensagem de Erro"
        --,IFF(nf."Error 13" = 1, 'NF não migrou para o G3P. ', nf."Mensagem de Erro") AS "Mensagem de Erro"
    FROM
        ecc_data02 ecc
    INNER JOIN nf_errors nf ON ecc."Chave de Acesso" = nf."Chave" AND ecc."Doc Num" = nf."Doc Num"
    INNER JOIN grc_data01 grc ON ecc."Num NF" = grc."Num NF" AND ecc."CNPJ Emitente" = grc."CNPJ Emitente"
),

consolidated_results AS (
    SELECT 
        ecc."Doc Num"
        ,ecc."Centro"
        ,ecc."Valor Incl. Impostos"
        ,ecc."Vlr Item"
        ,ecc."Chave de Acesso" 
        ,ecc."Indicador Status NF"
        ,ecc."Email"
        ,ecc."CNPJ Ball"
        ,ecc."CNPJ Emitente"
        ,ecc."Vlr Frete"
        ,ecc."Vlr Seguro"
        ,ecc."Vlr Desconto"
        ,ecc."Vlr Outros Custos"
        ,ecc."Data Emissao"
        ,ecc."Num NF"
        ,ecc."Usuario"
        ,ecc."Parceiro"
        ,ecc."Data Lancamento"
        ,ecc."Flag NF Serv"
        ,ecc."Inv Doc Number"
        --,ecc."Fin Doc Num"
        ,ecc."Company Code"
        ,ecc."Fiscal Year"
        ,ecc."Line Item"
        --,ecc."Doc Compensação"
        ,ecc."NF Cancelada"
        --,ecc."Pagamento"
    
        --GRC Data
        ,ecc."GRC Processo"
        ,ecc."GRC Chave de Acesso"
        ,ecc."GRC Valor Total do Frete"
        ,ecc."GRC Valor Total do Seguro"
        ,ecc."GRC Valor Total do Desconto"
        ,ecc."GRC Outros Custos Adicionais"
        ,ecc."GRC CNPJ Destinatário"
        ,ecc."GRC CNPJ Emitente"
        ,ecc."GRC Valor Total Incl Impostos"
        ,ecc."GRC Data Documento"
        ,ecc."GRC Numero Protocolo"
        ,ecc."GRC Num NF"
        ,ecc."GRC Data Emissao"
        ,IFF(LEN(ecc."Mensagem de Erro") = 0, '', ecc."Mensagem de Erro") AS "Mensagens de Erro" 
    FROM 
        ecc_data04 ecc
    WHERE
        ecc."GRC Chave de Acesso" IS NOT NULL

UNION

    SELECT 
        ecc."Doc Num"
        ,ecc."Centro"
        ,ecc."Valor Incl. Impostos"
        ,ecc."Vlr Item"
        ,ecc."Chave de Acesso" 
        ,ecc."Indicador Status NF"
        ,ecc."Email"
        ,ecc."CNPJ Ball"
        ,ecc."CNPJ Emitente"
        ,ecc."Vlr Frete"
        ,ecc."Vlr Seguro"
        ,ecc."Vlr Desconto"
        ,ecc."Vlr Outros Custos"
        ,ecc."Data Emissao"
        ,ecc."Num NF"
        ,ecc."Usuario"
        ,ecc."Parceiro"
        ,ecc."Data Lancamento"
        ,ecc."Flag NF Serv"
        ,ecc."Inv Doc Number"
        --,ecc."Fin Doc Num"
        ,ecc."Company Code"
        ,ecc."Fiscal Year"
        ,ecc."Line Item"
        --,ecc."Doc Compensação"
        ,ecc."NF Cancelada"
        --,ecc."Pagamento"
    
        --GRC Data
        ,ecc."GRC Processo"
        ,ecc."GRC Chave de Acesso"
        ,ecc."GRC Valor Total do Frete"
        ,ecc."GRC Valor Total do Seguro"
        ,ecc."GRC Valor Total do Desconto"
        ,ecc."GRC Outros Custos Adicionais"
        ,ecc."GRC CNPJ Destinatário"
        ,ecc."GRC CNPJ Emitente"
        ,ecc."GRC Valor Total Incl Impostos"
        ,ecc."GRC Data Documento"
        ,ecc."GRC Numero Protocolo"
        ,ecc."GRC Num NF"
        ,ecc."GRC Data Emissao"
        ,IFF(LEN(ecc."Mensagem de Erro") = 0, '', ecc."Mensagem de Erro") AS "Mensagens de Erro" 
    FROM 
        ecc_data04 ecc
    WHERE
        ecc."Indicador Status NF" = 'Não Carregada'
        OR LEN(ecc."Chave de Acesso") < 44 
)

SELECT DISTINCT
    ecc."Doc Num"
    ,ecc."Centro"
    ,ecc."Valor Incl. Impostos"
    ,ecc."Vlr Item"
    ,ecc."Chave de Acesso" 
    ,ecc."Indicador Status NF"
    ,ecc."Email"
    ,ecc."CNPJ Ball"
    ,ecc."CNPJ Emitente"
    ,ecc."Vlr Frete"
    ,ecc."Vlr Seguro"
    ,ecc."Vlr Desconto"
    ,ecc."Vlr Outros Custos"
    ,ecc."Data Emissao"
    ,ecc."Num NF"
    ,ecc."Usuario"
    ,ecc."Parceiro"
    ,ecc."Data Lancamento"
    ,ecc."Flag NF Serv"
    ,ecc."Inv Doc Number"
    --,ecc."Fin Doc Num"
    ,ecc."Company Code"
    ,ecc."Fiscal Year"
    --,ecc."Line Item"
    --,ecc."Doc Compensação"
    ,ecc."NF Cancelada"
    --,ecc."Pagamento"

    --GRC Data
    ,ecc."GRC Processo"
    ,ecc."GRC Chave de Acesso"
    ,ecc."GRC Valor Total do Frete"
    ,ecc."GRC Valor Total do Seguro"
    ,ecc."GRC Valor Total do Desconto"
    ,ecc."GRC Outros Custos Adicionais"
    ,ecc."GRC CNPJ Destinatário"
    ,ecc."GRC CNPJ Emitente"
    ,ecc."GRC Valor Total Incl Impostos"
    ,ecc."GRC Data Documento"
    ,ecc."GRC Numero Protocolo"
    ,ecc."GRC Num NF"
    ,ecc."GRC Data Emissao"
    ,ecc."Mensagens de Erro" AS "Mensagem de Erro"
FROM 
    consolidated_results ecc