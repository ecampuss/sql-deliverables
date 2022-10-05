WITH materials AS (
SELECT
    DISTINCT CONCAT(matnr, werks) AS pk
FROM
    BALL_SANDBOX.USER_ESANTOS2.mardh
),

mat_master AS (
SELECT 
	RIGHT(matnr,9) AS matnr
FROM 
	DW_STAGING.SAP_EUBEV.mara
WHERE 
	matkl = '11006'
ORDER BY 
	1
),

plant_cur AS (
SELECT
    a.bukrs
    ,a.bwkey
    ,b.waers
FROM
    DW_STAGING.SAP_EUBEV.t001k a
INNER JOIN DW_STAGING.SAP_EUBEV.t001 b 
    ON a.bukrs = b.bukrs
),

last_year AS (
SELECT
    CONCAT(a.matnr, a.werks) AS pk
    ,a.matnr
    ,a.werks
    ,MAX(a.lfgja) AS max_year
    ,CONCAT(a.matnr, a.werks, max_year) AS new_pk
FROM
    BALL_SANDBOX.USER_ESANTOS2.mardh a
INNER JOIN materials b 
	ON pk = b.pk
GROUP BY
    1,
    2,
    3
),

last_month AS (
SELECT
    CONCAT(a.matnr, a.werks, a.lfgja) AS pk
    ,a.matnr
    ,a.werks
    ,a.lfgja
    ,MAX(a.lfmon) as max_month
FROM
    BALL_SANDBOX.USER_ESANTOS2.mardh a
INNER JOIN last_year b 
    ON CONCAT(a.matnr, a.werks, a.lfgja) = CONCAT(b.matnr, b.werks, b.max_year)
GROUP BY
    1
    ,2
    ,3
    ,4
),

curmon_stock_position AS (
SELECT
    CONCAT(a.matnr, a.werks) AS pk
    ,RIGHT(a.matnr,9) AS material
    ,a.werks
    ,'CURQ' AS mov_type
    ,a.lgort AS sto_loc
    ,a.lfgja
    ,a.lfmon
    ,0 AS salk3
    ,b.waers
    ,a.labst AS unrestricted
    ,a.umlme AS stock_in_transfer
    ,a.insme AS in_quality_insp
    ,a.einme AS restricted
    ,a.speme AS blocked
    ,a.retme AS returns_stock
    ,a.vmlab AS sp_stock_value
    ,a.vmuml AS st_trnsf_sp
FROM
    DW_STAGING.SAP_EUBEV.mard a
    INNER JOIN plant_cur b ON a.werks = b.bwkey
),

curmon_stock_amount AS (
SELECT
    CONCAT(a.matnr, a.bwkey) AS pk
    ,RIGHT(a.matnr, 9) AS material
    ,a.bwkey
    ,'CURA' AS mov_type
    ,'PLANT' AS sto_loc
    ,a.lfgja
    ,a.lfmon
    ,a.salk3
    ,c.waers
    ,0 AS unrestricted
    ,0 AS stock_in_transfer
    ,0 AS in_quality_insp
    ,0 AS restricted
    ,0 AS blocked
    ,0 AS returns_stock
    ,0 AS sp_stock_value
    ,0 AS st_trnsf_sp
FROM
    DW_STAGING.SAP_EUBEV.mbew a
    INNER JOIN last_month b ON CONCAT(RIGHT(a.matnr, 9), a.bwkey) = CONCAT(b.matnr, b.werks)
    INNER JOIN plant_cur c ON a.bwkey = c.bwkey
),

merged_curmon_stocks AS (
SELECT
    CONCAT(RIGHT(a.material,9), a.werks, a.lfgja, a.lfmon) AS pk
    ,a.material
    ,a.werks
    ,'CURQ' AS mov_type
    ,a.sto_loc
    ,a.lfgja
    ,a.lfmon
    ,0 AS salk3
    ,b.waers
    ,a.unrestricted
    ,a.stock_in_transfer
    ,a.in_quality_insp
    ,a.restricted
    ,a.blocked
    ,a.returns_stock
    ,a.sp_stock_value
    ,a.st_trnsf_sp
FROM
    curmon_stock_position a
INNER JOIN curmon_stock_amount b 
	ON CONCAT(a.material, a.werks, a.lfgja, a.lfmon) = CONCAT(b.material, b.bwkey, b.lfgja, b.lfmon) 
),

hist_stock_position AS (
SELECT
    CONCAT(a.matnr, a.werks) AS pk
    ,a.matnr AS material
    ,a.werks
    ,'HIST' AS mov_type
    ,a.lgort AS sto_loc
    ,a.lfgja
    ,a.lfmon
    ,0 AS salk3
    ,'POS' AS waers
    ,a.labst AS unrestricted
    ,a.umlme AS stock_in_transfer
    ,a.insme AS in_quality_insp
    ,a.einme AS restricted
    ,a.speme AS blocked
    ,a.retme AS returns_stock
    ,a.vklab AS sp_stock_value
    ,a.vkuml AS st_trnsf_sp
FROM
    BALL_SANDBOX.USER_ESANTOS2.mardh a
    LEFT JOIN last_month b ON CONCAT(a.matnr, a.werks, a.lfgja, a.lfmon) = CONCAT(b.matnr, b.werks, b.lfgja, b.max_month)
    INNER JOIN plant_cur c ON a.werks = c.bwkey
),

merged_hist_cur_stocks AS ( 
SELECT * FROM hist_stock_position
UNION ALL
SELECT * FROM merged_curmon_stocks	
),

mat_std_price AS (
SELECT 
	RIGHT(a.matnr,9) AS new_matnr
	,a.bwkey
	,CONCAT(a.lfgja,'.',a.lfmon) AS period
	,a.lfgja
	,a.lfmon
	,a.stprs
	,a.peinh 
	,IFF(a.stprs = 0 AND a.peinh = 0, 0,(a.stprs/a.peinh)) AS std_price 
FROM 
	BALL_SANDBOX.USER_ESANTOS2.mbewh a
INNER JOIN mat_master b 
	ON new_matnr = b.matnr
UNION ALL 
SELECT 
	RIGHT(a.matnr,9) AS new_matnr
	,a.bwkey
	,CONCAT(a.lfgja,'.',a.lfmon) AS period
	,a.lfgja
	,a.lfmon
	,a.stprs
	,a.peinh 
	,IFF(a.stprs = 0 AND a.peinh = 0, 0,(a.stprs/a.peinh)) AS std_price 
FROM 
	DW_STAGING.SAP_EUBEV.mbew a
INNER JOIN mat_master b 
	ON new_matnr = b.matnr
),

calculated_stoloc_stock AS (
SELECT
    a.material
    ,a.werks
    ,a.sto_loc
    ,a.lfgja
    ,a.lfmon
    ,b.std_price
    ,a.unrestricted
    ,(a.unrestricted * b.std_price) AS unrestricted_amt
    ,a.stock_in_transfer
    ,(a.stock_in_transfer * b.std_price) AS stock_in_transfer_amt
    ,a.in_quality_insp
    ,(a.in_quality_insp * b.std_price) AS in_quality_insp_amt
    ,a.restricted
    ,(a.restricted * b.std_price) AS restricted_amt
    ,a.blocked
    ,(a.blocked * b.std_price) AS blocked_amt
    ,a.returns_stock
    ,(a.returns_stock * b.std_price) AS returns_stock_amt
    ,a.sp_stock_value
    ,(a.sp_stock_value * b.std_price) AS sp_stock_value_amt
    ,a.st_trnsf_sp
    ,(a.st_trnsf_sp * b.std_price) AS st_trnsf_sp_amt
FROM
    merged_hist_cur_stocks a
INNER JOIN mat_std_price b 
	ON CONCAT(a.material, a.werks, a.lfgja, a.lfmon) = CONCAT(b.new_matnr, b.bwkey, b.lfgja, b.lfmon)
ORDER BY
    5
    ,4
    ,3
    ,2
    ,1

),

mat_movs AS (
SELECT
    RIGHT(a.matnr, 9) AS new_matnr
    ,a.werks
    ,a.bwart as mov_type
    ,a.lgort
    ,a.mjahr
    ,MONTH(TRY_TO_DATE(b.budat, 'YYYYMMDD')) AS pst_month
    ,SUM(IFF(a.shkzg = 'H', a.dmbtr * -1, a.dmbtr)) AS amount
    ,a.waers
    ,SUM(IFF(a.shkzg = 'H', a.menge * -1, a.menge)) AS unrestricted
    ,0 AS stock_in_transfer
    ,0 AS in_quality_insp
    ,0 AS restricted
    ,0 AS blocked
    ,0 AS returns_stock
    ,0 AS sp_stock_value
    ,0 AS st_trnsf_sp
FROM
    DW_STAGING.SAP_EUBEV.mseg a
INNER JOIN DW_STAGING.SAP_EUBEV.mkpf b 
	ON b.mblnr = a.mblnr AND b.mjahr = a.mjahr
INNER JOIN mat_master c 
	ON new_matnr = c.matnr
WHERE
    b.mjahr = a.mjahr AND b.mjahr = YEAR(DATE(GETDATE())) AND pst_month = MONTH(DATE(GETDATE()))
GROUP BY
    1
    ,2
    ,3
    ,4
    ,5
    ,6
    ,8
),

consolidated_qty_mat_movs AS (
SELECT 
	a.new_matnr
	,a.werks
	,a.lgort AS sto_loc
	,a.mjahr AS lfgja
	,a.pst_month AS lfmon
	,b.std_price AS std_price
	,SUM(IFF(mov_type IN ('101','261'), a.unrestricted, 0)) AS unrestricted
	,SUM(a.stock_in_transfer) AS stock_in_transfer
	,SUM(a.in_quality_insp) AS in_quality_insp
	,SUM(a.restricted) AS restricted
	,SUM(a.blocked) AS blocked
	,SUM(a.returns_stock) AS returns_stock
	,SUM(a.sp_stock_value) AS sp_stock_value
	,SUM(a.st_trnsf_sp) AS st_trnsf_sp
FROM mat_movs a
INNER JOIN mat_std_price b
	ON CONCAT(a.new_matnr, a.werks, a.mjahr, a.pst_month) = CONCAT(b.new_matnr, b.bwkey, LEFT(b.lfgja,4), REPLACE(b.lfmon,'.00000',''))
GROUP BY 
	1
	,2
	,3
	,4
	,5
	,6
),

consolidated_amount_mat_movs AS (
SELECT 
	a.new_matnr AS material
	,a.werks
	,a.sto_loc
	,a.lfgja
	,a.lfmon
	,a.std_price
	,a.unrestricted
	,a.std_price * a.unrestricted AS unrestricted_amt
	,a.stock_in_transfer
    ,a.std_price * a.stock_in_transfer AS stock_in_transfer_amt
	,a.in_quality_insp
    ,a.std_price * in_quality_insp AS in_quality_insp_amt
	,a.restricted
    ,a.std_price * a.restricted AS restricted_amt
	,a.blocked
    ,a.std_price * a.blocked AS blocked_amt
	,a.returns_stock
    ,a.std_price * a.returns_stock AS returns_stock_amt
	,a.sp_stock_value
    ,a.std_price * a.sp_stock_value AS sp_stock_value_amt
	,a.st_trnsf_sp
    ,a.std_price * a.st_trnsf_sp AS st_trnsf_sp_amt
FROM consolidated_qty_mat_movs a
),

stock_calc_result AS (
SELECT
    'table A' as tablename
    ,material
    ,werks
    ,sto_loc
    ,lfgja
    ,lfmon
    ,std_price
    ,unrestricted
    ,unrestricted_amt
    ,stock_in_transfer
    ,stock_in_transfer_amt
    ,in_quality_insp
    ,in_quality_insp_amt
    ,restricted
    ,restricted_amt
    ,blocked
    ,blocked_amt
    ,returns_stock
    ,returns_stock_amt
    ,sp_stock_value
    ,sp_stock_value_amt
    ,st_trnsf_sp
    ,st_trnsf_sp_amt
FROM calculated_stoloc_stock
    
UNION ALL
    
SELECT
    'table B' as tablename
	,material
	,werks
	,sto_loc
	,lfgja
	,lfmon
	,std_price
	,unrestricted
	,unrestricted_amt
	,stock_in_transfer
    ,stock_in_transfer_amt
	,in_quality_insp
    ,in_quality_insp_amt
	,restricted
    ,restricted_amt
	,blocked
    ,blocked_amt
	,returns_stock
    ,returns_stock_amt
	,sp_stock_value
    ,sp_stock_value_amt
	,st_trnsf_sp
    ,st_trnsf_sp_amt
FROM consolidated_amount_mat_movs
)

 
SELECT 
    material
	,werks
	,sto_loc
	,lfgja
	,lfmon
	,std_price
	,SUM(unrestricted)
	,SUM(unrestricted_amt)
	,SUM(stock_in_transfer)
    ,SUM(stock_in_transfer_amt)
	,SUM(in_quality_insp)
    ,SUM(in_quality_insp_amt)
	,SUM(restricted)
    ,SUM(restricted_amt)
	,SUM(blocked)
    ,SUM(blocked_amt)
	,SUM(returns_stock)
    ,SUM(returns_stock_amt)
	,SUM(sp_stock_value)
    ,SUM(sp_stock_value_amt)
	,SUM(st_trnsf_sp)
    ,SUM(st_trnsf_sp_amt)
FROM stock_calc_result
WHERE werks = 'SCLU' AND material LIKE '%642'
GROUP BY 1,2,3,4,5,6
ORDER BY 4,5
