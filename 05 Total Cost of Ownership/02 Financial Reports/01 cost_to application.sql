SELECT 
	c.tco_costid
	,c.tco_cost_id
	,c.tco_cost_financial_plan
	,c.tco_cost_financial_planname
	,c.tco_cost_gl_account
	,c.tco_cost_gl_accountname
	,c.tco_cost_value
	,c.tco_stringmonth
	
	--COST CENTER INFO
	,cc.tco_cost_center_id
	,cc.tco_cost_center_nm
	,cc.tco_function
	,cc.tco_totalassigned
	,cc.tco_capabilityownername
	,cc.tco_capabilityowneryominame

	--GL ACCOUNT INFO
	,ga.tco_gl_account_id
	,ga.tco_gl_account_account_group
	,ga.tco_gl_account_account_groupname

	--COST CENTER ASSIGNMENT
	,(IIF(cca.tco_assignment IS NULL, 0, cca.tco_assignment)/100 * c.tco_cost_value) AS app_assigned_amount
	,IIF(cca.tco_assignment IS NULL, 0, 1) AS cost_center_assignment_complete
	
	--APPLICATION ASSIGNMENT
	,IIF(aa.tco_assignment IS NULL, 0, 1) AS application_assignment_complete
	,aa.tco_assignment AS application_assignment
	,(IIF(aa.tco_assignment IS NULL, 0, aa.tco_assignment)/100 * (IIF(cca.tco_assignment IS NULL, 0, cca.tco_assignment)/100 * c.tco_cost_value)) AS app_assignment
	,(IIF(aa.tco_assignment IS NULL, 0, aa.tco_assignment)/100 * c.tco_cost_value) AS app_assignment2
	,(100-IIF(aa.tco_assignment IS NULL, 0, aa.tco_assignment)/100 * (IIF(cca.tco_assignment IS NULL, 0, cca.tco_assignment)/100 * c.tco_cost_value)) AS app_unassigned

	--APPLICATION INFO
	,a.tco_applicationid
	,a.tco_application_id
	,a.tco_application_name
	,a.tco_shared_component_typename
FROM tco_cost c
	LEFT JOIN tco_cost_center cc ON c.tco_cost_cost_center = cc.tco_cost_centerid AND cc.tco_financial_planname = (SELECT MAX(tco_financial_plan_nm) FROM dbo.tco_financial_plan)
	INNER JOIN tco_gl_account ga ON c.tco_cost_gl_account = ga.tco_gl_accountid AND ga.tco_financial_planname = (SELECT MAX(tco_financial_plan_nm) FROM dbo.tco_financial_plan) AND ga.tco_todisplay = '1' 
	LEFT JOIN tco_cost_center_allocation cca ON c.tco_cost_cost_center = cca.tco_cost_center_allocation_cost_center AND c.tco_cost_gl_account = cca.tco_cost_center_allocation_gl_account AND UPPER(c.tco_stringmonth) = UPPER(cca.tco_monthname) AND cca.tco_cost_center_allocation_financial_planname = (SELECT MAX(tco_financial_plan_nm) FROM dbo.tco_financial_plan)
	LEFT JOIN tco_application_assignment aa ON c.tco_cost_cost_center = aa.tco_cost_center AND c.tco_cost_gl_account = aa.tco_gl_account AND UPPER(c.tco_stringmonth) = UPPER(aa.tco_monthname) AND aa.tco_financial_planname = (SELECT MAX(tco_financial_plan_nm) FROM dbo.tco_financial_plan)
	LEFT JOIN tco_application a ON aa.tco_application = a.tco_applicationid AND a.tco_financial_planname = (SELECT MAX(tco_financial_plan_nm) FROM dbo.tco_financial_plan)
WHERE
	a.statuscodename = 'Active'
	AND c.tco_cost_financial_planname = (SELECT MAX(tco_financial_plan_nm) FROM dbo.tco_financial_plan)
