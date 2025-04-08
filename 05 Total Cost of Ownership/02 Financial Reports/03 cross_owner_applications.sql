SELECT 
	a.tco_application_id
	,a.tco_application_name
	,c.tco_cost_financial_plan
	,cc.tco_cost_center_id
	,cc.tco_cost_center_nm
	,cc.tco_capabilityownername
	,cc.tco_function
FROM tco_cost c
	LEFT JOIN tco_cost_center cc ON c.tco_cost_cost_center = cc.tco_cost_centerid AND /*c.tco_cost_financial_plan = cc.tco_financial_plan*/ cc.tco_financial_planname = (SELECT MAX(tco_financial_plan_nm) FROM dbo.tco_financial_plan)
	INNER JOIN tco_gl_account ga ON c.tco_cost_gl_account = ga.tco_gl_accountid AND /*c.tco_cost_financial_plan = ga.tco_financial_plan*/ ga.tco_financial_planname = (SELECT MAX(tco_financial_plan_nm) FROM dbo.tco_financial_plan) AND ga.tco_todisplay = '1' 
	LEFT JOIN tco_cost_center_allocation cca ON c.tco_cost_cost_center = cca.tco_cost_center_allocation_cost_center AND c.tco_cost_gl_account = cca.tco_cost_center_allocation_gl_account AND UPPER(c.tco_stringmonth) = UPPER(cca.tco_monthname) AND /*c.tco_cost_financial_plan = cca.tco_cost_center_allocation_financial_plan*/ cca.tco_cost_center_allocation_financial_planname = (SELECT MAX(tco_financial_plan_nm) FROM dbo.tco_financial_plan)
	LEFT JOIN tco_application_assignment aa ON c.tco_cost_cost_center = aa.tco_cost_center AND c.tco_cost_gl_account = aa.tco_gl_account AND UPPER(c.tco_stringmonth) = UPPER(aa.tco_monthname) AND /*c.tco_cost_financial_plan = aa.tco_financial_plan*/ aa.tco_financial_planname = (SELECT MAX(tco_financial_plan_nm) FROM dbo.tco_financial_plan)
	LEFT JOIN tco_application a ON aa.tco_application = a.tco_applicationid AND /*c.tco_cost_financial_plan = a.tco_financial_plan*/ a.tco_financial_planname = (SELECT MAX(tco_financial_plan_nm) FROM dbo.tco_financial_plan)
WHERE
	a.tco_application_id IS NOT NULL
	AND a.statuscodename = 'Active'
	AND c.tco_cost_financial_planname = (SELECT MAX(tco_financial_plan_nm) FROM dbo.tco_financial_plan)
GROUP BY
	a.tco_application_id
	,a.tco_application_name
	,c.tco_cost_financial_plan
	,cc.tco_cost_center_id
	,cc.tco_cost_center_nm
	,cc.tco_capabilityownername
	,cc.tco_function