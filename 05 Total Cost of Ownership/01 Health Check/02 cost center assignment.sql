SELECT
	c.tco_financial_plan,
	c.tco_cost_centerid,
	c.tco_cost_center_id,
	c.tco_cost_center_nm,
	c.tco_capabilityownername,
	c.tco_function,
    b.total_assignment,
	IIF(b.total_assignment IS NOT NULL, 1, 0) AS assignment_check
	,COUNT(DISTINCT c.tco_cost_centerid) AS cc_alloc_count
FROM 
	dbo.tco_cost_center_allocation a
RIGHT JOIN dbo.tco_cost_center c ON a.tco_cost_center_allocation_cost_center = c.tco_cost_centerid AND a.tco_cost_center_allocation_financial_plan = c.tco_financial_plan
LEFT JOIN(
    SELECT 
        tco_cost_center_allocation_cost_center,
		tco_cost_center_allocation_financial_plan,
        SUM(tco_assignment) AS total_assignment
    FROM 
        dbo.tco_cost_center_allocation
    GROUP BY 
        tco_cost_center_allocation_cost_center,
		tco_cost_center_allocation_financial_plan
) b ON a.tco_cost_center_allocation_cost_center = b.tco_cost_center_allocation_cost_center AND a.tco_cost_center_allocation_financial_plan = b.tco_cost_center_allocation_financial_plan
WHERE
	c.tco_financial_planname = (SELECT MAX(tco_financial_plan_nm) FROM dbo.tco_financial_plan)	
GROUP BY 
	c.tco_financial_plan,
	c.tco_cost_centerid,
	c.tco_cost_center_id,
	c.tco_cost_center_nm,
	c.tco_capabilityownername,
	c.tco_function,
    b.total_assignment