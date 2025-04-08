SELECT
	CONCAT(b.tco_financial_planname, 'shared', sha.tco_shared_component_typename, bua.tco_buregionname) AS pk
	,b.tco_financial_plan
	,b.tco_financial_planname
	,b.tco_capabilityownername
	,b.tco_application_name
	,'shared' AS tco_cost_type
	,sha.tco_shared_component_typename
	,b.tco_function
	,bua.tco_buregionname
	,(sbua.tco_assignment / 100) AS tco_buregion_assignment
	,SUM(b.app_assignment) AS sum_app_assignment
	,ROUND( (bua.tco_assignment / 100) * SUM(b.app_assignment), 2) AS tco_total_shared_component_app_buregion_assignment_amt
FROM (
SELECT 
	--APPLICATION INFO
	a.tco_applicationid
	,a.tco_application_name
	,a.tco_financial_plan
	,a.tco_financial_planname
	,a.tco_capabilityowner
	,a.tco_capabilityownername
	,a.tco_shared_component_type
	,a.tco_shared_component_typename
	,cc.tco_function

	--APPLICATION ASSIGNMENT
	,(IIF(aa.tco_assignment IS NULL, 0, aa.tco_assignment)/100 * (IIF(cca.tco_assignment IS NULL, 0, cca.tco_assignment)/100 * c.tco_cost_value)) AS app_assignment
	
FROM tco_cost c
	LEFT JOIN tco_cost_center cc ON c.tco_cost_cost_center = cc.tco_cost_centerid AND c.tco_cost_financial_plan = cc.tco_financial_plan
	LEFT JOIN tco_gl_account ga ON c.tco_cost_gl_account = ga.tco_gl_accountid AND c.tco_cost_financial_plan = ga.tco_financial_plan AND ga.tco_todisplay = '1' 
	LEFT JOIN tco_cost_center_allocation cca ON c.tco_cost_cost_center = cca.tco_cost_center_allocation_cost_center AND c.tco_cost_gl_account = cca.tco_cost_center_allocation_gl_account AND UPPER(c.tco_stringmonth) = UPPER(cca.tco_monthname) AND c.tco_cost_financial_plan = cca.tco_cost_center_allocation_financial_plan
	LEFT JOIN tco_application_assignment aa ON c.tco_cost_cost_center = aa.tco_cost_center AND c.tco_cost_gl_account = aa.tco_gl_account AND UPPER(c.tco_stringmonth) = UPPER(aa.tco_monthname) AND c.tco_cost_financial_plan = aa.tco_financial_plan
	LEFT JOIN tco_application a ON aa.tco_application = a.tco_applicationid AND aa.tco_financial_plan = a.tco_financial_plan
WHERE
	a.statuscodename = 'Active'
) b
	LEFT JOIN tco_application_buregion_assign bua ON bua.tco_application = b.tco_applicationid AND bua.tco_financial_plan = b.tco_financial_plan
	LEFT JOIN tco_shared_component_buregion_assignment sbua ON bua.tco_buregionname = sbua.tco_buregionname AND sbua.tco_financial_plan = b.tco_financial_plan
	LEFT JOIN tco_shared_component_assignment sha ON sbua.tco_shared_component_assignmentname = sha.tco_name
WHERE
	b.tco_financial_planname = (SELECT MAX(tco_financial_plan_nm) FROM dbo.tco_financial_plan)
GROUP BY 
	b.tco_financial_plan
	,b.tco_financial_planname
	,b.tco_capabilityownername
	,b.tco_application_name
	,sha.tco_shared_component_typename
	,b.tco_function
	,bua.tco_buregionname
	,bua.tco_assignment
	,sbua.tco_assignment

UNION ALL

SELECT
	CONCAT(r.tco_financial_planname, r.tco_cost_type, r.tco_shared_component_typename, r.tco_buregionname) AS pk
	,r.tco_financial_plan
	,r.tco_financial_planname
	,r.tco_capabilityownername
	,r.tco_application_name
	,r.tco_cost_type
	,r.tco_shared_component_typename
	,r.tco_function
	,r.tco_buregionname
	,r.tco_buregion_assignment / 100 AS tco_buregion_assignment
	,SUM(r.sum_app_assignment) AS sum_app_assignment
	,SUM(r.tco_shared_component_direct_amount) AS tco_total_shared_component_app_buregion_assignment_amt
FROM (
SELECT 
	c.tco_cost_financial_plan AS tco_financial_plan
	,c.tco_cost_financial_planname AS tco_financial_planname
	,cc.tco_capabilityownername
	,a.tco_application_name
	,'direct' AS tco_cost_type
	,'Direct' AS tco_shared_component_typename
	,cc.tco_function
	,bu.tco_buregionname
	,bu.tco_assignment AS tco_buregion_assignment
	,(IIF(aa.tco_assignment IS NULL, 0, aa.tco_assignment)/100 * (IIF(cca.tco_assignment IS NULL, 0, cca.tco_assignment)/100 * c.tco_cost_value)) AS sum_app_assignment
	,(IIF(aa.tco_assignment IS NULL, 0, aa.tco_assignment)/100 * (IIF(cca.tco_assignment IS NULL, 0, cca.tco_assignment)/100 * c.tco_cost_value)) * (bu.tco_assignment/100) AS tco_shared_component_direct_amount
FROM tco_cost c
	LEFT JOIN tco_cost_center cc ON c.tco_cost_cost_center = cc.tco_cost_centerid AND c.tco_cost_financial_plan = cc.tco_financial_plan
	LEFT JOIN tco_gl_account ga ON c.tco_cost_gl_account = ga.tco_gl_accountid AND c.tco_cost_financial_plan = ga.tco_financial_plan AND ga.tco_todisplay = '1' 
	LEFT JOIN tco_cost_center_allocation cca ON c.tco_cost_cost_center = cca.tco_cost_center_allocation_cost_center AND c.tco_cost_gl_account = cca.tco_cost_center_allocation_gl_account AND UPPER(c.tco_stringmonth) = UPPER(cca.tco_monthname) AND c.tco_cost_financial_plan = cca.tco_cost_center_allocation_financial_plan
	LEFT JOIN tco_application_assignment aa ON c.tco_cost_cost_center = aa.tco_cost_center AND c.tco_cost_gl_account = aa.tco_gl_account AND UPPER(c.tco_stringmonth) = UPPER(aa.tco_monthname) AND c.tco_cost_financial_plan = aa.tco_financial_plan
	LEFT JOIN tco_application a ON aa.tco_application = a.tco_applicationid AND c.tco_cost_financial_plan = a.tco_financial_plan
	LEFT JOIN tco_application_buregion_assign bu ON bu.tco_application = a.tco_applicationid AND bu.tco_financial_plan = a.tco_financial_plan
WHERE
	a.statuscodename = 'Active'
	AND c.tco_cost_financial_planname = (SELECT MAX(tco_financial_plan_nm) FROM dbo.tco_financial_plan)
) r
GROUP BY
	r.tco_financial_plan
	,r.tco_financial_planname
	,r.tco_capabilityownername
	,r.tco_application_name
	,r.tco_cost_type
	,r.tco_shared_component_typename
	,r.tco_function
	,r.tco_buregionname
	,r.tco_buregion_assignment
