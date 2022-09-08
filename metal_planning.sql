WITH cur_date AS (
/* table to get current date
 * where-used list:
 * 	- materials 
 * */
SELECT 
	getdate() AS today_date
	,DATE(today_date) AS cur_date
	,MONTH(cur_date) AS cur_month
	,YEAR(cur_date) AS cur_year
),

materials AS (
/*  table to get materials from material group 11006
 * where-used list:
 * 	- material_details
 * */
SELECT 
	mara.matnr AS mat_id
FROM 
	DW_STAGING.SAP_EUBEV.mara 
WHERE 
	mara.matkl = '11006' 
), 

material_details AS (
/* table to get details from materials list in materials temp table
 * where-used list:
 * 	- stock_aging_pos 
 * */
SELECT
	mseg.matnr AS material
	,mseg.bwart AS mov_type
	,mseg.bukrs AS comp_code
	,mseg.werks AS plant
	,mseg.lgort AS sto_loc
	,mseg.shkzg AS deb_cre
	,IFF(deb_cre = 'H', mseg.dmbtr, 0) AS amount_in
	,IFF(deb_cre = 'H', mseg.menge, 0) AS quantity_in
	,IFF(deb_cre = 'S', mseg.dmbtr, 0) AS amount_out
	,IFF(deb_cre = 'S', mseg.menge, 0) AS quantity_out
	,mseg.meins AS base_unit
	,mkpf.mblnr AS document
	,TRY_TO_DATE(mkpf.budat, 'YYYYMMDD') AS posting_date
	,LAST_DAY(posting_date) AS last_day	
	,mkpf.mjahr AS doc_year
	,month(last_day) AS doc_month
	,DATEDIFF(day, posting_date, cur_date.cur_date) AS aging
	,IFF(aging>=0 AND aging<=30, '000-030'
	,IFF(aging>=31 AND aging<=60, '031-060'
	,IFF(aging>=61 AND aging<=90, '061-090'
	,IFF(aging>=91 AND aging<=120, '091-120'
	,IFF(aging>=121 AND aging<=180, '121-180' 
	,IFF(aging>=181 AND aging<=360, '181-360' 
	,IFF(aging>=361 AND aging<=720, '361-720' 
	,IFF(aging>720, '720+', '')))))))) AS aging_group
FROM
	cur_date, DW_STAGING.SAP_EUBEV.mseg 
	INNER JOIN DW_STAGING.SAP_EUBEV.mkpf 
		ON  mseg.mblnr = mkpf.mblnr 
		AND mseg.mjahr = mkpf.mjahr
	INNER JOIN materials 
		ON mseg.matnr = materials.mat_id
	WHERE 
		doc_year = cur_date.cur_year
		AND doc_month = cur_date.cur_month
		
)

SELECT
    comp_code
    ,plant
    ,material
    ,doc_year
    ,doc_month
    ,quantity_in
    ,Quantity_out
FROM
	material_details
	WHERE 
		material = '000000000200001702'
		AND plant = 'RSBL'