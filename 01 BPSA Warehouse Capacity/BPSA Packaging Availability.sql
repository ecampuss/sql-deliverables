WITH pallets AS (
SELECT * FROM (VALUES
('000000000300000014','VERP',10),
('000000000300000027','VERP',32.5),	 	
('000000000300000131','VERP',10),
('000000000300000230','VERP',10),
('000000000300000253','VERP',10),
('000000000350000004','LEIH',10),
('000000000350000006','LEIH',0),
('000000000350000005','LEIH',10),
('000000000350000007','LEIH',32.5),
('000000000350000021','LEIH',10),
('000000000350000034','LEIH',10),
('000000000350000072','LEIH',10)x(material, type, pp)
)
),

wh_capacity_pack AS (
SELECT
    IFF(wh.type = 'Warehouse', wh.location_code, LPAD(wh.location_code, 10, '0')) AS location_code
    ,wh.location_name
    ,wh.plant
    ,wh.pallet_capacity
    ,wh.topframe_capacity
FROM 
    BALL_SANDBOX.USER_ESANTOS2."01_WAREHOUSING_CAPACITY" wh
WHERE
    wh.type = 'Plant'
),

inventory AS (
SELECT
    inv."Date of Analysis"
    ,inv."Material"
    ,mara.mtart AS "Material Type"
    ,makt.maktx AS "Material Description"
    ,inv."Plant"
    ,inv."Storage Location"
    ,inv."Customer"
    ,inv."Vendor"
    ,inv."Status"
    ,mara.matkl AS "Material Group"
    ,p.pp AS "Number of Pallets"
    ,inv."Stock at Plant"
    ,DIV0(inv."Stock at Plant", p.pp) AS "Utilization"
FROM 
    DW_STAGING.SAP_SABEV.VW_FCT_INVENTORY_AGING inv
INNER JOIN DW_STAGING.SAP_SABEV.MARA mara ON inv."Material" = mara.matnr AND mara.mandt = '300'
INNER JOIN DW_STAGING.SAP_SABEV.MAKT makt ON mara.matnr = makt.matnr AND makt.spras = 'P' AND makt.mandt = '300'
INNER JOIN pallets p ON mara.matnr = p.material AND mara.mtart = p.type
WHERE
    mara.mtart IN ('LEIH', 'VERP')
),

utilization_packaging AS (
SELECT
    u."Date of Analysis" AS "Date"
    ,u."Material"
    ,u."Material Type"
    ,u."Material Description"
    ,u."Plant"
    ,SUM(u."Utilization") AS "Utilization Quantity"
FROM 
    inventory u
GROUP BY ALL
)

SELECT
    up."Date"
    ,up."Material"
    ,up."Material Type"
    ,up."Material Description"
    ,up."Plant"
    ,up."Utilization Quantity"
    ,whp.pallet_capacity + whp.topframe_capacity AS "Packaging Capacity"
    ,DIV0("Utilization Quantity", "Packaging Capacity") AS "Packaging Utilization"
FROM 
    utilization_packaging up
INNER JOIN wh_capacity_pack whp ON up."Plant" = whp.plant