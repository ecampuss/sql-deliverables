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
('81372', 8446,'Cans'),
('81410', 7080,'Cans'),
('81472', 6224,'Cans'),
('81710', 4082,'Cans'),
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
    ,p.plant AS "Plant"
    ,p.location_code AS "Warehouse"
FROM 
    future_dates fd 
JOIN wh_capacity_ag p
),

inventory AS (
SELECT
    inv."Date of Analysis"
    ,inv."Material"
    ,inv."Plant"
    ,inv."Storage Location"
    ,inv."Customer"
    ,inv."Vendor"
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
    ,u."Storage Location"
    ,u."Customer"
    ,plt.types AS "Material Type"
    ,SUM(u."Utilization") AS "Utilization Quantity - Cans"
FROM pre_utilization_ag u
INNER JOIN pallets plt ON u."Material Group" = plt.mat_group
WHERE
    plt.types = 'Cans'
GROUP BY ALL
),

utilization_ag_ends AS (
SELECT
    u."Date of Analysis" AS "Date"
    ,u."Plant"
    ,u."Storage Location"
    ,u."Customer"
    ,plt.types AS "Material Type"
    ,SUM(u."Utilization") AS "Utilization Quantity - Ends"
FROM pre_utilization_ag u
INNER JOIN pallets plt ON u."Material Group" = plt.mat_group
WHERE
    plt.types = 'Ends'
GROUP BY ALL
),

utilization_ag_total AS (
SELECT
    u."Date"
    ,u."Plant"
    ,u."Storage Location" AS "Warehouse"
    ,IFNULL(SUM(u."Utilization Quantity - Cans"),0) AS "Utilization Quantity - Cans"
    ,0 AS "Utilization Quantity - Ends"
FROM 
    utilization_ag_cans u
WHERE
    u."Storage Location" IN (SELECT location_code FROM wh_capacity_ag)
GROUP BY ALL

    UNION ALL

SELECT
    u."Date"
    ,u."Plant"
    ,u."Storage Location" AS "Warehouse"
    ,0 AS "Utilization Quantity - Cans"
    ,IFNULL(SUM(u."Utilization Quantity - Ends"),0) AS "Utilization Quantity - Ends"
FROM 
    utilization_ag_ends u
WHERE
    u."Storage Location" IN (SELECT location_code FROM wh_capacity_ag)
GROUP BY ALL

    UNION ALL

SELECT
    u."Date"
    ,u."Plant"
    ,u."Customer" AS "Warehouse"
    ,IFNULL(SUM(u."Utilization Quantity - Cans"),0) AS "Utilization Quantity - Cans"
    ,0 AS "Utilization Quantity - Ends"
FROM 
    utilization_ag_cans u
WHERE
    u."Customer" IN (SELECT location_code FROM wh_capacity_ag)
GROUP BY ALL

    UNION ALL

SELECT
    u."Date"
    ,u."Plant"
    ,u."Customer" AS "Warehouse"
    ,0 AS "Utilization Quantity - Cans"
    ,IFNULL(SUM(u."Utilization Quantity - Ends"),0) AS "Utilization Quantity - Ends"
FROM 
    utilization_ag_ends u
WHERE
    u."Customer" IN (SELECT location_code FROM wh_capacity_ag)
GROUP BY ALL
),

utilization_ag AS (
SELECT 
    u."Date"
    ,u."Plant"
    ,u."Warehouse"
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
    ,vbap.lgort AS "Warehouse"
    ,vbak.kunnr AS "Customer"
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
),

pre_sales_orders_ag_cans AS (
SELECT 
    so."Date"
    ,so."Plant"
    ,so."Customer"
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
    ,so."Customer"
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
    ,so."Customer"
    ,IFNULL(SUM(so."Sales Quantity - Cans"),0) AS "Sales Quantity - Cans"
    ,0 AS "Sales Quantity - Ends"
FROM 
    pre_sales_orders_ag_cans so
GROUP BY ALL

    UNION ALL

SELECT 
    so."Date"
    ,so."Plant"
    ,so."Customer"
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
    ,so."Customer" AS "Warehouse"
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
    ,wh.location_code AS "Warehouse"
    ,SUM(wh.can_capacity) AS "Pre Capacity Quantity AG - Cans"
    ,SUM(wh.end_capacity) AS "Pre Capacity Quantity AG - Ends"
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
    ,pc."Warehouse"
    ,SUM(pc."Pre Capacity Quantity AG - Cans") AS "Pre Capacity Quantity AG - Cans"
    ,SUM(pc."Pre Capacity Quantity AG - Ends") AS "Pre Capacity Quantity AG - Ends"
FROM 
    pre_capacity_ag pc
GROUP BY ALL
)

SELECT 
    pd."Date"
    ,pd."Plant"
    ,pd."Warehouse"
    
    ,IFNULL(ca."Pre Capacity Quantity AG - Cans", 0) AS "Capacity Quantity AG Only - Cans"
    ,IFNULL(ca."Pre Capacity Quantity AG - Ends", 0) AS "Capacity Quantity AG Only - Ends"
    ,("Capacity Quantity AG Only - Cans" + "Capacity Quantity AG Only - Ends") AS "Capacity Quantity AG Only"
    
    ,ROUND(IFNULL(ua."Utilization Quantity - Cans",0),0) AS "Stock Quantity AG Only - Cans"
    ,ROUND(IFNULL(ua."Utilization Quantity - Ends",0),0) AS "Stock Quantity AG Only - Ends"
    ,("Stock Quantity AG Only - Cans" + "Stock Quantity AG Only - Ends") AS "Stock Quantity AG Only"
        
    ,ROUND(IFNULL(soa."Sales Quantity - Cans",0),0) AS "Sales Quantity AG Only - Cans"
    ,ROUND(IFNULL(soa."Sales Quantity - Ends",0),0) AS "Sales Quantity AG Only - Ends"
    ,("Sales Quantity AG Only - Cans" + "Sales Quantity AG Only - Ends") AS "Sales Quantity AG Only"

    ,SUM("Stock Quantity AG Only - Cans" - "Sales Quantity AG Only - Cans") OVER (PARTITION BY pd."Plant", pd."Warehouse" ORDER BY TO_DATE(pd."Date") ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS "Daily Result AG Only - Cans"
    ,SUM("Stock Quantity AG Only - Ends" - "Sales Quantity AG Only - Ends") OVER (PARTITION BY pd."Plant", pd."Warehouse" ORDER BY TO_DATE(pd."Date") ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS "Daily Result AG Only - Ends"
    ,SUM("Stock Quantity AG Only" - "Sales Quantity AG Only") OVER (PARTITION BY pd."Plant", pd."Warehouse" ORDER BY TO_DATE(pd."Date") ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS "Daily Result AG Only"

    ,DIV0("Daily Result AG Only - Cans","Capacity Quantity AG Only - Cans") AS "Warehouse Ocupation AG Only - Cans"
    ,DIV0("Daily Result AG Only - Ends","Capacity Quantity AG Only - Ends") AS "Warehouse Ocupation AG Only - Ends"
    ,DIV0("Daily Result AG Only","Capacity Quantity AG Only") AS "Warehouse Ocupation AG Only"
    
FROM 
    plants_n_dates pd
LEFT JOIN utilization_ag ua ON ua."Date" = pd."Date" AND ua."Plant" = pd."Plant" AND ua."Warehouse" = pd."Warehouse" AND ua."Warehouse" <> ' ' 
LEFT JOIN sales_orders_ag soa ON soa."Date" = pd."Date" AND soa."Plant" = pd."Plant" --AND soa."Warehouse" = pd."Warehouse"
LEFT JOIN capacity_ag ca ON ca."Date" = pd."Date" AND ca."Plant" = pd."Plant" AND ca."Warehouse" = pd."Warehouse"
WHERE
    pd."Plant" = 'BRPE'