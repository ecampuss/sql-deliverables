WITH tipos_frete AS (
SELECT * FROM (VALUES
('0', 'Contratação do Frete por conta do Remetente (CIF)'),
('1', 'Contratação do Frete por conta do Destinatário (FOB)'),
('2', 'Contratação do Frete por conta de Terceiros'),
('3', 'Transporte Próprio por conta do Remetente'),
('4', 'Transporte Próprio por conta do Destinatário'),
('9', 'Sem Ocorrência de Transporte')x(cod_frete, descricao_frete)
)
),

natureza_operacoes AS (
SELECT * FROM (VALUES
('Exportação Temporária'),
('Rem. ind.cta.ord.adq.merc.qndo ñ tran.estab.adq.'),
('Rem. ind.cta.ord.adq.merc.qndo ñ tran.estab.adq. /  Remessa'),
('Rem. ind.cta.ord.adq.merc.qndo ñ tran.estab.adq. /  Rem. ind'),
('Remessa de bem por contrato de comodato ou locação'),
('Remessa de vasilhame ou sacaria'),
('Remessa merc.conta ord.terc.em venda à ordem'),
('Remessa p/ depós. fech. arm.geral ou outro est.'),
('Remessa p/ depósito fechado ou arm.geral'),
('Venda de mercadoria adquirida ou recebida terc.'),
('Venda de produção do estabelecimento'),
('Venda merc. adq. rec. terc. que ñ deva ele trans.'),
('Venda merc. adq. rec. terc. que ñ deva ele trans. /  Remessa'),
('Venda merc.adq. rec. terc. dest. ZFM Ár. Liv. Com.'),
('Venda merc.adq.receb.de terceiros'),
('Venda merc.adq.receb.de terceiros /  Remessa de vasilhame ou'),
('Venda merc.adq.receb.de terceiros /  Venda produção do estab'),
('Venda prod. estab. dest. ZFM Ár. Livre Comércio'),
('Venda prod. estab. ñ deva por ele transitar'),
('Venda prod.estab.ent.des.cnt.ord.adq.orig.vnd.ord.'),
('Venda produção do estabelecimento'),
('Venda produção do estabelecimento /  Remessa de vasilhame ou'),
('Vnd merc.adq.rec.terc.ent.des.vend.remet vnd.ord'),
('Vnd.mer.adq.rec.ter.rem.ind.cnt.o.adq.tra.est.adq.'),
('Vnd.prod.est.rem.ind.cnt.ord.adq.s/ tran.est.adq./ Vnd.mer'),
('Vnd.prod.est.rem.ind.cnt.ord.adq.s/ tran.est.adq.'),
('Venda produção do estabelecimento /  Venda merc.adq.receb.de')x(natop)
)
),

sit_tribut AS (
SELECT 
    icms_law
    ,tax_situation
    ,description
FROM 
    BALL_SANDBOX.USER_ESANTOS2.SA_BSP_TAX_LAW_ICMS
),

temp_konv AS (
SELECT
    konv.knumv
    ,konv.kposn
    ,konv.kwert
    ,konv.kschl
    ,konv.kbetr
FROM 
    DW_STAGING.SAP_SABEV.KONV konv 
WHERE
    konv.mandt = '300'
    AND konv.kschl IN ('BX10', 'BX13', 'BX23', 'BX72', 'BX82', 'IPVA')
),

base_icms_total AS (
SELECT
    konv.knumv
    ,SUM(konv.kwert) AS kwert
FROM 
    temp_konv konv 
WHERE
    konv.kschl IN ('BX10')
GROUP BY ALL
),

base_icms AS (
SELECT
    konv.knumv
    ,konv.kposn
    ,konv.kwert
FROM 
    temp_konv konv 
WHERE
    konv.kschl IN ('BX10')
),

impostos AS (
SELECT
    konv.knumv
    ,konv.kposn
    ,konv.kwert AS icms
    ,konv2.kwert AS ipi
    ,konv3.kwert AS pis
    ,konv4.kwert AS cofins
FROM 
    temp_konv konv
INNER JOIN temp_konv konv2 ON konv.knumv = konv2.knumv AND konv.kposn = konv2.kposn AND konv2.kschl = 'BX23'
INNER JOIN temp_konv konv3 ON konv.knumv = konv3.knumv AND konv.kposn = konv3.kposn AND konv3.kschl = 'BX82'
INNER JOIN temp_konv konv4 ON konv.knumv = konv4.knumv AND konv.kposn = konv4.kposn AND konv4.kschl = 'BX72'
WHERE
    konv.kschl IN ('BX13')
),

impostos_total AS (
SELECT
    imp.knumv
    --,imp.kposn
    ,SUM(imp.icms) AS icms
    ,SUM(imp.ipi) AS ipi
    ,SUM(imp.pis) AS pis
    ,SUM(imp.cofins) AS cofins
FROM
    impostos imp
GROUP BY ALL
),

aliquotas AS (
SELECT
    konv.knumv
    ,konv.kposn
    ,TO_NUMERIC(konv.kbetr / 10, 6, 2) AS icms
    ,TO_NUMERIC(konv2.kbetr / 10, 6, 2) AS ipi 
FROM
    temp_konv konv
INNER JOIN temp_konv konv2 ON konv.knumv = konv2.knumv AND konv.kposn = konv2.kposn AND konv2.kschl = 'IPVA'
WHERE
    konv.kschl = 'BX13'
),

nf_totais AS (
SELECT 
    j_1bnflin.docnum AS "NF Doc Number"
    ,SUM(j_1bnflin.netwr) AS "Net Value"
FROM 
    DW_STAGING.SAP_SABEV.J_1BNFLIN j_1bnflin
WHERE
    j_1bnflin.mandt = '300'
GROUP BY ALL
),

nf_data AS (
SELECT 
    j_1bnfe_active.regio AS "Componente Chave de Acesso 1"
    ,j_1bnfe_active.nfyear AS "Componente Chave de Acesso 2"
    ,j_1bnfe_active.nfmonth AS "Componente Chave de Acesso 3"
    ,j_1bnfe_active.stcd1 AS "Componente Chave de Acesso 4"
    ,j_1bnfe_active.model AS "Componente Chave de Acesso 5"
    ,j_1bnfe_active.serie AS "Componente Chave de Acesso 6"
    ,j_1bnfe_active.nfnum9 AS "Componente Chave de Acesso 7"
    ,j_1bnfe_active.docnum9 AS "Componente Chave de Acesso 8"
    ,j_1bnfe_active.cdv AS "Componente Chave de Acesso 9"

    ,kna1_emit.name1 AS "A - Identificação Emitente"
    ,kna1_emit.stras AS "A - Endereço Emitente"
    ,kna1_emit.ort02 AS "A - Bairro Emitente"
    ,kna1_emit.pstlz AS "A - CEP Emitente"
    ,kna1_emit.ort01 AS "A - Município Emitente"
    ,kna1_emit.regio AS "A - Estado Emitente"
    ,kna1_emit.telf1 AS "A - Fone/Fax Emitente"
    ,j_1bnfdoc.natop AS "B - Natureza da Operação"
    ,kna1_emit.stcd3 AS "C - Inscrição Estadual Emitente"
    ,CASE 
        WHEN j_1bnfdoc.direct = 1 THEN '0'
        WHEN j_1bnfdoc.direct = 2 THEN '1'
        WHEN j_1bnfdoc.direct = 3 THEN '0'
        WHEN j_1bnfdoc.direct = 4 THEN '1'
        ELSE NULL 
    END AS "D - Direção"
    ,j_1bnfdoc.nfenum AS "E - Num NF"
    ,CONCAT('00', j_1bnfdoc.series) AS "F - Série"
    ,CONCAT(j_1bnfe_active.regio, j_1bnfe_active.nfyear, j_1bnfe_active.nfmonth, j_1bnfe_active.stcd1, j_1bnfe_active.model, j_1bnfe_active.serie, j_1bnfe_active.nfnum9, j_1bnfe_active.docnum9, j_1bnfe_active.cdv) AS "G - Chave de Acesso"
        ,IFF(j_1bnfe_active.authdate = '00000000', j_1bnfe_active.authcod, CONCAT(j_1bnfe_active.authcod, ' - ', TRY_TO_DATE(j_1bnfe_active.authdate, 'YYYYMMDD'), ' ', TO_TIME(j_1bnfe_active.authtime))) AS "H - Protocolo"
    ,j_1bnfdoc.cnpj_bupla AS "I - CNPJ do Emitente - noformat"
    ,CONCAT(SUBSTR(j_1bnfdoc.cnpj_bupla, 0, 2), '.' , SUBSTR(j_1bnfdoc.cnpj_bupla, 3, 3), '.', SUBSTR(j_1bnfdoc.cnpj_bupla, 6, 3), '/', SUBSTR(j_1bnfdoc.cnpj_bupla, 9, 4), '-', SUBSTR(j_1bnfdoc.cnpj_bupla, 13, 2)) AS "I - CNPJ do Emitente"
    ,IFF(j_1bnfdoc.natop = 'Transferência produção estabelecimento', kna1_transf.name1, kna1_cust.name1) AS "J - Nome Cliente"
    ,IFF(j_1bnfdoc.natop = 'Transferência produção estabelecimento', kna1_transf.stras, kna1_cust.stras) AS "K - Endereço Cliente"
    ,IFF(j_1bnfdoc.natop = 'Transferência produção estabelecimento', kna1_transf.ort01, kna1_cust.ort01) AS "L - Município"
    ,CONCAT(SUBSTR(j_1bnfdoc.cgc, 0, 2), '.' , SUBSTR(j_1bnfdoc.cgc, 3, 3), '.', SUBSTR(j_1bnfdoc.cgc, 6, 3), '/', SUBSTR(j_1bnfdoc.cgc, 9, 4), '-', SUBSTR(j_1bnfdoc.cgc, 13, 2)) AS "M - CNPJ Cliente"
    ,IFF(j_1bnfdoc.natop = 'Transferência produção estabelecimento', kna1_transf.ort02, kna1_cust.ort02) AS "N - Bairro"
    ,IFF(j_1bnfdoc.natop = 'Transferência produção estabelecimento', kna1_transf.regio, kna1_cust.regio) AS "O - Estado"
    ,IFF(j_1bnfdoc.natop = 'Transferência produção estabelecimento', kna1_transf.telf1, kna1_cust.telf1) AS "P - Fone/Tax"
    ,IFF(j_1bnfdoc.natop = 'Transferência produção estabelecimento', kna1_transf.pstlz, kna1_cust.pstlz) AS "Q - CEP"
    ,IFF(j_1bnfdoc.natop = 'Transferência produção estabelecimento', kna1_transf.stcd3, kna1_cust.stcd3) AS "R - Inscrição Estadual Cliente"
    ,TRY_TO_DATE(j_1bnfdoc.docdat, 'YYYYMMDD') AS "S - Data da Emissão"
    ,REPLACE(CAST(bit.kwert AS VARCHAR),'.', ',') AS "T - Base de Calc do ICMS"
    ,REPLACE(CAST(j_1bnflin.netfre AS VARCHAR),'.', ',') AS "U - Valor do Frete"
    ,REPLACE(CAST(impt.icms AS VARCHAR),'.', ',') AS "V - Valor do ICMS"
    ,REPLACE(CAST(j_1bnflin.netins AS VARCHAR),'.', ',') AS "X - Valor do Seguro"
    ,IFF(j_1bnflin.modbcst = ' ', '0,00', REPLACE(CAST(j_1bnflin.modbcst AS VARCHAR),'.', ',')) AS "Z - Base de Calc ICMS S.T."
    ,REPLACE(CAST(j_1bnflin.nfdis AS VARCHAR),'.', ',') AS "Z1 - Desconto"
    ,'0,000' AS "Z2 - Valor do ICMS Subst."
    ,REPLACE(CAST(j_1bnflin.netoth AS VARCHAR),'.', ',') AS "Z3 - Outras Despesas"
    ,'0,00' AS "Z4 - Valor Importação"
    ,impt.ipi AS "Z5 - Valor Total IPI"
    ,'0,00' AS "Z6 - ICMS UF Remetente"
    ,'0,00' AS "Z7 - ICMS UF Destino"
    ,'0,00' AS "Z8 - Valor FCP UF Destino"
    ,0.00 AS "Z9 - Valor Total Impostos"
    ,REPLACE(CAST(impt.pis AS VARCHAR),'.', ',') AS "Z10 - Valor do PIS"
    ,REPLACE(CAST(impt.cofins AS VARCHAR),'.', ',') AS "Z11 - Valor da COFINS"
    ,nf_totais."Net Value" AS "Z12 - Valor Total Produtos"
    ,"Z12 - Valor Total Produtos" + "Z5 - Valor Total IPI" AS "Z13 - Valor Total da Nota"
    ,lfa1_transp.name1 AS "Z14 - Nome Transportador"
    ,lfa1_transp.stras AS "Z15 - Endereço Transportador"
    ,j_1bnfdoc.anzpk AS "Z16 - Quantidade"
    ,CONCAT(tf.cod_frete, ' - ', tf.descricao_frete) AS "Z17 - Frete"
    ,lfa1_transp.ort01 AS "Z21 - Município Transportador"
    ,TO_NUMERIC(j_1bnfdoc.brgew, 20, 3) AS "Z23 - Peso Bruto"
    ,' ' AS "Z24 - UF"
    ,lfa1_transp.regio AS "Z25 - UF"
    ,CONCAT(SUBSTR(lfa1_transp.stcd1, 0, 2), '.' , SUBSTR(lfa1_transp.stcd1, 3, 3), '.', SUBSTR(lfa1_transp.stcd1, 6, 3), '/', SUBSTR(lfa1_transp.stcd1, 9, 4), '-', SUBSTR(lfa1_transp.stcd1, 13, 2)) AS "Z26 - CNPJ Transportador"
    ,lfa1_transp.stcd3 AS "Z27 - Inscrição Estadual Transportador"
    ,TO_NUMERIC(j_1bnfdoc.ntgew, 20, 3) AS "Z28 - Peso Líquido"
    ,j_1bnflin.itmnum AS "Número do Item"
    ,j_1bnflin.matnr AS "Z29 - Código do Produto"
    ,j_1bnflin.maktx AS "Z30 - Descrição do Produto"
    ,mara.mtart AS "Material Type"
    ,IFF("Material Type" = 'FERT', 1, 0) AS "Count FERT"
    ,j_1bnflin.nbm AS "Z31 - NCM/SH"
    ,CONCAT(j_1bnflin.matorg, st.tax_situation) AS "Z32 - O/CST"
    ,SUBSTR(j_1bnflin.cfop, 0, 4) AS "Z33 - CFOP"
    ,CASE 
        WHEN j_1bnflin.meins = 'TH' THEN 'MI'
        ELSE j_1bnflin.meins
    END AS "Z34 - UN"
    ,TO_NUMERIC(j_1bnflin.menge, 13, 4) AS "Z35 - Quantidade"
    ,TO_NUMERIC(j_1bnflin.netpr, 13 ,6) AS "Z36 - Valor Unitário"
    ,TO_NUMERIC(("Z35 - Quantidade" * "Z36 - Valor Unitário"), 13, 2) AS "Z37 - Valor Total"
    ,j_1bnflin.netdis AS "Z38 - Valor Desconto"
    ,base_icms.kwert AS "Z39 - Base de Calc do ICMS"
    ,imp.icms AS "Z40 - Valor do ICMS"
    ,imp.ipi AS "Z41 - Valor Total IPI"
    ,CASE
        WHEN SUBSTR("Z31 - NCM/SH", 0,1) = '3' THEN 0
        WHEN SUBSTR("Z31 - NCM/SH", 0,1) = '4' THEN 0
        ELSE alq.icms 
    END AS "Z42 - Alíquota ICMS"
    ,CASE
        WHEN SUBSTR("Z31 - NCM/SH", 0,1) = '3' THEN 0
        WHEN SUBSTR("Z31 - NCM/SH", 0,1) = '4' THEN 0
        ELSE alq.ipi
    END AS "Z43 - Alíquota IPI"
    ,j_1bnfdoc.docnum
FROM 
    DW_STAGING.SAP_SABEV.J_1BNFDOC j_1bnfdoc
LEFT JOIN DW_STAGING.SAP_SABEV.J_1BNFE_ACTIVE j_1bnfe_active ON j_1bnfdoc.docnum = j_1bnfe_active.docnum AND j_1bnfe_active.mandt = '300'
LEFT JOIN DW_STAGING.SAP_SABEV.J_1BNFLIN j_1bnflin ON j_1bnfdoc.docnum = j_1bnflin.docnum AND j_1bnflin.mandt = '300'
LEFT JOIN DW_STAGING.SAP_SABEV.KNA1 kna1_cust ON j_1bnfe_active.parid = kna1_cust.kunnr AND kna1_cust.mandt = '300'
LEFT JOIN DW_STAGING.SAP_SABEV.KNA1 kna1_transf ON j_1bnfdoc.cgc = kna1_transf.stcd1 AND kna1_transf.mandt = '300'
LEFT JOIN DW_STAGING.SAP_SABEV.T001W t001w ON j_1bnflin.bwkey = t001w.bwkey AND t001w.mandt = '300'
LEFT JOIN DW_STAGING.SAP_SABEV.KNA1 kna1_emit ON t001w.kunnr = kna1_emit.kunnr AND kna1_emit.mandt = '300'
LEFT JOIN nf_totais ON j_1bnfdoc.docnum = nf_totais."NF Doc Number"
LEFT JOIN tipos_frete tf ON j_1bnfdoc.modfrete = tf.cod_frete
LEFT JOIN sit_tribut st ON j_1bnflin.taxlw1 = st.icms_law
LEFT JOIN DW_STAGING.SAP_SABEV.VBRP vbrp ON j_1bnflin.refkey = vbrp.vbeln AND j_1bnflin.refitm = vbrp.posnr AND vbrp.mandt = '300'
LEFT JOIN DW_STAGING.SAP_SABEV.VBRK vbrk ON vbrp.vbeln = vbrk.vbeln AND vbrk.mandt = '300'
LEFT JOIN DW_STAGING.SAP_SABEV.MARA mara ON vbrp.matnr = mara.matnr AND mara.mandt = '300'
LEFT JOIN base_icms ON vbrk.knumv = base_icms.knumv AND vbrp.posnr = base_icms.kposn
LEFT JOIN base_icms_total bit ON vbrk.knumv = bit.knumv 
LEFT JOIN impostos imp ON vbrk.knumv = imp.knumv AND vbrp.posnr = imp.kposn
LEFT JOIN impostos_total impt ON vbrk.knumv = impt.knumv 
LEFT JOIN aliquotas alq ON vbrk.knumv = alq.knumv AND vbrp.posnr = alq.kposn
LEFT JOIN DW_STAGING.SAP_SABEV.VBPA vbpa ON j_1bnflin.refkey = vbpa.vbeln AND vbpa.parvw IN ('CR', 'SP') AND vbpa.mandt = '300'
LEFT JOIN DW_STAGING.SAP_SABEV.LFA1 lfa1_transp ON vbpa.lifnr = lfa1_transp.lifnr AND lfa1_transp.mandt = '300'
WHERE 
    j_1bnfdoc.mandt = '300'
    AND "G - Chave de Acesso" IS NOT NULL
    --AND "G - Chave de Acesso" = '43240805053793000120550020000047431004640329'
    --AND j_1bnfdoc.docnum IN ('0005376512','0005375902')
    --AND j_1bnfdoc.nfenum LIKE '%000234464'
    AND j_1bnfdoc.natop IN (SELECT * FROM natureza_operacoes)
    AND mara.mtart IN ('HALB', 'FERT', 'LEIH', 'VERP')
    AND "S - Data da Emissão" = CURRENT_DATE()-3
),

fert_calculation AS (
SELECT 
    "E - Num NF"
    ,"G - Chave de Acesso"
    ,SUM("Count FERT") AS "FERT Result"
FROM
    nf_data
GROUP BY ALL
HAVING
    "FERT Result" > 0
),

nf_convertions AS (
SELECT
    nf."Componente Chave de Acesso 1"
    ,nf."Componente Chave de Acesso 2"
    ,nf."Componente Chave de Acesso 3"
    ,nf."Componente Chave de Acesso 4"
    ,nf."Componente Chave de Acesso 5"
    ,nf."Componente Chave de Acesso 6"
    ,nf."Componente Chave de Acesso 7"
    ,nf."Componente Chave de Acesso 8"
    ,nf."Componente Chave de Acesso 9"

    ,nf."A - Identificação Emitente"
    ,nf."A - Endereço Emitente"
    ,nf."A - Bairro Emitente"
    ,nf."A - CEP Emitente"
    ,nf."A - Município Emitente"
    ,nf."A - Estado Emitente"
    ,nf."A - Fone/Fax Emitente"
    ,nf."B - Natureza da Operação"
    ,nf."C - Inscrição Estadual Emitente"
    ,nf."D - Direção"
    ,nf."E - Num NF"
    ,nf."F - Série"
    ,nf."G - Chave de Acesso"
    ,nf."H - Protocolo"
    ,nf."I - CNPJ do Emitente - noformat"
    ,nf."I - CNPJ do Emitente"
    ,nf."J - Nome Cliente"
    ,nf."K - Endereço Cliente"
    ,nf."L - Município"
    ,nf."M - CNPJ Cliente"
    ,nf."N - Bairro"
    ,nf."O - Estado"
    ,nf."P - Fone/Tax"
    ,nf."Q - CEP"
    ,nf."R - Inscrição Estadual Cliente"
    ,nf."S - Data da Emissão"

    -- T - BASE DE CALC DO ICMS
    ,LEN(LEFT(nf."T - Base de Calc do ICMS", CHARINDEX(',', nf."T - Base de Calc do ICMS") - 1)) AS "T - Base de Calc do ICMS - Prefix"
    ,CASE
        WHEN "T - Base de Calc do ICMS - Prefix" = 4
            THEN CONCAT(LEFT(nf."T - Base de Calc do ICMS", 1), '.', SUBSTR(nf."T - Base de Calc do ICMS", 2, 3), ',', RIGHT(nf."T - Base de Calc do ICMS", 2))
        WHEN "T - Base de Calc do ICMS - Prefix" = 5 
            THEN CONCAT(LEFT(nf."T - Base de Calc do ICMS", 2), '.', SUBSTR(nf."T - Base de Calc do ICMS", 3, 3), ',', RIGHT(nf."T - Base de Calc do ICMS", 2))
        WHEN "T - Base de Calc do ICMS - Prefix" = 6
            THEN CONCAT(LEFT(nf."T - Base de Calc do ICMS", 3), '.', SUBSTR(nf."T - Base de Calc do ICMS", 4, 3), ',', RIGHT(nf."T - Base de Calc do ICMS", 2))
        WHEN "T - Base de Calc do ICMS - Prefix" = 7
            THEN CONCAT(LEFT(nf."T - Base de Calc do ICMS", 1), '.', SUBSTR(nf."T - Base de Calc do ICMS", 2, 3), '.', SUBSTR(nf."T - Base de Calc do ICMS", 5, 3), ',', RIGHT(nf."T - Base de Calc do ICMS", 2)) 
        WHEN "T - Base de Calc do ICMS - Prefix" = 8
            THEN CONCAT(LEFT(nf."T - Base de Calc do ICMS", 2), '.', SUBSTR(nf."T - Base de Calc do ICMS", 3, 3), '.', SUBSTR(nf."T - Base de Calc do ICMS", 6, 3), ',', RIGHT(nf."T - Base de Calc do ICMS", 2)) 
        WHEN "T - Base de Calc do ICMS - Prefix" = 9
            THEN CONCAT(LEFT(nf."T - Base de Calc do ICMS", 3), '.', SUBSTR(nf."T - Base de Calc do ICMS", 4, 3), '.', SUBSTR(nf."T - Base de Calc do ICMS", 7, 3), ',', RIGHT(nf."T - Base de Calc do ICMS", 2))
        ELSE nf."T - Base de Calc do ICMS"
    END AS "T - Base de Calc do ICMS"

    -- U - VALOR DO FRETE
    ,LEN(LEFT(nf."U - Valor do Frete", CHARINDEX(',', nf."U - Valor do Frete") - 1)) AS "U - Valor do Frete - Prefix"
    ,CASE
        WHEN "U - Valor do Frete - Prefix" = 4
            THEN CONCAT(LEFT(nf."U - Valor do Frete", 1), '.', SUBSTR(nf."U - Valor do Frete", 2, 3), ',', RIGHT(nf."U - Valor do Frete", 2))
        WHEN "U - Valor do Frete - Prefix" = 5 
            THEN CONCAT(LEFT(nf."U - Valor do Frete", 2), '.', SUBSTR(nf."U - Valor do Frete", 3, 3), ',', RIGHT(nf."U - Valor do Frete", 2))
        WHEN "U - Valor do Frete - Prefix" = 6
            THEN CONCAT(LEFT(nf."U - Valor do Frete", 3), '.', SUBSTR(nf."U - Valor do Frete", 4, 3), ',', RIGHT(nf."U - Valor do Frete", 2))
        WHEN "U - Valor do Frete - Prefix" = 7
            THEN CONCAT(LEFT(nf."U - Valor do Frete", 1), '.', SUBSTR(nf."U - Valor do Frete", 2, 3), '.', SUBSTR(nf."U - Valor do Frete", 5, 3), ',', RIGHT(nf."U - Valor do Frete", 2))
        WHEN "U - Valor do Frete - Prefix" = 8
            THEN CONCAT(LEFT(nf."U - Valor do Frete", 2), '.', SUBSTR(nf."U - Valor do Frete", 3, 3), '.', SUBSTR(nf."U - Valor do Frete", 6, 3), ',', RIGHT(nf."U - Valor do Frete", 2)) 
        WHEN "U - Valor do Frete - Prefix" = 9
            THEN CONCAT(LEFT(nf."U - Valor do Frete", 3), '.', SUBSTR(nf."U - Valor do Frete", 4, 3), '.', SUBSTR(nf."U - Valor do Frete", 7, 3), ',', RIGHT(nf."U - Valor do Frete", 2))
        ELSE nf."U - Valor do Frete"
    END AS "U - Valor do Frete"

    
    -- V - Valor do ICMS
    ,LEN(LEFT(nf."V - Valor do ICMS", CHARINDEX(',', nf."V - Valor do ICMS") - 1)) AS "V - Valor do ICMS - Prefix"
    ,CASE
        WHEN "V - Valor do ICMS - Prefix" = 4
            THEN CONCAT(LEFT(nf."V - Valor do ICMS", 1), '.', SUBSTR(nf."V - Valor do ICMS", 2, 3), ',', RIGHT(nf."V - Valor do ICMS", 2))
        WHEN "V - Valor do ICMS - Prefix" = 5 
            THEN CONCAT(LEFT(nf."V - Valor do ICMS", 2), '.', SUBSTR(nf."V - Valor do ICMS", 3, 3), ',', RIGHT(nf."V - Valor do ICMS", 2))
        WHEN "V - Valor do ICMS - Prefix" = 6
            THEN CONCAT(LEFT(nf."V - Valor do ICMS", 3), '.', SUBSTR(nf."V - Valor do ICMS", 4, 3), ',', RIGHT(nf."V - Valor do ICMS", 2))
        WHEN "V - Valor do ICMS - Prefix" = 7
            THEN CONCAT(LEFT(nf."V - Valor do ICMS", 1), '.', SUBSTR(nf."V - Valor do ICMS", 2, 3), '.', SUBSTR(nf."V - Valor do ICMS", 5, 3), ',', RIGHT(nf."V - Valor do ICMS", 2)) 
        WHEN "V - Valor do ICMS - Prefix" = 8
            THEN CONCAT(LEFT(nf."V - Valor do ICMS", 2), '.', SUBSTR(nf."V - Valor do ICMS", 3, 3), '.', SUBSTR(nf."V - Valor do ICMS", 6, 3), ',', RIGHT(nf."V - Valor do ICMS", 2)) 
        WHEN "V - Valor do ICMS - Prefix" = 9
            THEN CONCAT(LEFT(nf."V - Valor do ICMS", 3), '.', SUBSTR(nf."V - Valor do ICMS", 4, 3), '.', SUBSTR(nf."V - Valor do ICMS", 7, 3), ',', RIGHT(nf."V - Valor do ICMS", 2)) 
        ELSE nf."V - Valor do ICMS"
    END AS "V - Valor do ICMS"

    
    --X - VALOR DO SEGURO
    ,LEN(LEFT(nf."X - Valor do Seguro", CHARINDEX(',', nf."X - Valor do Seguro") - 1)) AS "X - Valor do Seguro - Prefix"
    ,CASE
        WHEN "X - Valor do Seguro - Prefix" = 4
            THEN CONCAT(LEFT(nf."X - Valor do Seguro", 1), '.', SUBSTR(nf."X - Valor do Seguro", 2, 3), ',', RIGHT(nf."X - Valor do Seguro", 2))
        WHEN "X - Valor do Seguro - Prefix" = 5 
            THEN CONCAT(LEFT(nf."X - Valor do Seguro", 2), '.', SUBSTR(nf."X - Valor do Seguro", 3, 3), ',', RIGHT(nf."X - Valor do Seguro", 2))
        WHEN "X - Valor do Seguro - Prefix" = 6
            THEN CONCAT(LEFT(nf."X - Valor do Seguro", 3), '.', SUBSTR(nf."X - Valor do Seguro", 4, 3), ',', RIGHT(nf."X - Valor do Seguro", 2))
        WHEN "X - Valor do Seguro - Prefix" = 7
            THEN CONCAT(LEFT(nf."X - Valor do Seguro", 1), '.', SUBSTR(nf."X - Valor do Seguro", 2, 3), '.', SUBSTR(nf."X - Valor do Seguro", 5, 3), ',', RIGHT(nf."X - Valor do Seguro", 2))
        WHEN "X - Valor do Seguro - Prefix" = 8
            THEN CONCAT(LEFT(nf."X - Valor do Seguro", 2), '.', SUBSTR(nf."X - Valor do Seguro", 3, 3), '.', SUBSTR(nf."X - Valor do Seguro", 6, 3), ',', RIGHT(nf."X - Valor do Seguro", 2)) 
        WHEN "X - Valor do Seguro - Prefix" = 9
            THEN CONCAT(LEFT(nf."X - Valor do Seguro", 3), '.', SUBSTR(nf."X - Valor do Seguro", 4, 3), '.', SUBSTR(nf."X - Valor do Seguro", 7, 3), ',', RIGHT(nf."X - Valor do Seguro", 2))
        ELSE nf."X - Valor do Seguro"
    END AS "X - Valor do Seguro"

    
    --Z - BASE DE CALC ICMS S.T.
    ,LEN(LEFT(nf."Z - Base de Calc ICMS S.T.", CHARINDEX(',', nf."Z - Base de Calc ICMS S.T.") - 1)) AS "Z - Base de Calc ICMS S.T. - Prefix"
    ,CASE
        WHEN "Z - Base de Calc ICMS S.T. - Prefix" = 4
            THEN CONCAT(LEFT(nf."Z - Base de Calc ICMS S.T.", 1), '.', SUBSTR(nf."Z - Base de Calc ICMS S.T.", 2, 3), ',', RIGHT(nf."Z - Base de Calc ICMS S.T.", 2))
        WHEN "Z - Base de Calc ICMS S.T. - Prefix" = 5 
            THEN CONCAT(LEFT(nf."Z - Base de Calc ICMS S.T.", 2), '.', SUBSTR(nf."Z - Base de Calc ICMS S.T.", 3, 3), ',', RIGHT(nf."Z - Base de Calc ICMS S.T.", 2))
        WHEN "Z - Base de Calc ICMS S.T. - Prefix" = 6
            THEN CONCAT(LEFT(nf."Z - Base de Calc ICMS S.T.", 3), '.', SUBSTR(nf."Z - Base de Calc ICMS S.T.", 4, 3), ',', RIGHT(nf."Z - Base de Calc ICMS S.T.", 2))
        WHEN "Z - Base de Calc ICMS S.T. - Prefix" = 7
            THEN CONCAT(LEFT(nf."Z - Base de Calc ICMS S.T.", 1), '.', SUBSTR(nf."Z - Base de Calc ICMS S.T.", 2, 3), '.', SUBSTR(nf."Z - Base de Calc ICMS S.T.", 5, 3), ',', RIGHT(nf."Z - Base de Calc ICMS S.T.", 2)) 
        WHEN "Z - Base de Calc ICMS S.T. - Prefix" = 8
            THEN CONCAT(LEFT(nf."Z - Base de Calc ICMS S.T.", 2), '.', SUBSTR(nf."Z - Base de Calc ICMS S.T.", 3, 3), '.', SUBSTR(nf."Z - Base de Calc ICMS S.T.", 6, 3), ',', RIGHT(nf."Z - Base de Calc ICMS S.T.", 2)) 
        WHEN "Z - Base de Calc ICMS S.T. - Prefix" = 9
            THEN CONCAT(LEFT(nf."Z - Base de Calc ICMS S.T.", 3), '.', SUBSTR(nf."Z - Base de Calc ICMS S.T.", 4, 3), '.', SUBSTR(nf."Z - Base de Calc ICMS S.T.", 7, 3), ',', RIGHT(nf."Z - Base de Calc ICMS S.T.", 2))
        ELSE nf."Z - Base de Calc ICMS S.T."
    END AS "Z - Base de Calc ICMS S.T."

    
    --Z1 - DESCONTO
    ,LEN(LEFT(nf."Z1 - Desconto", CHARINDEX(',', nf."Z1 - Desconto") - 1)) AS "Z1 - Desconto - Prefix"
    ,CASE
        WHEN "Z1 - Desconto - Prefix" = 4
            THEN CONCAT(LEFT(nf."Z1 - Desconto", 1), '.', SUBSTR(nf."Z1 - Desconto", 2, 3), ',', RIGHT(nf."Z1 - Desconto", 2))
        WHEN "Z1 - Desconto - Prefix" = 5 
            THEN CONCAT(LEFT(nf."Z1 - Desconto", 2), '.', SUBSTR(nf."Z1 - Desconto", 3, 3), ',', RIGHT(nf."Z1 - Desconto", 2))
        WHEN "Z1 - Desconto - Prefix" = 6
            THEN CONCAT(LEFT(nf."Z1 - Desconto", 3), '.', SUBSTR(nf."Z1 - Desconto", 4, 3), ',', RIGHT(nf."Z1 - Desconto", 2))
        WHEN "Z1 - Desconto - Prefix" = 7
            THEN CONCAT(LEFT(nf."Z1 - Desconto", 1), '.', SUBSTR(nf."Z1 - Desconto", 2, 3), '.', SUBSTR(nf."Z1 - Desconto", 5, 3), ',', RIGHT(nf."Z1 - Desconto", 2))
        WHEN "Z1 - Desconto - Prefix" = 8
            THEN CONCAT(LEFT(nf."Z1 - Desconto", 2), '.', SUBSTR(nf."Z1 - Desconto", 3, 3), '.', SUBSTR(nf."Z1 - Desconto", 6, 3), ',', RIGHT(nf."Z1 - Desconto", 2)) 
        WHEN "Z1 - Desconto - Prefix" = 9
            THEN CONCAT(LEFT(nf."Z1 - Desconto", 3), '.', SUBSTR(nf."Z1 - Desconto", 4, 3), '.', SUBSTR(nf."Z1 - Desconto", 7, 3), ',', RIGHT(nf."Z1 - Desconto", 2))
        ELSE nf."Z1 - Desconto"
    END AS "Z1 - Desconto"

    
    --Z2 - VALOR DO ICMS SUBST.
    ,LEN(LEFT(nf."Z2 - Valor do ICMS Subst.", CHARINDEX(',', nf."Z2 - Valor do ICMS Subst.") - 1)) AS "Z2 - Valor do ICMS Subst. - Prefix"
    ,CASE
        WHEN "Z2 - Valor do ICMS Subst. - Prefix" = 4
            THEN CONCAT(LEFT(nf."Z2 - Valor do ICMS Subst.", 1), '.', SUBSTR(nf."Z2 - Valor do ICMS Subst.", 2, 3), ',', RIGHT(nf."Z2 - Valor do ICMS Subst.", 2))
        WHEN "Z2 - Valor do ICMS Subst. - Prefix" = 5 
            THEN CONCAT(LEFT(nf."Z2 - Valor do ICMS Subst.", 2), '.', SUBSTR(nf."Z2 - Valor do ICMS Subst.", 3, 3), ',', RIGHT(nf."Z2 - Valor do ICMS Subst.", 2))
        WHEN "Z2 - Valor do ICMS Subst. - Prefix" = 6
            THEN CONCAT(LEFT(nf."Z2 - Valor do ICMS Subst.", 3), '.', SUBSTR(nf."Z2 - Valor do ICMS Subst.", 4, 3), ',', RIGHT(nf."Z2 - Valor do ICMS Subst.", 2))
        WHEN "Z2 - Valor do ICMS Subst. - Prefix" = 7
            THEN CONCAT(LEFT(nf."Z2 - Valor do ICMS Subst.", 1), '.', SUBSTR(nf."Z2 - Valor do ICMS Subst.", 2, 3), '.', SUBSTR(nf."Z2 - Valor do ICMS Subst.", 5, 3), ',', RIGHT(nf."Z2 - Valor do ICMS Subst.", 2)) 
        WHEN "Z2 - Valor do ICMS Subst. - Prefix" = 8
            THEN CONCAT(LEFT(nf."Z2 - Valor do ICMS Subst.", 2), '.', SUBSTR(nf."Z2 - Valor do ICMS Subst.", 3, 3), '.', SUBSTR(nf."Z2 - Valor do ICMS Subst.", 6, 3), ',', RIGHT(nf."Z2 - Valor do ICMS Subst.", 2)) 
        WHEN "Z2 - Valor do ICMS Subst. - Prefix" = 9
            THEN CONCAT(LEFT(nf."Z2 - Valor do ICMS Subst.", 3), '.', SUBSTR(nf."Z2 - Valor do ICMS Subst.", 4, 3), '.', SUBSTR(nf."Z2 - Valor do ICMS Subst.", 7, 3), ',', RIGHT(nf."Z2 - Valor do ICMS Subst.", 2))
        ELSE nf."Z2 - Valor do ICMS Subst."
    END AS "Z2 - Valor do ICMS Subst."

    

    --Z3 - OUTRAS DESPESAS
    ,LEN(LEFT(nf."Z3 - Outras Despesas", CHARINDEX(',', nf."Z3 - Outras Despesas") - 1)) AS "Z3 - Outras Despesas - Prefix"
    ,CASE
        WHEN "Z3 - Outras Despesas - Prefix" = 4
            THEN CONCAT(LEFT(nf."Z3 - Outras Despesas", 1), '.', SUBSTR(nf."Z3 - Outras Despesas", 2, 3), ',', RIGHT(nf."Z3 - Outras Despesas", 2))
        WHEN "Z3 - Outras Despesas - Prefix" = 5 
            THEN CONCAT(LEFT(nf."Z3 - Outras Despesas", 2), '.', SUBSTR(nf."Z3 - Outras Despesas", 3, 3), ',', RIGHT(nf."Z3 - Outras Despesas", 2))
        WHEN "Z3 - Outras Despesas - Prefix" = 6
            THEN CONCAT(LEFT(nf."Z3 - Outras Despesas", 3), '.', SUBSTR(nf."Z3 - Outras Despesas", 4, 3), ',', RIGHT(nf."Z3 - Outras Despesas", 2))
        WHEN "Z3 - Outras Despesas - Prefix" = 7
            THEN CONCAT(LEFT(nf."Z3 - Outras Despesas", 1), '.', SUBSTR(nf."Z3 - Outras Despesas", 2, 3), '.', SUBSTR(nf."Z3 - Outras Despesas", 5, 3), ',', RIGHT(nf."Z3 - Outras Despesas", 2))
        WHEN "Z3 - Outras Despesas - Prefix" = 8
            THEN CONCAT(LEFT(nf."Z3 - Outras Despesas", 2), '.', SUBSTR(nf."Z3 - Outras Despesas", 3, 3), '.', SUBSTR(nf."Z3 - Outras Despesas", 6, 3), ',', RIGHT(nf."Z3 - Outras Despesas", 2)) 
        WHEN "Z3 - Outras Despesas - Prefix" = 9
            THEN CONCAT(LEFT(nf."Z3 - Outras Despesas", 3), '.', SUBSTR(nf."Z3 - Outras Despesas", 4, 3), '.', SUBSTR(nf."Z3 - Outras Despesas", 7, 3), ',', RIGHT(nf."Z3 - Outras Despesas", 2))
        ELSE nf."Z3 - Outras Despesas"
    END AS "Z3 - Outras Despesas"
    
    
    --Z4 - VALOR IMPORTAÇÃO
    ,LEN(LEFT(nf."Z4 - Valor Importação", CHARINDEX(',', nf."Z4 - Valor Importação") - 1)) AS "Z4 - Valor Importação - Prefix"
    ,CASE
        WHEN "Z4 - Valor Importação - Prefix" = 4
            THEN CONCAT(LEFT(nf."Z4 - Valor Importação", 1), '.', SUBSTR(nf."Z4 - Valor Importação", 2, 3), ',', RIGHT(nf."Z4 - Valor Importação", 2))
        WHEN "Z4 - Valor Importação - Prefix" = 5 
            THEN CONCAT(LEFT(nf."Z4 - Valor Importação", 2), '.', SUBSTR(nf."Z4 - Valor Importação", 3, 3), ',', RIGHT(nf."Z4 - Valor Importação", 2))
        WHEN "Z4 - Valor Importação - Prefix" = 6
            THEN CONCAT(LEFT(nf."Z4 - Valor Importação", 3), '.', SUBSTR(nf."Z4 - Valor Importação", 4, 3), ',', RIGHT(nf."Z4 - Valor Importação", 2))
        WHEN "Z4 - Valor Importação - Prefix" = 7
            THEN CONCAT(LEFT(nf."Z4 - Valor Importação", 1), '.', SUBSTR(nf."Z4 - Valor Importação", 2, 3), '.', SUBSTR(nf."Z4 - Valor Importação", 5, 3), ',', RIGHT(nf."Z4 - Valor Importação", 2)) 
        WHEN "Z4 - Valor Importação - Prefix" = 8
            THEN CONCAT(LEFT(nf."Z4 - Valor Importação", 2), '.', SUBSTR(nf."Z4 - Valor Importação", 3, 3), '.', SUBSTR(nf."Z4 - Valor Importação", 6, 3), ',', RIGHT(nf."Z4 - Valor Importação", 2)) 
        WHEN "Z4 - Valor Importação - Prefix" = 9
            THEN CONCAT(LEFT(nf."Z4 - Valor Importação", 3), '.', SUBSTR(nf."Z4 - Valor Importação", 4, 3), '.', SUBSTR(nf."Z4 - Valor Importação", 7, 3), ',', RIGHT(nf."Z4 - Valor Importação", 2))
        ELSE nf."Z4 - Valor Importação"
    END AS "Z4 - Valor Importação"


    --Z5 - VALOR TOTAL IPI
    ,REPLACE(CAST(nf."Z5 - Valor Total IPI" AS VARCHAR),'.', ',') AS "Z5.1 - Valor Total IPI"
    ,LEN(LEFT("Z5.1 - Valor Total IPI", CHARINDEX(',', "Z5.1 - Valor Total IPI") - 1)) AS "Z5 - Valor Total IPI - Prefix"
    ,CASE
        WHEN "Z5 - Valor Total IPI - Prefix" = 4
            THEN CONCAT(LEFT("Z5.1 - Valor Total IPI", 1), '.', SUBSTR("Z5.1 - Valor Total IPI", 2, 3), ',', RIGHT("Z5.1 - Valor Total IPI", 2))
        WHEN "Z5 - Valor Total IPI - Prefix" = 5 
            THEN CONCAT(LEFT("Z5.1 - Valor Total IPI", 2), '.', SUBSTR("Z5.1 - Valor Total IPI", 3, 3), ',', RIGHT("Z5.1 - Valor Total IPI", 2))
        WHEN "Z5 - Valor Total IPI - Prefix" = 6
            THEN CONCAT(LEFT("Z5 - Valor Total IPI", 3), '.', SUBSTR("Z5.1 - Valor Total IPI", 4, 3), ',', RIGHT("Z5.1 - Valor Total IPI", 2))
        WHEN "Z5 - Valor Total IPI - Prefix" = 7
            THEN CONCAT(LEFT("Z5.1 - Valor Total IPI", 1), '.', SUBSTR("Z5.1 - Valor Total IPI", 2, 3), '.', SUBSTR("Z5.1 - Valor Total IPI", 5, 3), ',', RIGHT("Z5.1 - Valor Total IPI", 2))
        WHEN "Z5 - Valor Total IPI - Prefix" = 8
            THEN CONCAT(LEFT("Z5.1 - Valor Total IPI", 2), '.', SUBSTR("Z5.1 - Valor Total IPI", 3, 3), '.', SUBSTR("Z5.1 - Valor Total IPI", 6, 3), ',', RIGHT("Z5.1 - Valor Total IPI", 2)) 
        WHEN "Z5 - Valor Total IPI - Prefix" = 9
            THEN CONCAT(LEFT("Z5.1 - Valor Total IPI", 3), '.', SUBSTR("Z5.1 - Valor Total IPI", 4, 3), '.', SUBSTR("Z5.1 - Valor Total IPI", 7, 3), ',', RIGHT("Z5.1 - Valor Total IPI", 2))
        ELSE "Z5.1 - Valor Total IPI"
    END AS "Z5 - Valor Total IPI"

    
    ,nf."Z6 - ICMS UF Remetente"
    ,nf."Z7 - ICMS UF Destino"
    ,nf."Z8 - Valor FCP UF Destino"
    ,nf."Z9 - Valor Total Impostos"

    
    --Z10 - VALOR DO PIS
    ,LEN(LEFT(nf."Z10 - Valor do PIS", CHARINDEX(',', nf."Z10 - Valor do PIS") - 1)) AS "Z10 - Valor do PIS - Prefix"
    ,CASE
        WHEN "Z10 - Valor do PIS - Prefix" = 4
            THEN CONCAT(LEFT(nf."Z10 - Valor do PIS", 1), '.', SUBSTR(nf."Z10 - Valor do PIS", 2, 3), ',', RIGHT(nf."Z10 - Valor do PIS", 2))
        WHEN "Z10 - Valor do PIS - Prefix" = 5 
            THEN CONCAT(LEFT(nf."Z10 - Valor do PIS", 2), '.', SUBSTR(nf."Z10 - Valor do PIS", 3, 3), ',', RIGHT(nf."Z10 - Valor do PIS", 2))
        WHEN "Z10 - Valor do PIS - Prefix" = 6
            THEN CONCAT(LEFT(nf."Z10 - Valor do PIS", 3), '.', SUBSTR(nf."Z10 - Valor do PIS", 4, 3), ',', RIGHT(nf."Z10 - Valor do PIS", 2))
        WHEN "Z10 - Valor do PIS - Prefix" = 7
            THEN CONCAT(LEFT(nf."Z10 - Valor do PIS", 1), '.', SUBSTR(nf."Z10 - Valor do PIS", 2, 3), '.', SUBSTR(nf."Z10 - Valor do PIS", 5, 3), ',', RIGHT(nf."Z10 - Valor do PIS", 2))
        WHEN "Z10 - Valor do PIS - Prefix" = 8
            THEN CONCAT(LEFT(nf."Z10 - Valor do PIS", 2), '.', SUBSTR(nf."Z10 - Valor do PIS", 3, 3), '.', SUBSTR(nf."Z10 - Valor do PIS", 6, 3), ',', RIGHT(nf."Z10 - Valor do PIS", 2)) 
        WHEN "Z10 - Valor do PIS - Prefix" = 9
            THEN CONCAT(LEFT(nf."Z10 - Valor do PIS", 3), '.', SUBSTR(nf."Z10 - Valor do PIS", 4, 3), '.', SUBSTR(nf."Z10 - Valor do PIS", 7, 3), ',', RIGHT(nf."Z10 - Valor do PIS", 2))
        ELSE nf."Z10 - Valor do PIS"
    END AS "Z10 - Valor do PIS"

    
    --Z11 - VALOR DA COFINS
    ,LEN(LEFT(nf."Z11 - Valor da COFINS", CHARINDEX(',', nf."Z11 - Valor da COFINS") - 1)) AS "Z11 - Valor da COFINS - Prefix"
    ,CASE
        WHEN "Z11 - Valor da COFINS - Prefix" = 4
            THEN CONCAT(LEFT(nf."Z11 - Valor da COFINS", 1), '.', SUBSTR(nf."Z11 - Valor da COFINS", 2, 3), ',', RIGHT(nf."Z11 - Valor da COFINS", 2))
        WHEN "Z11 - Valor da COFINS - Prefix" = 5 
            THEN CONCAT(LEFT(nf."Z11 - Valor da COFINS", 2), '.', SUBSTR(nf."Z11 - Valor da COFINS", 3, 3), ',', RIGHT(nf."Z11 - Valor da COFINS", 2))
        WHEN "Z11 - Valor da COFINS - Prefix" = 6
            THEN CONCAT(LEFT(nf."Z11 - Valor da COFINS", 3), '.', SUBSTR(nf."Z11 - Valor da COFINS", 4, 3), ',', RIGHT(nf."Z11 - Valor da COFINS", 2))
        WHEN "Z11 - Valor da COFINS - Prefix" = 7
            THEN CONCAT(LEFT(nf."Z11 - Valor da COFINS", 1), '.', SUBSTR(nf."Z11 - Valor da COFINS", 2, 3), '.', SUBSTR(nf."Z11 - Valor da COFINS", 5, 3), ',', RIGHT(nf."Z11 - Valor da COFINS", 2))
        WHEN "Z11 - Valor da COFINS - Prefix" = 8
            THEN CONCAT(LEFT(nf."Z11 - Valor da COFINS", 2), '.', SUBSTR(nf."Z11 - Valor da COFINS", 3, 3), '.', SUBSTR(nf."Z11 - Valor da COFINS", 6, 3), ',', RIGHT(nf."Z11 - Valor da COFINS", 2)) 
        WHEN "Z11 - Valor da COFINS - Prefix" = 9
            THEN CONCAT(LEFT(nf."Z11 - Valor da COFINS", 3), '.', SUBSTR(nf."Z11 - Valor da COFINS", 4, 3), '.', SUBSTR(nf."Z11 - Valor da COFINS", 7, 3), ',', RIGHT(nf."Z11 - Valor da COFINS", 2))
        ELSE nf."Z11 - Valor da COFINS"
    END AS "Z11 - Valor da COFINS"


    --Z12 - VALOR TOTAL PRODUTOS
    ,REPLACE(CAST(nf."Z12 - Valor Total Produtos" AS VARCHAR),'.', ',') AS "Z12.1 - Valor Total Produtos"
    ,LEN(LEFT("Z12.1 - Valor Total Produtos", CHARINDEX(',', "Z12.1 - Valor Total Produtos") - 1)) AS "Z12 - Valor Total Produtos - Prefix"
    ,CASE
        WHEN "Z12 - Valor Total Produtos - Prefix" = 4
            THEN CONCAT(LEFT("Z12.1 - Valor Total Produtos", 1), '.', SUBSTR("Z12.1 - Valor Total Produtos", 2, 3), ',', RIGHT("Z12.1 - Valor Total Produtos", 2))
        WHEN "Z12 - Valor Total Produtos - Prefix" = 5 
            THEN CONCAT(LEFT("Z12.1 - Valor Total Produtos", 2), '.', SUBSTR("Z12.1 - Valor Total Produtos", 3, 3), ',', RIGHT("Z12.1 - Valor Total Produtos", 2))
        WHEN "Z12 - Valor Total Produtos - Prefix" = 6
            THEN CONCAT(LEFT("Z12 - Valor Total Produtos", 3), '.', SUBSTR("Z12.1 - Valor Total Produtos", 4, 3), ',', RIGHT("Z12.1 - Valor Total Produtos", 2))
        WHEN "Z12 - Valor Total Produtos - Prefix" = 7
            THEN CONCAT(LEFT("Z12.1 - Valor Total Produtos", 1), '.', SUBSTR("Z12.1 - Valor Total Produtos", 2, 3), '.', SUBSTR("Z12.1 - Valor Total Produtos", 5, 3), ',', RIGHT("Z12.1 - Valor Total Produtos", 2)) 
        WHEN "Z12 - Valor Total Produtos - Prefix" = 8
            THEN CONCAT(LEFT("Z12.1 - Valor Total Produtos", 2), '.', SUBSTR("Z12.1 - Valor Total Produtos", 3, 3), '.', SUBSTR("Z12.1 - Valor Total Produtos", 6, 3), ',', RIGHT("Z12.1 - Valor Total Produtos", 2)) 
        WHEN "Z12 - Valor Total Produtos - Prefix" = 9
            THEN CONCAT(LEFT("Z12.1 - Valor Total Produtos", 3), '.', SUBSTR("Z12.1 - Valor Total Produtos", 4, 3), '.', SUBSTR("Z12.1 - Valor Total Produtos", 7, 3), ',', RIGHT("Z12.1 - Valor Total Produtos", 2))
        ELSE "Z12.1 - Valor Total Produtos"
    END AS "Z12 - Valor Total Produtos"
    

    --Z13 - VALOR TOTAL DA NOTA
    ,REPLACE(CAST(nf."Z13 - Valor Total da Nota" AS VARCHAR),'.', ',') AS "Z13.1 - Valor Total da Nota"
    ,LEN(LEFT("Z13.1 - Valor Total da Nota", CHARINDEX(',', "Z13.1 - Valor Total da Nota") - 1)) AS "Z13 - Valor Total da Nota - Prefix"
    ,CASE
        WHEN "Z13 - Valor Total da Nota - Prefix" = 4
            THEN CONCAT(LEFT("Z13.1 - Valor Total da Nota", 1), '.', SUBSTR("Z13.1 - Valor Total da Nota", 2, 3), ',', RIGHT("Z13.1 - Valor Total da Nota", 2))
        WHEN "Z13 - Valor Total da Nota - Prefix" = 5 
            THEN CONCAT(LEFT("Z13.1 - Valor Total da Nota", 2), '.', SUBSTR("Z13.1 - Valor Total da Nota", 3, 3), ',', RIGHT("Z13.1 - Valor Total da Nota", 2))
        WHEN "Z13 - Valor Total da Nota - Prefix" = 6
            THEN CONCAT(LEFT("Z13 - Valor Total da Nota", 3), '.', SUBSTR("Z13.1 - Valor Total da Nota", 4, 3), ',', RIGHT("Z13.1 - Valor Total da Nota", 2))
        WHEN "Z13 - Valor Total da Nota - Prefix" = 7
            THEN CONCAT(LEFT("Z13.1 - Valor Total da Nota", 1), '.', SUBSTR("Z13.1 - Valor Total da Nota", 2, 3), '.', SUBSTR("Z13.1 - Valor Total da Nota", 5, 3), ',', RIGHT("Z13.1 - Valor Total da Nota", 2)) 
        WHEN "Z13 - Valor Total da Nota - Prefix" = 8
            THEN CONCAT(LEFT("Z13.1 - Valor Total da Nota", 2), '.', SUBSTR("Z13.1 - Valor Total da Nota", 3, 3), '.', SUBSTR("Z13.1 - Valor Total da Nota", 6, 3), ',', RIGHT("Z13.1 - Valor Total da Nota", 2)) 
        WHEN "Z13 - Valor Total da Nota - Prefix" = 9
            THEN CONCAT(LEFT("Z13.1 - Valor Total da Nota", 3), '.', SUBSTR("Z13.1 - Valor Total da Nota", 4, 3), '.', SUBSTR("Z13.1 - Valor Total da Nota", 7, 3), ',', RIGHT("Z13.1 - Valor Total da Nota", 2))
        ELSE "Z13.1 - Valor Total da Nota"
    END AS "Z13 - Valor Total da Nota"

    
    ,nf."Z14 - Nome Transportador"
    ,nf."Z15 - Endereço Transportador"
    ,nf."Z16 - Quantidade"
    ,nf."Z17 - Frete"
    ,nf."Z21 - Município Transportador"


    --Z23 - PESO BRUTO
    ,REPLACE(CAST(nf."Z23 - Peso Bruto" AS VARCHAR),'.', ',') AS "Z23.1 - Peso Bruto"
    ,LEN(LEFT("Z23.1 - Peso Bruto", CHARINDEX(',', "Z23.1 - Peso Bruto") - 1)) AS "Z23 - Peso Bruto - Prefix"
    ,RIGHT("Z23.1 - Peso Bruto", CHARINDEX(',', "Z23.1 - Peso Bruto") -2) AS "Z23 - Peso Bruto - Sufix"
    ,CASE
        WHEN "Z23 - Peso Bruto - Prefix" = 4
            THEN CONCAT(LEFT("Z23.1 - Peso Bruto", 1), '.', SUBSTR("Z23.1 - Peso Bruto", 2, 3), ',', "Z23 - Peso Bruto - Sufix")
        WHEN "Z23 - Peso Bruto - Prefix" = 5 
            THEN CONCAT(LEFT("Z23.1 - Peso Bruto", 2), '.', SUBSTR("Z23.1 - Peso Bruto", 3, 3), ',', "Z23 - Peso Bruto - Sufix")
        WHEN "Z23 - Peso Bruto - Prefix" = 6
            THEN CONCAT(LEFT("Z23 - Peso Bruto", 3), '.', SUBSTR("Z23.1 - Peso Bruto", 4, 3), ',', "Z23 - Peso Bruto - Sufix")
        WHEN "Z23 - Peso Bruto - Prefix" = 7
            THEN CONCAT(LEFT("Z23.1 - Peso Bruto", 1), '.', SUBSTR("Z23.1 - Peso Bruto", 2, 3), '.', SUBSTR("Z23.1 - Peso Bruto", 5, 3), ',', "Z23 - Peso Bruto - Sufix")
        WHEN "Z23 - Peso Bruto - Prefix" = 8
            THEN CONCAT(LEFT("Z23.1 - Peso Bruto", 2), '.', SUBSTR("Z23.1 - Peso Bruto", 3, 3), '.', SUBSTR("Z23.1 - Peso Bruto", 6, 3), ',', "Z23 - Peso Bruto - Sufix") 
        WHEN "Z23 - Peso Bruto - Prefix" = 9
            THEN CONCAT(LEFT("Z23.1 - Peso Bruto", 3), '.', SUBSTR("Z23.1 - Peso Bruto", 4, 3), '.', SUBSTR("Z23.1 - Peso Bruto", 7, 3), ',', "Z23 - Peso Bruto - Sufix")
        ELSE "Z23.1 - Peso Bruto"
    END AS "Z23 - Peso Bruto"

    
    ,nf."Z24 - UF"
    ,nf."Z25 - UF"
    ,nf."Z26 - CNPJ Transportador"
    ,nf."Z27 - Inscrição Estadual Transportador"

    
    --Z28 - PESO LÍQUIDO
    ,REPLACE(CAST(nf."Z28 - Peso Líquido" AS VARCHAR),'.', ',') AS "Z28.1 - Peso Líquido"
    ,LEN(LEFT("Z28.1 - Peso Líquido", CHARINDEX(',', "Z28.1 - Peso Líquido") - 1)) AS "Z28 - Peso Líquido - Prefix"
    ,RIGHT("Z28.1 - Peso Líquido", CHARINDEX(',', "Z28.1 - Peso Líquido") - 2) AS "Z28 - Peso Líquido - Sufix"
    ,CASE
        WHEN "Z28 - Peso Líquido - Prefix" = 4
            THEN CONCAT(LEFT("Z28.1 - Peso Líquido", 1), '.', SUBSTR("Z28.1 - Peso Líquido", 2, 3), ',', "Z28 - Peso Líquido - Sufix")
        WHEN "Z28 - Peso Líquido - Prefix" = 5 
            THEN CONCAT(LEFT("Z28.1 - Peso Líquido", 2), '.', SUBSTR("Z28.1 - Peso Líquido", 3, 3), ',', "Z28 - Peso Líquido - Sufix")
        WHEN "Z28 - Peso Líquido - Prefix" = 6
            THEN CONCAT(LEFT("Z28 - Peso Líquido", 3), '.', SUBSTR("Z28.1 - Peso Líquido", 4, 3), ',', "Z28 - Peso Líquido - Sufix")
        WHEN "Z28 - Peso Líquido - Prefix" = 7
            THEN CONCAT(LEFT("Z28.1 - Peso Líquido", 1), '.', SUBSTR("Z28.1 - Peso Líquido", 2, 3), '.', SUBSTR("Z28.1 - Peso Líquido", 5, 3), ',', "Z28 - Peso Líquido - Sufix") 
        WHEN "Z28 - Peso Líquido - Prefix" = 8
            THEN CONCAT(LEFT("Z28.1 - Peso Líquido", 2), '.', SUBSTR("Z28.1 - Peso Líquido", 3, 3), '.', SUBSTR("Z28.1 - Peso Líquido", 6, 3), ',', "Z28 - Peso Líquido - Sufix") 
        WHEN "Z28 - Peso Líquido - Prefix" = 9
            THEN CONCAT(LEFT("Z28.1 - Peso Líquido", 3), '.', SUBSTR("Z28.1 - Peso Líquido", 4, 3), '.', SUBSTR("Z28.1 - Peso Líquido", 7, 3), ',', "Z28 - Peso Líquido - Sufix")
        ELSE "Z28.1 - Peso Líquido"
    END AS "Z28 - Peso Líquido"

    
    ,nf."Número do Item"
    ,nf."Z29 - Código do Produto"
    ,nf."Z30 - Descrição do Produto"
    ,nf."Z31 - NCM/SH"
    ,nf."Z32 - O/CST"
    ,nf."Z33 - CFOP"
    ,nf."Z34 - UN"


    --Z35 - QUANTIDADE
    ,REPLACE(CAST(nf."Z35 - Quantidade" AS VARCHAR),'.', ',') AS "Z35.1 - Quantidade"
    ,LEN(LEFT("Z35.1 - Quantidade", CHARINDEX(',', "Z35.1 - Quantidade") - 1)) AS "Z35 - Quantidade - Prefix"
    ,CASE
        WHEN "Z35 - Quantidade - Prefix" = 4
            THEN CONCAT(LEFT("Z35.1 - Quantidade", 1), '.', SUBSTR("Z35.1 - Quantidade", 2, 3), ',', RIGHT("Z35.1 - Quantidade", 2))
        WHEN "Z35 - Quantidade - Prefix" = 5 
            THEN CONCAT(LEFT("Z35.1 - Quantidade", 2), '.', SUBSTR("Z35.1 - Quantidade", 3, 3), ',', RIGHT("Z35.1 - Quantidade", 2))
        WHEN "Z35 - Quantidade - Prefix" = 6
            THEN CONCAT(LEFT("Z35 - Quantidade", 3), '.', SUBSTR("Z35.1 - Quantidade", 4, 3), ',', RIGHT("Z35.1 - Quantidade", 2))
        WHEN "Z35 - Quantidade - Prefix" = 7
            THEN CONCAT(LEFT("Z35.1 - Quantidade", 1), '.', SUBSTR("Z35.1 - Quantidade", 2, 3), '.', SUBSTR("Z35.1 - Quantidade", 5, 3), ',', RIGHT("Z35.1 - Quantidade", 2))
        WHEN "Z35 - Quantidade - Prefix" = 8
            THEN CONCAT(LEFT("Z35.1 - Quantidade", 2), '.', SUBSTR("Z35.1 - Quantidade", 3, 3), '.', SUBSTR("Z35.1 - Quantidade", 6, 3), ',', RIGHT("Z35.1 - Quantidade", 2)) 
        WHEN "Z35 - Quantidade - Prefix" = 9
            THEN CONCAT(LEFT("Z35.1 - Quantidade", 3), '.', SUBSTR("Z35.1 - Quantidade", 4, 3), '.', SUBSTR("Z35.1 - Quantidade", 7, 3), ',', RIGHT("Z35.1 - Quantidade", 2))
        ELSE "Z35.1 - Quantidade"
    END AS "Z35 - Quantidade"
    

    --Z36 - Valor Unitário
    ,nf."Z36 - Valor Unitário" AS "teste"
    ,REPLACE(CAST(nf."Z36 - Valor Unitário" AS VARCHAR),'.', ',') AS "Z36.1 - Valor Unitário"
    ,LEN(LEFT("Z36.1 - Valor Unitário", CHARINDEX(',', "Z36.1 - Valor Unitário") - 1)) AS "Z36 - Valor Unitário - Prefix"
    ,RIGHT("Z36.1 - Valor Unitário", CHARINDEX(',', "Z36.1 - Valor Unitário") - 2) AS "Z36 - Valor Unitário - Sufix"
    ,CASE
        WHEN "Z36 - Valor Unitário - Prefix" = 4
            THEN CONCAT(LEFT("Z36.1 - Valor Unitário", 1), '.', SUBSTR("Z36.1 - Valor Unitário", 2, 3), ',', "Z36 - Valor Unitário - Sufix")
        WHEN "Z36 - Valor Unitário - Prefix" = 5 
            THEN CONCAT(LEFT("Z36.1 - Valor Unitário", 2), '.', SUBSTR("Z36.1 - Valor Unitário", 3, 3), ',', "Z36 - Valor Unitário - Sufix")
        WHEN "Z36 - Valor Unitário - Prefix" = 6
            THEN CONCAT(LEFT("Z36 - Valor Unitário", 3), '.', SUBSTR("Z36.1 - Valor Unitário", 4, 3), ',', "Z36 - Valor Unitário - Sufix")
        WHEN "Z36 - Valor Unitário - Prefix" = 7
            THEN CONCAT(LEFT("Z36.1 - Valor Unitário", 1), '.', SUBSTR("Z36.1 - Valor Unitário", 2, 3), '.', SUBSTR("Z36.1 - Valor Unitário", 5, 3), ',', "Z36 - Valor Unitário - Sufix") 
        WHEN "Z36 - Valor Unitário - Prefix" = 8
            THEN CONCAT(LEFT("Z36.1 - Valor Unitário", 2), '.', SUBSTR("Z36.1 - Valor Unitário", 3, 3), '.', SUBSTR("Z36.1 - Valor Unitário", 6, 3), ',', "Z36 - Valor Unitário - Sufix") 
        WHEN "Z36 - Valor Unitário - Prefix" = 9
            THEN CONCAT(LEFT("Z36.1 - Valor Unitário", 3), '.', SUBSTR("Z36.1 - Valor Unitário", 4, 3), '.', SUBSTR("Z36.1 - Valor Unitário", 7, 3), ',', "Z36 - Valor Unitário - Sufix")
        ELSE "Z36.1 - Valor Unitário"
    END AS "Z36 - Valor Unitário"
    

    --Z37 - Valor Total
    ,REPLACE(CAST(nf."Z37 - Valor Total" AS VARCHAR),'.', ',') AS "Z37.1 - Valor Total"
    ,LEN(LEFT("Z37.1 - Valor Total", CHARINDEX(',', "Z37.1 - Valor Total") - 1)) AS "Z37 - Valor Total - Prefix"
    ,CASE
        WHEN "Z37 - Valor Total - Prefix" = 4
            THEN CONCAT(LEFT("Z37.1 - Valor Total", 1), '.', SUBSTR("Z37.1 - Valor Total", 2, 3), ',', RIGHT("Z37.1 - Valor Total", 2))
        WHEN "Z37 - Valor Total - Prefix" = 5 
            THEN CONCAT(LEFT("Z37.1 - Valor Total", 2), '.', SUBSTR("Z37.1 - Valor Total", 3, 3), ',', RIGHT("Z37.1 - Valor Total", 2))
        WHEN "Z37 - Valor Total - Prefix" = 6
            THEN CONCAT(LEFT("Z37 - Valor Total", 3), '.', SUBSTR("Z37.1 - Valor Total", 4, 3), ',', RIGHT("Z37.1 - Valor Total", 2))
        WHEN "Z37 - Valor Total - Prefix" = 7
            THEN CONCAT(LEFT("Z37.1 - Valor Total", 1), '.', SUBSTR("Z37.1 - Valor Total", 2, 3), '.', SUBSTR("Z37.1 - Valor Total", 5, 3), ',', RIGHT("Z37.1 - Valor Total", 2)) 
        WHEN "Z37 - Valor Total - Prefix" = 8
            THEN CONCAT(LEFT("Z37.1 - Valor Total", 2), '.', SUBSTR("Z37.1 - Valor Total", 3, 3), '.', SUBSTR("Z37.1 - Valor Total", 6, 3), ',', RIGHT("Z37.1 - Valor Total", 2)) 
        WHEN "Z37 - Valor Total - Prefix" = 9
            THEN CONCAT(LEFT("Z37.1 - Valor Total", 3), '.', SUBSTR("Z37.1 - Valor Total", 4, 3), '.', SUBSTR("Z37.1 - Valor Total", 7, 3), ',', RIGHT("Z37.1 - Valor Total", 2))
        WHEN "Z37 - Valor Total - Prefix" = 8
            THEN CONCAT(LEFT("Z37.1 - Valor Total", 2), '.', SUBSTR("Z37.1 - Valor Total", 3, 3), '.', SUBSTR("Z37.1 - Valor Total", 6, 3), ',', RIGHT("Z37.1 - Valor Total", 2)) 
        WHEN "Z37 - Valor Total - Prefix" = 9
            THEN CONCAT(LEFT("Z37.1 - Valor Total", 3), '.', SUBSTR("Z37.1 - Valor Total", 4, 3), '.', SUBSTR("Z37.1 - Valor Total", 7, 3), ',', RIGHT("Z37.1 - Valor Total", 2))
        ELSE "Z37.1 - Valor Total"
    END AS "Z37 - Valor Total"

    
    --Z38 - Valor Desconto
    ,REPLACE(CAST(nf."Z38 - Valor Desconto" AS VARCHAR),'.', ',') AS "Z38.1 - Valor Desconto"
    ,LEN(LEFT("Z38.1 - Valor Desconto", CHARINDEX(',', "Z38.1 - Valor Desconto") - 1)) AS "Z38 - Valor Desconto - Prefix"
    ,CASE
        WHEN "Z38 - Valor Desconto - Prefix" = 4
            THEN CONCAT(LEFT("Z38.1 - Valor Desconto", 1), '.', SUBSTR("Z38.1 - Valor Desconto", 2, 3), ',', RIGHT("Z38.1 - Valor Desconto", 2))
        WHEN "Z38 - Valor Desconto - Prefix" = 5 
            THEN CONCAT(LEFT("Z38.1 - Valor Desconto", 2), '.', SUBSTR("Z38.1 - Valor Desconto", 3, 3), ',', RIGHT("Z38.1 - Valor Desconto", 2))
        WHEN "Z38 - Valor Desconto - Prefix" = 6
            THEN CONCAT(LEFT("Z38.1 - Valor Desconto", 3), '.', SUBSTR("Z38.1 - Valor Desconto", 4, 3), ',', RIGHT("Z38.1 - Valor Desconto", 2))
        WHEN "Z38 - Valor Desconto - Prefix" = 7
            THEN CONCAT(LEFT("Z38.1 - Valor Desconto", 1), '.', SUBSTR("Z38.1 - Valor Desconto", 2, 3), '.', SUBSTR("Z38.1 - Valor Desconto", 5, 3), ',', RIGHT("Z38.1 - Valor Desconto", 2))
        WHEN "Z38 - Valor Desconto - Prefix" = 8
            THEN CONCAT(LEFT("Z38.1 - Valor Desconto", 2), '.', SUBSTR("Z38.1 - Valor Desconto", 3, 3), '.', SUBSTR("Z38.1 - Valor Desconto", 6, 3), ',', RIGHT("Z38.1 - Valor Desconto", 2)) 
        WHEN "Z38 - Valor Desconto - Prefix" = 9
            THEN CONCAT(LEFT("Z38.1 - Valor Desconto", 3), '.', SUBSTR("Z38.1 - Valor Desconto", 4, 3), '.', SUBSTR("Z38.1 - Valor Desconto", 7, 3), ',', RIGHT("Z38.1 - Valor Desconto", 2))
        WHEN "Z38 - Valor Desconto - Prefix" = 8
            THEN CONCAT(LEFT("Z38.1 - Valor Desconto", 2), '.', SUBSTR("Z38.1 - Valor Desconto", 3, 3), '.', SUBSTR("Z38.1 - Valor Desconto", 6, 3), ',', RIGHT("Z38.1 - Valor Desconto", 2)) 
        WHEN "Z38 - Valor Desconto - Prefix" = 9
            THEN CONCAT(LEFT("Z38.1 - Valor Desconto", 3), '.', SUBSTR("Z38.1 - Valor Desconto", 4, 3), '.', SUBSTR("Z38.1 - Valor Desconto", 7, 3), ',', RIGHT("Z38.1 - Valor Desconto", 2))
        ELSE "Z38.1 - Valor Desconto"
    END AS "Z38 - Valor Desconto"

    
    --Z39 - Base de Calc do ICMS
    ,REPLACE(CAST(nf."Z39 - Base de Calc do ICMS" AS VARCHAR),'.', ',') AS "Z39.1 - Base de Calc do ICMS"
    ,LEN(LEFT("Z39.1 - Base de Calc do ICMS", CHARINDEX(',', "Z39.1 - Base de Calc do ICMS") - 1)) AS "Z39 - Base de Calc do ICMS - Prefix"
    ,CASE
        WHEN "Z39 - Base de Calc do ICMS - Prefix" = 4
            THEN CONCAT(LEFT("Z39.1 - Base de Calc do ICMS", 1), '.', SUBSTR("Z39.1 - Base de Calc do ICMS", 2, 3), ',', RIGHT("Z39.1 - Base de Calc do ICMS", 2))
        WHEN "Z39 - Base de Calc do ICMS - Prefix" = 5 
            THEN CONCAT(LEFT("Z39.1 - Base de Calc do ICMS", 2), '.', SUBSTR("Z39.1 - Base de Calc do ICMS", 3, 3), ',', RIGHT("Z39.1 - Base de Calc do ICMS", 2))
        WHEN "Z39 - Base de Calc do ICMS - Prefix" = 6
            THEN CONCAT(LEFT("Z39 - Base de Calc do ICMS", 3), '.', SUBSTR("Z39.1 - Base de Calc do ICMS", 4, 3), ',', RIGHT("Z39.1 - Base de Calc do ICMS", 2))
        WHEN "Z39 - Base de Calc do ICMS - Prefix" = 7
            THEN CONCAT(LEFT("Z39.1 - Base de Calc do ICMS", 1), '.', SUBSTR("Z39.1 - Base de Calc do ICMS", 2, 3), '.', SUBSTR("Z39.1 - Base de Calc do ICMS", 5, 3), ',', RIGHT("Z39.1 - Base de Calc do ICMS", 2)) 
        WHEN "Z39 - Base de Calc do ICMS - Prefix" = 8
            THEN CONCAT(LEFT("Z39.1 - Base de Calc do ICMS", 2), '.', SUBSTR("Z39.1 - Base de Calc do ICMS", 3, 3), '.', SUBSTR("Z39.1 - Base de Calc do ICMS", 6, 3), ',', RIGHT("Z39.1 - Base de Calc do ICMS", 2)) 
        WHEN "Z39 - Base de Calc do ICMS - Prefix" = 9
            THEN CONCAT(LEFT("Z39.1 - Base de Calc do ICMS", 3), '.', SUBSTR("Z39.1 - Base de Calc do ICMS", 4, 3), '.', SUBSTR("Z39.1 - Base de Calc do ICMS", 7, 3), ',', RIGHT("Z39.1 - Base de Calc do ICMS", 2))
        ELSE "Z39.1 - Base de Calc do ICMS"
    END AS "Z39 - Base de Calc do ICMS"

    
    --Z40 - Valor do ICMS
    ,REPLACE(CAST(nf."Z40 - Valor do ICMS" AS VARCHAR),'.', ',') AS "Z40.1 - Valor do ICMS"
    ,LEN(LEFT("Z40.1 - Valor do ICMS", CHARINDEX(',', "Z40.1 - Valor do ICMS") - 1)) AS "Z40 - Valor do ICMS - Prefix"
    ,CASE
        WHEN "Z40 - Valor do ICMS - Prefix" = 4
            THEN CONCAT(LEFT("Z40.1 - Valor do ICMS", 1), '.', SUBSTR("Z40.1 - Valor do ICMS", 2, 3), ',', RIGHT("Z40.1 - Valor do ICMS", 2))
        WHEN "Z40 - Valor do ICMS - Prefix" = 5 
            THEN CONCAT(LEFT("Z40.1 - Valor do ICMS", 2), '.', SUBSTR("Z40.1 - Valor do ICMS", 3, 3), ',', RIGHT("Z40.1 - Valor do ICMS", 2))
        WHEN "Z40 - Valor do ICMS - Prefix" = 6
            THEN CONCAT(LEFT("Z40 - Valor do ICMS", 3), '.', SUBSTR("Z40.1 - Valor do ICMS", 4, 3), ',', RIGHT("Z40.1 - Valor do ICMS", 2))
        WHEN "Z40 - Valor do ICMS - Prefix" = 7
            THEN CONCAT(LEFT("Z40.1 - Valor do ICMS", 1), '.', SUBSTR("Z40.1 - Valor do ICMS", 2, 3), '.', SUBSTR("Z40.1 - Valor do ICMS", 5, 3), ',', RIGHT("Z40.1 - Valor do ICMS", 2))
        WHEN "Z40 - Valor do ICMS - Prefix" = 8
            THEN CONCAT(LEFT("Z40.1 - Valor do ICMS", 2), '.', SUBSTR("Z40.1 - Valor do ICMS", 3, 3), '.', SUBSTR("Z40.1 - Valor do ICMS", 6, 3), ',', RIGHT("Z40.1 - Valor do ICMS", 2)) 
        WHEN "Z40 - Valor do ICMS - Prefix" = 9
            THEN CONCAT(LEFT("Z40.1 - Valor do ICMS", 3), '.', SUBSTR("Z40.1 - Valor do ICMS", 4, 3), '.', SUBSTR("Z40.1 - Valor do ICMS", 7, 3), ',', RIGHT("Z40.1 - Valor do ICMS", 2))
        ELSE "Z40.1 - Valor do ICMS"
    END AS "Z40 - Valor do ICMS"

    
    --Z41 - Valor Total IPI
    ,REPLACE(CAST(nf."Z41 - Valor Total IPI" AS VARCHAR),'.', ',') AS "Z41.1 - Valor Total IPI"
    ,LEN(LEFT("Z41.1 - Valor Total IPI", CHARINDEX(',', "Z41.1 - Valor Total IPI") - 1)) AS "Z41 - Valor Total IPI - Prefix"
    ,CASE
        WHEN "Z41 - Valor Total IPI - Prefix" = 4
            THEN CONCAT(LEFT("Z41.1 - Valor Total IPI", 1), '.', SUBSTR("Z41.1 - Valor Total IPI", 2, 3), ',', RIGHT("Z41.1 - Valor Total IPI", 2))
        WHEN "Z41 - Valor Total IPI - Prefix" = 5 
            THEN CONCAT(LEFT("Z41.1 - Valor Total IPI", 2), '.', SUBSTR("Z41.1 - Valor Total IPI", 3, 3), ',', RIGHT("Z41.1 - Valor Total IPI", 2))
        WHEN "Z41 - Valor Total IPI - Prefix" = 6
            THEN CONCAT(LEFT("Z41 - Valor Total IPI", 3), '.', SUBSTR("Z41.1 - Valor Total IPI", 4, 3), ',', RIGHT("Z41.1 - Valor Total IPI", 2))
        WHEN "Z41 - Valor Total IPI - Prefix" = 7
            THEN CONCAT(LEFT("Z41.1 - Valor Total IPI", 1), '.', SUBSTR("Z41.1 - Valor Total IPI", 2, 3), '.', SUBSTR("Z41.1 - Valor Total IPI", 5, 3), ',', RIGHT("Z41.1 - Valor Total IPI", 2))
        WHEN "Z41 - Valor Total IPI - Prefix" = 8
            THEN CONCAT(LEFT("Z41.1 - Valor Total IPI", 2), '.', SUBSTR("Z41.1 - Valor Total IPI", 3, 3), '.', SUBSTR("Z41.1 - Valor Total IPI", 6, 3), ',', RIGHT("Z41.1 - Valor Total IPI", 2)) 
        WHEN "Z41 - Valor Total IPI - Prefix" = 9
            THEN CONCAT(LEFT("Z41.1 - Valor Total IPI", 3), '.', SUBSTR("Z41.1 - Valor Total IPI", 4, 3), '.', SUBSTR("Z41.1 - Valor Total IPI", 7, 3), ',', RIGHT("Z41.1 - Valor Total IPI", 2))
        ELSE "Z41.1 - Valor Total IPI"
    END AS "Z41 - Valor Total IPI"

    
    ,REPLACE(CAST(nf."Z42 - Alíquota ICMS" AS VARCHAR),'.', ',') AS "Z42 - Alíquota ICMS"
    ,REPLACE(CAST(nf."Z43 - Alíquota IPI" AS VARCHAR),'.', ',') AS "Z43 - Alíquota IPI"
    ,nf.docnum
FROM 
    nf_data nf
LEFT JOIN fert_calculation fc ON nf."G - Chave de Acesso" = fc."G - Chave de Acesso"
)

SELECT
    nf."Componente Chave de Acesso 1"
    ,nf."Componente Chave de Acesso 2"
    ,nf."Componente Chave de Acesso 3"
    ,nf."Componente Chave de Acesso 4"
    ,nf."Componente Chave de Acesso 5"
    ,nf."Componente Chave de Acesso 6"
    ,nf."Componente Chave de Acesso 7"
    ,nf."Componente Chave de Acesso 8"
    ,nf."Componente Chave de Acesso 9"

    ,nf."A - Identificação Emitente"
    ,nf."A - Endereço Emitente"
    ,nf."A - Bairro Emitente"
    ,nf."A - CEP Emitente"
    ,nf."A - Município Emitente"
    ,nf."A - Estado Emitente"
    ,nf."A - Fone/Fax Emitente"
    ,nf."B - Natureza da Operação"
    ,nf."C - Inscrição Estadual Emitente"
    ,nf."D - Direção"
    ,nf."E - Num NF"
    ,nf."F - Série"
    ,nf."G - Chave de Acesso"
    ,nf."H - Protocolo"
    ,nf."I - CNPJ do Emitente - noformat"
    ,nf."I - CNPJ do Emitente"
    ,nf."J - Nome Cliente"
    ,nf."K - Endereço Cliente"
    ,nf."L - Município"
    ,nf."M - CNPJ Cliente"
    ,nf."N - Bairro"
    ,nf."O - Estado"
    ,nf."P - Fone/Tax"
    ,nf."Q - CEP"
    ,nf."R - Inscrição Estadual Cliente"
    ,TO_CHAR(nf."S - Data da Emissão") AS "S - Data da Emissão"
    ,nf."T - Base de Calc do ICMS"
    ,nf."U - Valor do Frete"
    ,nf."V - Valor do ICMS"
    ,nf."X - Valor do Seguro"
    ,nf."Z - Base de Calc ICMS S.T."
    ,nf."Z1 - Desconto"
    ,nf."Z2 - Valor do ICMS Subst."
    ,nf."Z3 - Outras Despesas"
    ,nf."Z4 - Valor Importação"
    ,nf."Z5 - Valor Total IPI"
    ,nf."Z6 - ICMS UF Remetente"
    ,nf."Z7 - ICMS UF Destino"
    ,nf."Z8 - Valor FCP UF Destino"
    ,nf."Z9 - Valor Total Impostos"
    ,nf."Z10 - Valor do PIS"
    ,nf."Z11 - Valor da COFINS"
    ,nf."Z12 - Valor Total Produtos"
    ,nf."Z13 - Valor Total da Nota"
    ,nf."Z14 - Nome Transportador"
    ,nf."Z15 - Endereço Transportador"
    ,nf."Z16 - Quantidade"
    ,nf."Z17 - Frete"
    ,nf."Z21 - Município Transportador"
    ,nf."Z23 - Peso Bruto"
    ,nf."Z24 - UF"
    ,nf."Z25 - UF"
    ,nf."Z26 - CNPJ Transportador"
    ,nf."Z27 - Inscrição Estadual Transportador"
    ,nf."Z28 - Peso Líquido"
    ,nf."Número do Item"
    ,nf."Z29 - Código do Produto"
    ,nf."Z30 - Descrição do Produto"
    ,nf."Z31 - NCM/SH"
    ,nf."Z32 - O/CST"
    ,nf."Z33 - CFOP"
    ,nf."Z34 - UN"
    ,nf."Z35 - Quantidade"
    ,nf."teste"
    ,nf."Z36 - Valor Unitário"
    ,nf."Z37 - Valor Total"
    ,nf."Z38 - Valor Desconto"
    ,nf."Z39 - Base de Calc do ICMS"
    ,nf."Z40 - Valor do ICMS"
    ,nf."Z41 - Valor Total IPI"
    ,nf."Z42 - Alíquota ICMS"
    ,nf."Z43 - Alíquota IPI"
    ,nf.docnum
FROM 
    nf_convertions nf
