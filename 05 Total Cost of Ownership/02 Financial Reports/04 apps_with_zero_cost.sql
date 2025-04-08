SELECT
	fr.tco_cost_financial_plan
	,fr.tco_cost_financial_planname
	,fr.tco_capabilityownername
	,fr.total_app_assignment
	,fr.tco_application_id
	,fr.tco_application_name
	,1 AS app_with_no_cost_count
	,fr.tco_function
FROM (
SELECT 
	r.tco_cost_financial_plan
	,r.tco_cost_financial_planname
	,r.tco_cost_center_id
	,r.tco_cost_center_nm
	,r.tco_capabilityownername
	,SUM(r.app_assignment) AS total_app_assignment
	,r.tco_application_id
	,r.tco_application_name
	,r.tco_function
FROM (
SELECT 
	c.tco_cost_financial_plan
	,c.tco_cost_financial_planname
	,c.tco_stringmonth
	
	--COST CENTER INFO
	,cc.tco_cost_center_id
	,cc.tco_cost_center_nm
	,cc.tco_capabilityownername
	,cc.tco_function
	
	--APPLICATION ASSIGNMENT
	,(IIF(aa.tco_assignment IS NULL, 0, aa.tco_assignment)/100 * (IIF(cca.tco_assignment IS NULL, 0, cca.tco_assignment)/100 * c.tco_cost_value)) AS app_assignment

	--APPLICATION INFO
	,a.tco_application_id
	,a.tco_application_name
FROM tco_cost c
	LEFT JOIN tco_cost_center cc ON c.tco_cost_cost_center = cc.tco_cost_centerid AND c.tco_cost_financial_plan = cc.tco_financial_plan
	LEFT JOIN tco_cost_center_allocation cca ON c.tco_cost_cost_center = cca.tco_cost_center_allocation_cost_center AND c.tco_cost_gl_account = cca.tco_cost_center_allocation_gl_account AND UPPER(c.tco_stringmonth) = UPPER(cca.tco_monthname) AND c.tco_cost_financial_plan = cca.tco_cost_center_allocation_financial_plan
	LEFT JOIN tco_application_assignment aa ON c.tco_cost_cost_center = aa.tco_cost_center AND c.tco_cost_gl_account = aa.tco_gl_account AND UPPER(c.tco_stringmonth) = UPPER(aa.tco_monthname) AND c.tco_cost_financial_plan = aa.tco_financial_plan
	LEFT JOIN tco_application a ON aa.tco_application = a.tco_applicationid AND c.tco_cost_financial_plan = a.tco_financial_plan
WHERE
	a.statuscodename = 'Active'
	AND c.tco_cost_financial_planname = (SELECT MAX(tco_financial_plan_nm) FROM dbo.tco_financial_plan)
) r
GROUP BY
r.tco_cost_financial_plan
	,r.tco_cost_financial_planname
	,r.tco_cost_center_id
	,r.tco_cost_center_nm
	,r.tco_capabilityownername
	,r.tco_application_id
	,r.tco_application_name
	,r.tco_function
) fr
WHERE
	fr.total_app_assignment = 0
GROUP BY
	fr.tco_cost_financial_plan
	,fr.tco_cost_financial_planname
	,fr.tco_capabilityownername
	,fr.total_app_assignment
	,fr.tco_application_id
	,fr.tco_application_name
	,fr.tco_function