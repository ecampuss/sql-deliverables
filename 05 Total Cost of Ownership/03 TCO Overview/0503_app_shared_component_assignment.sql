SELECT
	CONCAT(a.tco_financial_planname, 'shared', sha.tco_shared_component_typename, b.tco_business_unit_region_name) AS pk
	,a.tco_financial_plan
	,ao.tco_capabilityownername
	,ao.tco_function
	,a.tco_applicationname AS tco_application_name
	,'shared' AS tco_cost_type
	,sha.tco_shared_component_typename
	,ao.tco_buregionname
	,(ao.tco_assignment / 100) AS tco_shared_component_buregion_assignment_perc
	,a.tco_dolassigned AS tco_shared_component_app_assignment_amt
	,ROUND((a.tco_dolassigned * (ao.tco_assignment / 100)),2) AS tco_total_shared_component_app_buregion_assignment_amt
FROM tco_shared_component_app_assignment a
	CROSS JOIN tco_business_unit_region b
	INNER JOIN tco_shared_component_assignment sha ON a.tco_shared_component_assignmentname = sha.tco_name AND a.tco_financial_plan = sha.tco_financial_plan
	LEFT JOIN tco_shared_component_buregion_assignment bu ON b.tco_business_unit_region_name = bu.tco_buregionname
	LEFT JOIN tco_shared_component_type sc ON sha.tco_shared_component_typename = sc.tco_description
	LEFT JOIN (
SELECT DISTINCT
	app.tco_financial_planname
	,app.tco_application_name
	,app.tco_capabilityownername
	,cc.tco_function
	,b.tco_buregionname
	,b.tco_assignment
FROM
	dbo.tco_application app
	LEFT JOIN tco_application_assignment aa ON aa.tco_applicationname = app.tco_application_name AND app.tco_financial_plan = aa.tco_financial_plan
    LEFT JOIN tco_cost_center cc ON aa.tco_cost_center = cc.tco_cost_centerid AND aa.tco_financial_plan = cc.tco_financial_plan
    LEFT JOIN tco_application_buregion_assign b ON b.tco_application = app.tco_applicationid AND b.tco_financial_plan = app.tco_financial_plan             
) ao ON a.tco_applicationname = ao.tco_application_name AND a.tco_financial_planname = ao.tco_financial_planname AND b.tco_business_unit_region_name = ao.tco_buregionname
WHERE
	a.tco_financial_planname = (SELECT MAX(tco_financial_plan_nm) FROM dbo.tco_financial_plan)
