SELECT
	c.tco_financial_plan
    ,c.tco_applicationid
    ,c.tco_application_name
	,c.tco_capabilityownername
	,c.tco_ownerstring
	,cc.tco_function
    ,b.total_assignment
    ,IIF(ROUND(b.total_assignment,0) = 100, 1, 0) AS assignment_check
	,COUNT(DISTINCT c.tco_applicationid) AS appburegion_count
FROM 
    dbo.tco_application_buregion_assign a
RIGHT JOIN dbo.tco_application c ON a.tco_application = c.tco_applicationid AND a.tco_financial_plan = c.tco_financial_plan
LEFT JOIN (
	SELECT DISTINCT 
		tco_capabilityownername
		,tco_function 
	FROM 
		tco_cost_center 
	WHERE 
		tco_financial_planname = (SELECT MAX(tco_financial_plan_nm) FROM dbo.tco_financial_plan)
) cc ON c.tco_capabilityownername = cc.tco_capabilityownername
LEFT JOIN (
    SELECT 
        tco_application
		,tco_financial_plan
        ,SUM(tco_assignment) AS total_assignment
    FROM 
        dbo.tco_application_buregion_assign
    GROUP BY 
        tco_application
		,tco_financial_plan
) b ON a.tco_application = b.tco_application AND a.tco_financial_plan = b.tco_financial_plan
WHERE
	c.statuscodename = 'Active'
	AND c.tco_financial_planname = (SELECT MAX(tco_financial_plan_nm) FROM dbo.tco_financial_plan)
GROUP BY 
	c.tco_financial_plan
	,c.tco_applicationid
    ,c.tco_application_name
	,c.tco_capabilityownername
	,c.tco_ownerstring
	,cc.tco_function
    ,b.total_assignment