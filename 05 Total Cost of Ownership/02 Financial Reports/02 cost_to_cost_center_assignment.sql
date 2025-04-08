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
	,cc.tco_capabilityowner
	,cc.tco_capabilityownername
	,cc.tco_totalassigned

	--GL ACCOUNT INFO
	,ga.tco_gl_account_id
	,ga.tco_gl_account_account_group
	,ga.tco_gl_account_account_groupname

	--COST CENTER ASSIGNMENT
	,cca.tco_assignment

	,(IIF(cca.tco_assignment IS NULL, 0, cca.tco_assignment)/100 * c.tco_cost_value) AS app_assigned_amount
	,((100-IIF(cca.tco_assignment IS NULL, 0, cca.tco_assignment))/100 * c.tco_cost_value) AS service_assigned_amount

	,IIF(cca.tco_assignment IS NULL, 0, 1) AS assignment_complete

FROM 
	tco_cost c
	LEFT JOIN tco_cost_center cc ON c.tco_cost_cost_center = cc.tco_cost_centerid AND c.tco_cost_financial_plan = cc.tco_financial_plan
	INNER JOIN tco_gl_account ga ON c.tco_cost_gl_account = ga.tco_gl_accountid AND c.tco_cost_financial_plan = ga.tco_financial_plan AND ga.tco_todisplay = '1' 
	LEFT JOIN tco_cost_center_allocation cca ON c.tco_cost_cost_center = cca.tco_cost_center_allocation_cost_center AND c.tco_cost_gl_account = cca.tco_cost_center_allocation_gl_account AND UPPER(c.tco_stringmonth) = UPPER(cca.tco_monthname) AND c.tco_cost_financial_plan = cca.tco_cost_center_allocation_financial_plan
WHERE
	c.tco_cost_financial_planname = (SELECT MAX(tco_financial_plan_nm) FROM dbo.tco_financial_plan)


