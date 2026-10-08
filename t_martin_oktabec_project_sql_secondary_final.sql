CREATE TABLE t_martin_oktabec_project_sql_secondary_final AS
SELECT 
    e.country,
    e.year AS rok,
    e.gdp,
    e.gini,
    e.population,
    e.taxes
FROM economies e
JOIN countries c 
    ON e.country = c.country
WHERE c.continent = 'Europe'
  AND e.year BETWEEN (
      SELECT MIN(rok) FROM t_martin_oktabec_project_sql_primary_final
  ) AND (
      SELECT MAX(rok) FROM t_martin_oktabec_project_sql_primary_final
  )
ORDER BY e.country, e.year;