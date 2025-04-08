SELECT
	a.tco_financial_plan
	,a.tco_capabilityownername
	,a.tco_cost_center
	,a.tco_cost_centername
	,a.tco_function
	,a.total_assignment
	,a.assets_per_costctr
	,IIF(a.assets_per_costctr = 0, 1, ROUND((CAST(a.total_assignment AS DECIMAL) / CAST(a.assets_per_costctr AS DECIMAL)),2)) AS asset_total_assignment
	,IIF(a.assets_per_costctr = 0, 1, IIF((a.total_assignment / a.assets_per_costctr) = 1, 1, 0)) AS asset_assignment_check
	,1 AS asset_count
FROM (
SELECT
	c.tco_financial_plan
	,c.tco_financial_planname
	,d.tco_capabilityownername
	,c.tco_cost_center
	,c.tco_cost_centername
	,d.tco_function
	,(SELECT COUNT(tco_asset_item_number) FROM dbo.tco_assets e 
	WHERE c.tco_cost_center = e.tco_cost_center AND c.tco_financial_plan = e.tco_financial_plan AND tco_app_releted = 1 AND tco_application IS NOT NULL AND tco_net_book_value > 1 AND e.tco_financial_planname = (SELECT MAX(tco_financial_plan_nm) FROM dbo.tco_financial_plan)) AS total_assignment
	,(SELECT COUNT(tco_asset_item_number) FROM dbo.tco_assets e 
	WHERE c.tco_cost_center = e.tco_cost_center AND c.tco_financial_plan = e.tco_financial_plan AND tco_app_releted = 1 AND tco_net_book_value > 1 AND e.tco_financial_planname = (SELECT MAX(tco_financial_plan_nm) FROM dbo.tco_financial_plan)) AS assets_per_costctr
FROM 
    dbo.tco_assets c
LEFT JOIN dbo.tco_cost_center d ON c.tco_cost_center = d.tco_cost_centerid AND c.tco_financial_planname = d.tco_financial_planname
WHERE
	c.tco_net_book_value > 1	
GROUP BY
	c.tco_financial_plan
	,c.tco_financial_planname
	,d.tco_capabilityownername
	,c.tco_cost_center
	,c.tco_cost_centername
	,d.tco_function
	,c.tco_application
) a
WHERE
	a.tco_financial_planname = (SELECT MAX(tco_financial_plan_nm) FROM dbo.tco_financial_plan)
	AND tco_function IS NOT NULL
GROUP BY
	a.tco_financial_plan
	,a.tco_capabilityownername
	,a.tco_cost_center
	,a.tco_cost_centername
	,a.tco_function
	,a.total_assignment
	,a.assets_per_costctr
