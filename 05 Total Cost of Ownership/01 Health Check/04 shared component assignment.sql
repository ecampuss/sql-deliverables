SELECT
	g.tco_description
	,g.tco_ownername
    ,IIF(f.assignment_check IS NULL, 0, 1) AS assignment_check
	,1 AS shared_comp_count
FROM 
	tco_shared_component_type g
LEFT JOIN (
SELECT
	a.tco_description
	,a.tco_ownername
	,a.tco_shared_component_typeid
	,b.tco_financial_plan
    ,IIF(ROUND(b.total_assignment, 0) = 100, 1, 0) AS assignment_check
FROM 
	dbo.tco_shared_component_type a
LEFT JOIN (
SELECT 
	c.tco_shared_component_type
	,c.tco_financial_plan
	,c.tco_financial_planname
	,c.tco_assignment_type
	,IIF(c.tco_assignment_type = 'app'
		,(SELECT SUM(d.tco_assignment) FROM dbo.tco_shared_component_app_assignment d 
		WHERE d.tco_shared_component_assignment = c.tco_shared_component_assignmentid AND d.tco_financial_planname = c.tco_financial_planname)
		,(SELECT SUM(e.tco_assignment) FROM dbo.tco_shared_component_buregion_assignment e 
		WHERE e.tco_shared_component_assignment = c.tco_shared_component_assignmentid AND e.tco_financial_planname = c.tco_financial_planname)
	) AS total_assignment
FROM dbo.tco_shared_component_assignment c
) b ON a.tco_shared_component_typeid = b.tco_shared_component_type
WHERE
	b.tco_financial_planname = (SELECT MAX(tco_financial_plan_nm) FROM dbo.tco_financial_plan)
GROUP BY
	a.tco_description
	,a.tco_ownername
	,a.tco_shared_component_typeid
	,b.tco_financial_plan
	,b.total_assignment
) f ON f.tco_shared_component_typeid = g.tco_shared_component_typeid