WITH current_date AS (
/* table to get current date
 * where-used list:
 * 	- materials 
 * */
SELECT 
	getdate() AS today_date,
	DATE(today_date) AS cur_date
),

previous_month AS (
/* table to get previous month data based on current date
 * where-used list:
 * 	- NOT BEING USED YET 
 * */
SELECT 
	month_number
	,year_number 
	,CONCAT(month_number,'-',year_number) AS month_year_number
FROM 
	DW_PROD.MART.DIM_DATE, current_date
WHERE 
	CASE 
		WHEN MONTH(current_date.cur_date) = 1 
		THEN month_number = month(current_date.cur_date)-1 AND year_number = year(current_date.cur_date)-1 
		ELSE month_number = month(current_date.cur_date)-1 AND year_number = year(current_date.cur_date)
	END 
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
	,DATEDIFF(day, posting_date, current_date.cur_date) AS aging
	,IFF(aging>=0 AND aging<=30, '000-030'
	,IFF(aging>=31 AND aging<=60, '031-060'
	,IFF(aging>=61 AND aging<=90, '061-090'
	,IFF(aging>=91 AND aging<=120, '091-120'
	,IFF(aging>=121 AND aging<=180, '121-180' 
	,IFF(aging>=181 AND aging<=360, '181-360' 
	,IFF(aging>=361 AND aging<=720, '361-720' 
	,IFF(aging>720, '720+', '')))))))) AS aging_group
FROM
	current_date, DW_STAGING.SAP_EUBEV.mseg 
	INNER JOIN DW_STAGING.SAP_EUBEV.mkpf 
		ON  mseg.mblnr = mkpf.mblnr 
		AND mseg.mjahr = mkpf.mjahr 
		/* AND mkpf.mjahr LIKE '2022%' */
	INNER JOIN materials 
		ON mseg.matnr = materials.mat_id
), 

stock_aging_pos AS (
/* table to get stock position base on aging groups 
 * where-used list:
 * 	- main
 * */
SELECT  
	comp_code
	,plant
	,material
	,aging_group
	,SUM(amount_in) + SUM(amount_out) AS aging_stock
FROM 
	material_details
GROUP BY 1, 2, 3, 4
ORDER BY 1 ASC, 2 ASC, 3 ASC, 4 DESC
)

SELECT
	comp_code
	,plant
	,material
	,aging_group
	,aging_stock
	,IFNULL(lag(aging_stock) OVER (ORDER BY 1 ASC, 2 ASC, 3 ASC, 4 DESC), 0) AS new_actual_stock /*function to get value from previous row*/ 
	,aging_stock - new_actual_stock AS stock_actual_position
FROM 
	stock_aging_pos
ORDER BY 1 ASC, 2 ASC, 3 ASC, 4 DESC