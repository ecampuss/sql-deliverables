SELECT DISTINCT
	f.tco_financial_plan
    ,f.tco_applicationid
    ,f.tco_application_name
	,f.tco_application_id
	,f.tco_capabilityownername
	,f.tco_ownername
	,cc.tco_function
	,f.assigned_cost_center_count
	,f.cost_center_count
    ,IIF(
		(f.assigned_cost_center_count = f.cost_center_count) 
		AND (f.total_assignment IS NOT NULL)
	, 1, 0) AS assignment_check
	,f.app_assignment_count
FROM (
SELECT
	c.tco_financial_plan
    ,c.tco_applicationid
    ,c.tco_application_name
	,c.tco_application_id
    ,b.total_assignment
	,c.statuscodename
	,c.tco_capabilityownername
	,c.tco_ownername
	,a.tco_cost_center
	,(SELECT COUNT(DISTINCT tco_cost_center) FROM dbo.tco_application_assignment e WHERE e.tco_application = a.tco_application AND c.tco_financial_planname = (SELECT MAX(tco_financial_plan_nm) FROM dbo.tco_financial_plan)) AS assigned_cost_center_count
	,(SELECT COUNT(tco_cost_centerid) FROM dbo.tco_cost_center d WHERE c.tco_capabilityownername = d.tco_capabilityownername AND d.tco_financial_planname = (SELECT MAX(tco_financial_plan_nm) FROM dbo.tco_financial_plan)) AS cost_center_count
	,COUNT(DISTINCT c.tco_applicationid) AS app_assignment_count
FROM 
    dbo.tco_application_assignment a
RIGHT JOIN tco_application c ON a.tco_application = c.tco_applicationid AND a.tco_financial_plan = c.tco_financial_plan
LEFT JOIN (
SELECT 
        tco_application
		,tco_financial_plan
		,tco_financial_planname
        ,SUM(tco_assignment) AS total_assignment
    FROM 
        dbo.tco_application_assignment
	WHERE
		tco_financial_planname = (SELECT MAX(tco_financial_plan_nm) FROM dbo.tco_financial_plan)
GROUP BY 
        tco_application
		,tco_financial_plan
		,tco_financial_planname
) b ON a.tco_application = b.tco_application AND a.tco_financial_plan = b.tco_financial_plan
WHERE
	c.statuscodename = 'Active'
	AND c.tco_financial_planname = (SELECT MAX(tco_financial_plan_nm) FROM dbo.tco_financial_plan)
GROUP BY 
	c.tco_financial_plan
	,c.tco_financial_planname
	,c.tco_applicationid
    ,c.tco_application_name
	,c.tco_application_id
    ,b.total_assignment
	,c.statuscodename
	,c.tco_capabilityownername
	,c.tco_ownername
	,a.tco_cost_center
	,a.tco_application
	) f
LEFT JOIN (
SELECT DISTINCT 
		tco_capabilityownername
		,tco_function 
	FROM 
		tco_cost_center 
	WHERE 
		tco_financial_planname = (SELECT MAX(tco_financial_plan_nm) FROM dbo.tco_financial_plan)
) cc ON f.tco_capabilityownername = cc.tco_capabilityownername
WHERE
	cc.tco_function IS NOT NULL


