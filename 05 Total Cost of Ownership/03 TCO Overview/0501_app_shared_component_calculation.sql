SELECT
	CONCAT(c.tco_financial_planname, 'shared', c.tco_shared_component_typename, c.tco_buregionname) AS pk
	,c.tco_financial_plan
	--,c.tco_financial_planname
	,c.tco_capabilityownername
	,c.tco_shared_component_typename
	,c.tco_buregionname
	--,ROUND(SUM(c.sum_app_assignment) * c.tco_shared_buregion_assignment, 2) AS total_sum_app_assignment
	,(SUM(c.sum_app_assignment) * c.tco_shared_buregion_assignment) AS total_sum_app_assignment
FROM (
SELECT
	b.tco_financial_plan
	,b.tco_financial_planname
	,b.tco_capabilityownername
	,b.tco_application_name
	,b.tco_shared_component_typename
	,bua.tco_buregionname
	,(sbua.tco_assignment / 100) AS tco_shared_buregion_assignment
	,SUM(b.app_assignment) AS sum_app_assignment
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

	--APPLICATION ASSIGNMENT
	,(IIF(aa.tco_assignment IS NULL, 0, aa.tco_assignment)/100 * (IIF(cca.tco_assignment IS NULL, 0, cca.tco_assignment)/100 * c.tco_cost_value)) AS app_assignment
	
FROM tco_cost c
	LEFT JOIN tco_gl_account ga ON c.tco_cost_gl_account = ga.tco_gl_accountid AND c.tco_cost_financial_plan = ga.tco_financial_plan 
	LEFT JOIN tco_cost_center_allocation cca ON c.tco_cost_cost_center = cca.tco_cost_center_allocation_cost_center AND c.tco_cost_gl_account = cca.tco_cost_center_allocation_gl_account AND UPPER(c.tco_stringmonth) = UPPER(cca.tco_monthname) AND c.tco_cost_financial_plan = cca.tco_cost_center_allocation_financial_plan
	LEFT JOIN tco_application_assignment aa ON c.tco_cost_cost_center = aa.tco_cost_center AND c.tco_cost_gl_account = aa.tco_gl_account AND UPPER(c.tco_stringmonth) = UPPER(aa.tco_monthname) AND c.tco_cost_financial_plan = aa.tco_financial_plan
	LEFT JOIN tco_application a ON aa.tco_application = a.tco_applicationid AND aa.tco_financial_plan = a.tco_financial_plan
	LEFT JOIN tco_shared_component_assignment sha ON a.tco_shared_component_typename = sha.tco_shared_component_typename AND sha.tco_assignment_type = 'bu-region'
WHERE
	a.statuscodename = 'Active'
	AND ga.tco_todisplay = 1
	AND c.tco_cost_financial_planname = (SELECT MAX(tco_financial_plan_nm) FROM dbo.tco_financial_plan)

UNION ALL

SELECT 
	--APPLICATION INFO
	a.tco_applicationid
	,a.tco_application_name
	,a.tco_financial_plan
	,a.tco_financial_planname
	,a.tco_capabilityowner
	,a.tco_capabilityownername
	,sha.tco_shared_component_type
	,sha.tco_shared_component_typename

	--APPLICATION ASSIGNMENT
	,(IIF(aa.tco_assignment IS NULL, 0, aa.tco_assignment)/100 * (IIF(cca.tco_assignment IS NULL, 0, cca.tco_assignment)/100 * c.tco_cost_value)) AS app_assignment
	
FROM tco_cost c
	LEFT JOIN tco_gl_account ga ON c.tco_cost_gl_account = ga.tco_gl_accountid AND c.tco_cost_financial_plan = ga.tco_financial_plan 
	LEFT JOIN tco_cost_center_allocation cca ON c.tco_cost_cost_center = cca.tco_cost_center_allocation_cost_center AND c.tco_cost_gl_account = cca.tco_cost_center_allocation_gl_account AND UPPER(c.tco_stringmonth) = UPPER(cca.tco_monthname) AND c.tco_cost_financial_plan = cca.tco_cost_center_allocation_financial_plan
	LEFT JOIN tco_application_assignment aa ON c.tco_cost_cost_center = aa.tco_cost_center AND c.tco_cost_gl_account = aa.tco_gl_account AND UPPER(c.tco_stringmonth) = UPPER(aa.tco_monthname) AND c.tco_cost_financial_plan = aa.tco_financial_plan
	LEFT JOIN tco_application a ON aa.tco_application = a.tco_applicationid AND aa.tco_financial_plan = a.tco_financial_plan
	LEFT JOIN tco_shared_component_app_assignment shaapp ON a.tco_applicationid = shaapp.tco_application
	LEFT JOIN tco_shared_component_assignment sha ON shaapp.tco_shared_component_assignmentname = sha.tco_name AND shaapp.tco_financial_plan = sha.tco_financial_plan
WHERE
	a.statuscodename = 'Active'
	AND ga.tco_todisplay = 1
) b
	LEFT JOIN tco_application_buregion_assign bua ON bua.tco_application = b.tco_applicationid AND bua.tco_financial_plan = b.tco_financial_plan
	LEFT JOIN tco_shared_component_buregion_assignment sbua ON bua.tco_buregionname = sbua.tco_buregionname AND sbua.tco_financial_plan = b.tco_financial_plan
GROUP BY 
	b.tco_financial_plan
	,b.tco_financial_planname
	,b.tco_capabilityownername
	,b.tco_application_name
	,b.tco_shared_component_typename
	,bua.tco_buregionname
	,sbua.tco_assignment
) c
WHERE
	c.tco_financial_planname = (SELECT MAX(tco_financial_plan_nm) FROM dbo.tco_financial_plan)
GROUP BY
	c.tco_financial_plan
	,c.tco_financial_planname
	,c.tco_capabilityownername
	,c.tco_shared_component_typename
	,c.tco_buregionname
	,c.tco_shared_buregion_assignment
