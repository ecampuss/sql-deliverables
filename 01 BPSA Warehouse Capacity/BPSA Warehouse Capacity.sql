WITH future_dates AS (
SELECT * FROM VALUES
    (CURRENT_DATE()),
    (DATEADD(DAY, 1, CURRENT_DATE())),
    (DATEADD(DAY, 2, CURRENT_DATE())),
    (DATEADD(DAY, 3, CURRENT_DATE())),
    (DATEADD(DAY, 4, CURRENT_DATE())),
    (DATEADD(DAY, 5, CURRENT_DATE())),
    (DATEADD(DAY, 6, CURRENT_DATE())),
    (DATEADD(DAY, 7, CURRENT_DATE())),
    (DATEADD(DAY, 8, CURRENT_DATE())),
    (DATEADD(DAY, 9, CURRENT_DATE())),
    (DATEADD(DAY, 10, CURRENT_DATE())),
    (DATEADD(DAY, 11, CURRENT_DATE())),
    (DATEADD(DAY, 12, CURRENT_DATE())),
    (DATEADD(DAY, 13, CURRENT_DATE())),
    (DATEADD(DAY, 14, CURRENT_DATE())),
    (DATEADD(DAY, 15, CURRENT_DATE())),
    (DATEADD(DAY, 16, CURRENT_DATE())),
    (DATEADD(DAY, 17, CURRENT_DATE())),
    (DATEADD(DAY, 18, CURRENT_DATE())),
    (DATEADD(DAY, 19, CURRENT_DATE())),
    (DATEADD(DAY, 20, CURRENT_DATE())),
    (DATEADD(DAY, 21, CURRENT_DATE())),
    (DATEADD(DAY, 22, CURRENT_DATE())),
    (DATEADD(DAY, 23, CURRENT_DATE())),
    (DATEADD(DAY, 24, CURRENT_DATE())),
    (DATEADD(DAY, 25, CURRENT_DATE())),
    (DATEADD(DAY, 26, CURRENT_DATE())),
    (DATEADD(DAY, 27, CURRENT_DATE())),
    (DATEADD(DAY, 28, CURRENT_DATE())),
    (DATEADD(DAY, 29, CURRENT_DATE())),
    (DATEADD(DAY, 30, CURRENT_DATE()))
    x(dates)
),

wh_capacity_plants AS (
SELECT
    fd.dates AS "Date"
    ,CASE 
        WHEN wh.location_code = 'BRPD' THEN 'BRPA'
        WHEN wh.location_code = 'BRRE' THEN 'BRPE'
        WHEN wh.location_code = 'BRRC' THEN 'BRPE'
        WHEN wh.location_code = 'RISC' THEN 'BR3R'
        ELSE wh.location_code
    END AS "Plant"
    ,wh.can_capacity AS "Capacity Quantity Plant - Cans"
    ,wh.end_capacity AS "Capacity Quantity Plant - Ends"
FROM BALL_SANDBOX.USER_ESANTOS2."01_WAREHOUSING_CAPACITY" wh
JOIN future_dates fd
WHERE 
    wh.type = 'Plant'
),

wh_capacity_ag AS (
SELECT
    IFF(wh.type = 'Warehouse', wh.location_code, LPAD(wh.location_code, 10, '0')) AS location_code
    ,wh.location_name
    ,wh.storage_type
    ,wh.can_capacity
    ,wh.end_capacity
    ,wh.based_on_usage
    ,wh.plant
    ,wh.region 
    ,wh.inventory_level_min
	,wh.country
    ,wh.type
FROM 
    BALL_SANDBOX.USER_ESANTOS2."01_WAREHOUSING_CAPACITY" wh
WHERE 
    wh.type <> 'Plant'
),

pallets AS (
SELECT * FROM (VALUES
('81222', 11616,'Cans'),
('81262', 11088,'Cans'),
('81312', 9504,'Cans'),
('81362', 8169,'Cans'),
('81372', 8448,'Cans'),
('81410', 7080,'Cans'),
('81472', 6224,'Cans'),
('81710', 3768,'Cans'),
('83262', 11088,'Cans'),
('83312', 9504,'Cans'),
('83372', 8446,'Cans'),
('83472', 6224,'Cans'),
('83710', 4082,'Cans'),
('86262', 11088,'Cans'),
('86312', 9504,'Cans'),
('86473', 6224,'Cans'),
('89002', 289800,'Ends'),
('89202', 275310,'Ends'),
('89209', 146832,'Ends')) x(mat_group, pnum, types)
),

plants_n_dates AS (
SELECT DISTINCT
    fd.dates AS "Date"
    ,p."Plant"
FROM 
    future_dates fd 
JOIN wh_capacity_plants p
),

inventory AS (
SELECT
    inv."Date of Analysis"
    ,inv."Material"
    ,inv."Plant"
    ,inv."Storage Location"
    ,inv."Customer"
    ,inv."Vendor"
    ,inv."Status"
    ,mara.matkl AS "Material Group"
    ,marc.bstrf AS "Number of Pallets"
    ,inv."Stock at Plant"
    ,DIV0(inv."Stock at Plant", marc.bstrf) AS "Utilization"
FROM DW_STAGING.SAP_SABEV.VW_FCT_INVENTORY_AGING inv
INNER JOIN DW_STAGING.SAP_SABEV.MARA mara ON inv."Material" = mara.matnr AND mara.mandt = '300'
INNER JOIN DW_STAGING.SAP_SABEV.MARC marc ON inv."Material" = marc.matnr AND inv."Plant" = marc.werks AND marc.mandt = '300'
WHERE
    mara.mtart = 'FERT'
    AND inv."Status" <> 'Stock in Transit'
    AND inv."Storage Location" <> '1300'
),

pre_utilization_plants AS (
SELECT
    inv."Date of Analysis"
    ,inv."Material"
    ,inv."Plant"
    ,inv."Storage Location"
    ,inv."Customer"
    ,inv."Vendor"
    ,inv."Material Group"
    ,inv."Number of Pallets"
    ,inv."Stock at Plant"
    ,inv."Utilization"
FROM 
    inventory inv
WHERE
    inv."Storage Location" NOT IN (SELECT location_code FROM wh_capacity_ag)
    AND inv."Customer" NOT IN (SELECT location_code FROM wh_capacity_ag)
),

utilization_plants_cans AS (
SELECT
    u."Date of Analysis" AS "Date"
    ,u."Plant"
    ,plt.types AS "Material Type"
    ,SUM(u."Utilization") AS "Utilization Quantity - Cans"
FROM pre_utilization_plants u
INNER JOIN pallets plt ON u."Material Group" = plt.mat_group
WHERE
    plt.types = 'Cans'
GROUP BY ALL
),

utilization_plants_ends AS (
SELECT
    u."Date of Analysis" AS "Date"
    ,u."Plant"
    ,plt.types AS "Material Type"
    ,SUM(u."Utilization") AS "Utilization Quantity - Ends"
FROM pre_utilization_plants u
INNER JOIN pallets plt ON u."Material Group" = plt.mat_group
WHERE
    plt.types = 'Ends'
GROUP BY ALL
),

utilization_plants_total AS (
SELECT
    uc."Date"
    ,uc."Plant"
    ,IFNULL(SUM(uc."Utilization Quantity - Cans"),0) AS "Utilization Quantity - Cans"
    ,0 AS "Utilization Quantity - Ends"
FROM 
    utilization_plants_cans uc
GROUP BY ALL

    UNION ALL

SELECT
    ue."Date"
    ,ue."Plant"
    ,0 AS "Utilization Quantity - Cans"
    ,IFNULL(SUM(ue."Utilization Quantity - Ends"),0) AS "Utilization Quantity - Ends"
FROM 
    utilization_plants_ends ue
GROUP BY ALL
),

utilization_plants AS (
SELECT
    u."Date"
    ,u."Plant"
    ,IFNULL(SUM(u."Utilization Quantity - Cans"),0) AS "Utilization Quantity - Cans"
    ,IFNULL(SUM(u."Utilization Quantity - Ends"),0) AS "Utilization Quantity - Ends"
FROM 
    utilization_plants_total u
GROUP BY ALL
),

pre_sales_orders_plants AS (
SELECT
    TRY_TO_DATE(vbep.tddat, 'YYYYMMDD') AS "Date"
    ,vbap.vbeln AS "Sales Order"
    ,vbap.posnr AS "Item"
    ,vbak.auart AS "Order Type"
    ,vbap.werks AS "Plant"
    ,mara.matnr AS "Material"
    ,mara.matkl AS "Material Group"
    ,plt.types AS "Material Type"
    ,vbep.wmeng * 1000 AS "Quantity"
    ,vbep.meins AS "Base Unit"
    ,plt.pnum AS "Number per Pallet"
FROM 
    DW_STAGING.SAP_SABEV.VBAK vbak
INNER JOIN DW_STAGING.SAP_SABEV.VBAP vbap ON vbak.vbeln = vbap.vbeln AND vbap.mandt = '300'
INNER JOIN DW_STAGING.SAP_SABEV.VBEP vbep ON vbap.vbeln = vbep.vbeln AND vbap.posnr = vbep.posnr AND vbep.mandt = '300'
INNER JOIN DW_STAGING.SAP_SABEV.MARA mara ON vbap.matnr = mara.matnr AND mara.mandt = '300'
INNER JOIN pallets plt ON mara.matkl = plt.mat_group
INNER JOIN future_dates fd ON TRY_TO_DATE(vbep.tddat, 'YYYYMMDD') = fd.dates
WHERE
    (mara.matkl LIKE '8%'
    OR mara.matkl LIKE '9%')
    AND vbak.auart <> 'ZBA3'
    AND vbap.abgru = ' '
),

pre_sales_orders_plants_cans AS (
SELECT 
    so."Date"
    ,so."Plant"
    ,so."Material Group"
    ,so."Material Type"
    ,DIV0(so."Quantity", so."Number per Pallet") AS "Sales Quantity - Cans" 
FROM 
    pre_sales_orders_plants so
WHERE
    so."Material Type" = 'Cans'
),

pre_sales_orders_plants_ends AS (
SELECT 
    so."Date"
    ,so."Plant"
    ,so."Material Group"
    ,so."Material Type"
    ,DIV0(so."Quantity", so."Number per Pallet") AS "Sales Quantity - Ends" 
FROM 
    pre_sales_orders_plants so
WHERE
    so."Material Type" = 'Ends'
),

sales_orders_plants_total AS (
SELECT 
    so."Date"
    ,so."Plant"
    ,IFNULL(SUM(so."Sales Quantity - Cans"),0) AS "Sales Quantity - Cans"
    ,0 AS "Sales Quantity - Ends"
FROM 
    pre_sales_orders_plants_cans so
GROUP BY ALL

    UNION ALL
    
SELECT 
    so."Date"
    ,so."Plant"
    ,0 AS "Sales Quantity - Cans"
    ,IFNULL(SUM(so."Sales Quantity - Ends"),0) AS "Sales Quantity - Ends"
FROM 
    pre_sales_orders_plants_ends so
GROUP BY ALL
),

sales_orders_plants AS (
SELECT 
    so."Date"
    ,so."Plant"
    ,IFNULL(SUM(so."Sales Quantity - Cans"),0) AS "Sales Quantity - Cans"
    ,IFNULL(SUM(so."Sales Quantity - Ends"),0) AS "Sales Quantity - Ends"
FROM 
    sales_orders_plants_total so
GROUP BY ALL
),

calc_production_plants AS (
SELECT
    TRY_TO_DATE(zbw.dtplan, 'YYYYMMDD') AS "Date"
    ,zbw.werks AS "Plant"
    ,zbw.matkl AS "Material Group"
    ,plt.types AS "Material Type"
    ,zbw.quantidade AS "Item Quantity"
FROM 
    "DW_STAGING"."SAP_SABEV"."ZTBBW_PRD_LINES" zbw
INNER JOIN "DW_STAGING"."SAP_SABEV"."T023T" t023t ON t023t.matkl = zbw.matkl
INNER JOIN "DW_STAGING"."SAP_SABEV"."T001W" t001w ON zbw.werks = t001w.werks
INNER JOIN future_dates fd ON TRY_TO_DATE(zbw.dtplan, 'YYYYMMDD') = fd.dates
INNER JOIN pallets plt ON plt.mat_group = zbw.matkl 
WHERE 
    1=1
    AND zbw.dtcarga = (SELECT DISTINCT MAX(dtcarga) FROM "DW_STAGING"."SAP_SABEV"."ZTBBW_PRD_LINES" WHERE ctg_rep = '20')
    AND zbw.mandt = '300'
    AND t001w.mandt = '300'
    AND t023t.mandt = '300'
    AND t023t.spras = 'P'
    AND zbw.ctg_rep = '20' 
),

calc02_production_plants AS (
SELECT
    prd."Date"
    ,prd."Plant"
    ,prd."Material Group"
    ,prd."Material Type"
    ,SUM(prd."Item Quantity") AS "Quantity" 
FROM 
    calc_production_plants prd
GROUP BY ALL
),

calc03_production_plants AS (
SELECT
    prd."Date"
    ,prd."Plant"
    ,prd."Material Group"
    ,prd."Material Type"
    ,DIV0((prd."Quantity" * 1000000), plt.pnum) AS "Pallet Quantity"
FROM 
    calc02_production_plants prd
INNER JOIN pallets plt ON prd."Material Group" = plt.mat_group
),

calc04_production_plants AS (
SELECT
    prd."Date"
    ,prd."Plant"
    ,prd."Material Group"
    ,prd."Material Type"
    ,SUM(prd."Pallet Quantity") AS "Pallet Quantity"
FROM 
    calc03_production_plants prd
GROUP BY ALL
HAVING SUM(prd."Pallet Quantity") > 0
),

avg_production_plants AS (
SELECT
    prd."Plant"
    ,prd."Material Group"
    ,prd."Material Type"
    ,AVG(prd."Pallet Quantity") AS "Avg Pallet Quantity"
FROM 
    calc04_production_plants prd
GROUP BY ALL
),

pre_production_plants_cans AS (
SELECT 
    pp."Date"
    ,pp."Plant"
    ,'Cans' AS "Material Type"
    ,prd."Pallet Quantity"
FROM
    plants_n_dates pp
LEFT JOIN calc04_production_plants prd ON prd."Date" = pp."Date" AND prd."Plant" = pp."Plant" AND prd."Material Type" = 'Cans'
),

production_plants_cans AS (
SELECT DISTINCT
    pprd."Date"
    ,pprd."Plant"
    ,pprd."Material Type"
    ,IFNULL(pprd."Pallet Quantity", avgprd."Avg Pallet Quantity") AS "Production Quantity - Cans"
FROM
    pre_production_plants_cans pprd
INNER JOIN avg_production_plants avgprd ON pprd."Plant" = avgprd."Plant" AND avgprd."Material Type" = 'Cans'
),

pre_production_plants_ends AS (
SELECT 
    pp."Date"
    ,pp."Plant"
    ,'Ends' AS "Material Type"
    ,prd."Pallet Quantity"
FROM
    plants_n_dates pp
LEFT JOIN calc04_production_plants prd ON prd."Date" = pp."Date" AND prd."Plant" = pp."Plant" AND prd."Material Type" = 'Ends'
),

production_plants_ends AS (
SELECT DISTINCT
    pprd."Date"
    ,pprd."Plant"
    ,pprd."Material Type"
    ,IFNULL(pprd."Pallet Quantity", avgprd."Avg Pallet Quantity") AS "Production Quantity - Ends"
FROM
    pre_production_plants_ends pprd
INNER JOIN avg_production_plants avgprd ON pprd."Plant" = avgprd."Plant" AND avgprd."Material Type" = 'Ends'
),

production_plants_total AS (
SELECT 
    prd."Date"
    ,prd."Plant"
    ,IFNULL(SUM(prd."Production Quantity - Cans"),0) AS "Production Quantity - Cans"
    ,0 AS "Production Quantity - Ends"
FROM
    production_plants_cans prd
GROUP BY ALL

    UNION ALL

SELECT 
    prd."Date"
    ,prd."Plant"
    ,0 AS "Production Quantity - Cans"
    ,IFNULL(SUM(prd."Production Quantity - Ends"),0) AS "Production Quantity - Ends"
FROM
    production_plants_ends prd
GROUP BY ALL
),

production_plants AS (
SELECT 
    prd."Date"
    ,prd."Plant"
    ,IFNULL(SUM(prd."Production Quantity - Cans"),0) AS "Production Quantity - Cans"
    ,IFNULL(SUM(prd."Production Quantity - Ends"),0) AS "Production Quantity - Ends"
FROM
    production_plants_total prd
GROUP BY ALL
),

pre_utilization_ag AS (
SELECT
    inv."Date of Analysis"
    ,inv."Material"
    ,inv."Plant"
    ,inv."Storage Location"
    ,inv."Customer"
    ,inv."Vendor"
    ,inv."Material Group"
    ,inv."Number of Pallets"
    ,inv."Stock at Plant"
    ,inv."Utilization"
FROM 
    inventory inv
WHERE
    inv."Storage Location" IN (SELECT location_code FROM wh_capacity_ag)
    OR inv."Customer" IN (SELECT location_code FROM wh_capacity_ag)
),

utilization_ag_cans AS (
SELECT
    u."Date of Analysis" AS "Date"
    ,u."Plant"
    ,plt.types AS "Material Type"
    ,SUM(u."Utilization") AS "Utilization Quantity - Cans"
FROM 
    pre_utilization_ag u
INNER JOIN pallets plt ON u."Material Group" = plt.mat_group
WHERE
    plt.types = 'Cans'
GROUP BY ALL
),

utilization_ag_ends AS (
SELECT
    u."Date of Analysis" AS "Date"
    ,u."Plant"
    ,plt.types AS "Material Type"
    ,SUM(u."Utilization") AS "Utilization Quantity - Ends"
FROM 
    pre_utilization_ag u
INNER JOIN pallets plt ON u."Material Group" = plt.mat_group
WHERE
    plt.types = 'Ends'
GROUP BY ALL
),

utilization_ag_total AS (
SELECT
    u."Date"
    ,u."Plant"
    ,IFNULL(SUM(u."Utilization Quantity - Cans"),0) AS "Utilization Quantity - Cans"
    ,0 AS "Utilization Quantity - Ends"
FROM 
    utilization_ag_cans u
GROUP BY ALL

    UNION ALL

SELECT
    u."Date"
    ,u."Plant"
    ,0 AS "Utilization Quantity - Cans"
    ,IFNULL(SUM(u."Utilization Quantity - Ends"),0) AS "Utilization Quantity - Ends"
FROM 
    utilization_ag_ends u
GROUP BY ALL
),

utilization_ag AS (
SELECT
    u."Date"
    ,u."Plant"
    ,IFNULL(SUM(u."Utilization Quantity - Cans"),0) AS "Utilization Quantity - Cans"
    ,IFNULL(SUM(u."Utilization Quantity - Ends"),0) AS "Utilization Quantity - Ends"
FROM 
    utilization_ag_total u
GROUP BY ALL
),

pre_sales_orders_ag AS (
SELECT
    TRY_TO_DATE(vbep.tddat, 'YYYYMMDD') AS "Date"
    ,vbap.vbeln AS "Sales Order"
    ,vbap.posnr AS "Item"
    ,vbak.auart AS "Order Type"
    ,vbap.werks AS "Plant"
    ,mara.matkl AS "Material Group"
    ,plt.types AS "Material Type"
    ,vbep.wmeng * 1000 AS "Quantity"
    ,vbep.meins AS "Base Unit"
    ,plt.pnum AS "Number per Pallet"
FROM 
    DW_STAGING.SAP_SABEV.VBAK vbak
INNER JOIN DW_STAGING.SAP_SABEV.VBAP vbap ON vbak.vbeln = vbap.vbeln AND vbap.mandt = '300'
INNER JOIN DW_STAGING.SAP_SABEV.VBEP vbep ON vbap.vbeln = vbep.vbeln AND vbap.posnr = vbep.posnr AND vbep.mandt = '300'
INNER JOIN DW_STAGING.SAP_SABEV.MARA mara ON vbap.matnr = mara.matnr AND mara.mandt = '300'
INNER JOIN pallets plt ON mara.matkl = plt.mat_group
INNER JOIN future_dates fd ON TRY_TO_DATE(vbep.tddat, 'YYYYMMDD') = fd.dates
WHERE
    (mara.matkl LIKE '8%'
    OR mara.matkl LIKE '9%')
    AND vbak.auart = 'ZBA3'
    AND vbap.abgru = ' '
)

SELECT * FROM pre_sales_orders_ag WHERE "Plant" = 'BRPE';,

pre_sales_orders_ag_cans AS (
SELECT 
    so."Date"
    ,so."Plant"
    ,so."Material Group"
    ,so."Material Type"
    ,DIV0(so."Quantity", so."Number per Pallet") AS "Sales Quantity - Cans" 
FROM 
    pre_sales_orders_ag so
WHERE
    so."Material Type" = 'Cans'
),

pre_sales_orders_ag_ends AS (
SELECT 
    so."Date"
    ,so."Plant"
    ,so."Material Group"
    ,so."Material Type"
    ,DIV0(so."Quantity", so."Number per Pallet") AS "Sales Quantity - Ends" 
FROM 
    pre_sales_orders_ag so
WHERE
    so."Material Type" = 'Ends'
),

sales_orders_ag_total AS (
SELECT 
    so."Date"
    ,so."Plant"
    ,IFNULL(SUM(so."Sales Quantity - Cans"),0) AS "Sales Quantity - Cans"
    ,0 AS "Sales Quantity - Ends"   
FROM 
    pre_sales_orders_ag_cans so
GROUP BY ALL

    UNION ALL

SELECT 
    so."Date"
    ,so."Plant"
    ,0 AS "Sales Quantity - Cans"
    ,IFNULL(SUM(so."Sales Quantity - Ends"),0) AS "Sales Quantity - Ends"   
FROM 
    pre_sales_orders_ag_ends so
GROUP BY ALL
),    

sales_orders_ag AS (
SELECT 
    so."Date"
    ,so."Plant"
    ,IFNULL(SUM(so."Sales Quantity - Cans"),0) AS "Sales Quantity - Cans"
    ,IFNULL(SUM(so."Sales Quantity - Ends"),0) AS "Sales Quantity - Ends"   
FROM 
    sales_orders_ag_total so
GROUP BY ALL
),

pre_capacity_ag AS (
SELECT
    fd.dates AS "Date"
    ,t001k.bwkey AS "Plant"
    ,SUM(wh.can_capacity) AS "Pre Capacity Quantity AG - Cans"
    ,SUM(wh.end_capacity) AS "Pre Capacity Quantity AG - Ends"
    ,wh.inventory_level_min AS "Inventory Level Min"
FROM 
    wh_capacity_ag wh
INNER JOIN DW_STAGING.SAP_SABEV.T001K t001k ON wh.plant = t001k.bwkey AND t001k.mandt = '300'
JOIN future_dates fd
GROUP BY ALL
),

capacity_ag AS (
SELECT DISTINCT
    pc."Date"
    ,pc."Plant"
    ,SUM(pc."Pre Capacity Quantity AG - Cans") AS "Pre Capacity Quantity AG - Cans"
    ,SUM(pc."Pre Capacity Quantity AG - Ends") AS "Pre Capacity Quantity AG - Ends"
    ,SUM(pc."Inventory Level Min") AS "Inventory Level Min"
FROM 
    pre_capacity_ag pc
GROUP BY ALL
)

SELECT 
    pd."Date"
    ,pd."Plant"

    ,cp."Capacity Quantity Plant - Cans"
    ,cp."Capacity Quantity Plant - Ends"
    ,(cp."Capacity Quantity Plant - Cans" + cp."Capacity Quantity Plant - Ends") AS "Capacity Quantity Plant"
    
    ,IFNULL(ca."Pre Capacity Quantity AG - Cans", 0) AS "Capacity Quantity AG - Cans"
    ,IFNULL(ca."Pre Capacity Quantity AG - Ends", 0) AS "Capacity Quantity AG - Ends"
    ,("Capacity Quantity AG - Cans" + "Capacity Quantity AG - Ends") AS "Capacity Quantity AG"
    
    ,("Capacity Quantity Plant - Cans" + "Capacity Quantity AG - Cans") AS "Capacity Quantity Total - Cans"
    ,("Capacity Quantity Plant - Ends" + "Capacity Quantity AG - Ends") AS "Capacity Quantity Total - Ends"
    ,("Capacity Quantity Plant" + "Capacity Quantity AG") AS "Capacity Quantity Total"
    
    ,ROUND(IFNULL(up."Utilization Quantity - Cans",0),0) AS "Stock Quantity Plant - Cans"
    ,ROUND(IFNULL(up."Utilization Quantity - Ends",0),0) AS "Stock Quantity Plant - Ends"
    ,("Stock Quantity Plant - Cans" + "Stock Quantity Plant - Ends") AS "Stock Quantity Plant"

    ,ROUND(IFNULL(ua."Utilization Quantity - Cans",0),0) AS "Stock Quantity AG - Cans"
    ,ROUND(IFNULL(ua."Utilization Quantity - Ends",0),0) AS "Stock Quantity AG - Ends"
    ,("Stock Quantity AG - Cans" + "Stock Quantity AG - Ends") AS "Stock Quantity AG"

    ,ROUND(IFNULL(sop."Sales Quantity - Cans",0),0) AS "Sales Quantity Plant - Cans"
    ,ROUND(IFNULL(sop."Sales Quantity - Ends",0),0) AS "Sales Quantity Plant - Ends"
    ,("Sales Quantity Plant - Cans" + "Sales Quantity Plant - Ends") AS "Sales Quantity Plant"
    
    ,ROUND(IFNULL(soa."Sales Quantity - Cans",0),0) AS "Sales Quantity AG - Cans"
    ,ROUND(IFNULL(soa."Sales Quantity - Ends",0),0) AS "Sales Quantity AG - Ends"
    ,("Sales Quantity AG - Cans" + "Sales Quantity AG - Ends") AS "Sales Quantity AG"

    ,ROUND(IFNULL(pp."Production Quantity - Cans",0),0) AS "Production Quantity Plant - Cans"
    ,ROUND(IFNULL(pp."Production Quantity - Ends",0),0) AS "Production Quantity Plant - Ends"
    ,("Production Quantity Plant - Cans" + "Production Quantity Plant - Ends") AS "Production Quantity Plant"

    ,SUM("Stock Quantity Plant - Cans" - "Sales Quantity Plant - Cans" + "Production Quantity Plant - Cans") OVER (PARTITION BY pd."Plant" ORDER BY TO_DATE(pd."Date") ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS "Daily Result Plant - Cans"
    ,SUM("Stock Quantity Plant - Ends" - "Sales Quantity Plant - Ends" + "Production Quantity Plant - Ends") OVER (PARTITION BY pd."Plant" ORDER BY TO_DATE(pd."Date") ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS "Daily Result Plant - Ends"
    ,SUM("Stock Quantity Plant" - "Sales Quantity Plant" + "Production Quantity Plant") OVER (PARTITION BY pd."Plant" ORDER BY TO_DATE(pd."Date") ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS "Daily Result Plant"
    
    ,SUM("Stock Quantity AG - Cans" - "Sales Quantity AG - Cans") OVER (PARTITION BY pd."Plant" ORDER BY TO_DATE(pd."Date") ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS "Daily Result AG - Cans"
    ,SUM("Stock Quantity AG - Ends" - "Sales Quantity AG - Ends") OVER (PARTITION BY pd."Plant" ORDER BY TO_DATE(pd."Date") ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS "Daily Result AG - Ends"
    ,SUM("Stock Quantity AG" - "Sales Quantity AG") OVER (PARTITION BY pd."Plant" ORDER BY TO_DATE(pd."Date") ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS "Daily Result AG"

    ,("Daily Result Plant - Cans" + "Daily Result AG - Cans") AS "Daily Result Total - Cans"
    ,("Daily Result Plant - Ends" + "Daily Result AG - Ends") AS "Daily Result Total - Ends"
    ,("Daily Result Plant" + "Daily Result AG") AS "Daily Result Total"
    
    ,DIV0("Daily Result Plant - Cans","Capacity Quantity Plant - Cans") AS "Warehouse Ocupation Plant - Cans"
    ,DIV0("Daily Result Plant - Ends","Capacity Quantity Plant - Ends") AS "Warehouse Ocupation Plant - Ends"
    ,DIV0("Daily Result Plant","Capacity Quantity Plant") AS "Warehouse Ocupation Plant"
    
    ,DIV0("Daily Result AG - Cans","Capacity Quantity AG - Cans") AS "Warehouse Ocupation AG - Cans"
    ,DIV0("Daily Result AG - Ends","Capacity Quantity AG - Ends") AS "Warehouse Ocupation AG - Ends"
    ,DIV0("Daily Result AG","Capacity Quantity AG") AS "Warehouse Ocupation AG"
    
    ,DIV0("Daily Result Total - Cans", "Capacity Quantity Total - Cans") AS "Warehouse Ocupation Total - Cans"
    ,DIV0("Daily Result Total - Ends", "Capacity Quantity Total - Ends") AS "Warehouse Ocupation Total - Ends"
    ,DIV0("Daily Result Total", "Capacity Quantity Total") AS "Warehouse Ocupation Total"
FROM 
    plants_n_dates pd
LEFT JOIN utilization_plants up ON up."Date" = pd."Date" AND up."Plant" = pd."Plant"
LEFT JOIN utilization_ag ua ON ua."Date" = pd."Date" AND ua."Plant" = pd."Plant"

LEFT JOIN sales_orders_plants sop ON sop."Date" = pd."Date" AND sop."Plant" = pd."Plant"
LEFT JOIN sales_orders_ag soa ON soa."Date" = pd."Date" AND soa."Plant" = pd."Plant"

LEFT JOIN production_plants pp ON pp."Date" = pd."Date" AND pp."Plant" = pd."Plant"

INNER JOIN wh_capacity_plants cp ON cp."Date" = pd."Date" AND cp."Plant" = pd."Plant"
LEFT JOIN capacity_ag ca ON ca."Date" = pd."Date" AND ca."Plant" = pd."Plant"
WHERE
    pd."Plant" = 'BRPE'
