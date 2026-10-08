CREATE TABLE t_martin_oktabec_project_sql_primary_final AS
SELECT 
    cp.payroll_year AS rok,
    cp.industry_branch_code,
    cpib.name AS odvetvi_nazev,
    ROUND(AVG(cp.value)::numeric, 2) AS prumerna_mzda,
    NULL::bigint AS category_code,
    NULL::varchar AS potravina_nazev,
    NULL::numeric AS prumerna_cena,
    NULL::numeric AS price_value,
    NULL::varchar AS price_unit
FROM czechia_payroll cp
JOIN czechia_payroll_industry_branch cpib
    ON cp.industry_branch_code = cpib.code
WHERE cp.value_type_code = 5958     -- Použijeme správný kód pro mzdu!
  AND cp.calculation_code = 200     -- Přepočtený počet zaměstnanců
  AND cp.industry_branch_code IS NOT NULL
GROUP BY cp.payroll_year, cp.industry_branch_code, cpib.name

UNION ALL

SELECT 
    EXTRACT(YEAR FROM cpr.date_from) AS rok,
    NULL AS industry_branch_code,
    NULL AS odvetvi_nazev,
    NULL AS prumerna_mzda,
    cpr.category_code::bigint,
    cpc.name AS potravina_nazev,
    ROUND(AVG(cpr.value)::numeric, 2) AS prumerna_cena,
    cpc.price_value::numeric,
    cpc.price_unit
FROM czechia_price cpr
JOIN czechia_price_category cpc
    ON cpr.category_code = cpc.code
GROUP BY EXTRACT(YEAR FROM cpr.date_from), cpr.category_code, cpc.name, cpc.price_value, cpc.price_unit;