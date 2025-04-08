SELECT
	c.tco_financial_plan
	,c.tco_financial_planname
	,d.tco_capabilityownername
	,c.tco_asset_item_number
	,c.tco_description
	,c.tco_app_reletedname
	,c.tco_cost_center
	,c.tco_cost_centername
	,d.tco_function
FROM 
    dbo.tco_assets c
LEFT JOIN dbo.tco_cost_center d ON c.tco_cost_center = d.tco_cost_centerid AND c.tco_financial_planname = d.tco_financial_planname
WHERE
	c.tco_financial_planname = (SELECT MAX(tco_financial_plan_nm) FROM dbo.tco_financial_plan)
	AND d.tco_function IS NOT NULL
GROUP BY
	c.tco_financial_plan
	,c.tco_financial_planname
	,d.tco_capabilityownername
	,c.tco_asset_item_number
	,c.tco_description
	,c.tco_app_reletedname
	,c.tco_cost_center
	,c.tco_cost_centername
	,d.tco_function
	,c.tco_application



