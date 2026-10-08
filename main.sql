-- Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?

WITH agregovane_mzdy AS (
    SELECT 
        rok,
        odvetvi_nazev,
        ROUND(AVG(prumerna_mzda)::numeric, 2) AS prumerna_mzda
    FROM t_martin_oktabec_project_sql_primary_final
    WHERE odvetvi_nazev IS NOT NULL
      AND prumerna_mzda IS NOT NULL
    GROUP BY rok, odvetvi_nazev
),
mezirocni_srovnani AS (
    SELECT 
        rok,
        odvetvi_nazev,
        prumerna_mzda,
        LAG(prumerna_mzda) OVER (
            PARTITION BY odvetvi_nazev 
            ORDER BY rok
        ) AS predchozi_mzda
    FROM agregovane_mzdy
)
SELECT 
    rok,
    odvetvi_nazev,
    prumerna_mzda,
    predchozi_mzda,
    ROUND((prumerna_mzda - predchozi_mzda)::numeric, 2) AS pokles_kc,
    ROUND(((prumerna_mzda - predchozi_mzda) / predchozi_mzda * 100)::numeric, 2) AS pokles_procent
FROM mezirocni_srovnani
WHERE predchozi_mzda IS NOT NULL 
  AND prumerna_mzda < predchozi_mzda
ORDER BY odvetvi_nazev, rok;

-- Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?

WITH srovnatelne_roky AS (
    SELECT 
        MIN(rok) AS prvi_rok,
        MAX(rok) AS posledni_rok
    FROM t_martin_oktabec_project_sql_primary_final
    WHERE prumerna_mzda IS NOT NULL
      AND rok IN (
          SELECT DISTINCT rok 
          FROM t_martin_oktabec_project_sql_primary_final 
          WHERE prumerna_cena IS NOT NULL
      )
),
prumerna_mzda_roky AS (
    SELECT 
        rok,
        ROUND(AVG(prumerna_mzda)::numeric, 2) AS celkova_prumerna_mzda
    FROM t_martin_oktabec_project_sql_primary_final
    WHERE prumerna_mzda IS NOT NULL
      AND rok IN (SELECT prvi_rok FROM srovnatelne_roky UNION SELECT posledni_rok FROM srovnatelne_roky)
    GROUP BY rok
),
ceny_potravin AS (
    SELECT 
        rok,
        potravina_nazev,
        price_value,
        price_unit,
        ROUND(AVG(prumerna_cena)::numeric, 2) AS prumerna_cena
    FROM t_martin_oktabec_project_sql_primary_final
    WHERE potravina_nazev ILIKE '%chléb%' OR potravina_nazev ILIKE '%mléko%'
      AND rok IN (SELECT prvi_rok FROM srovnatelne_roky UNION SELECT posledni_rok FROM srovnatelne_roky)
    GROUP BY rok, potravina_nazev, price_value, price_unit
)
SELECT 
    pm.rok,
    pm.celkova_prumerna_mzda,
    cp.potravina_nazev,
    cp.prumerna_cena,
    cp.price_value,
    cp.price_unit,
    FLOOR(pm.celkova_prumerna_mzda / cp.prumerna_cena) AS kusu_za_mzdu
FROM prumerna_mzda_roky pm
JOIN ceny_potravin cp ON pm.rok = cp.rok
ORDER BY cp.potravina_nazev, pm.rok;

-- Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?

WITH rocni_ceny AS (
    SELECT 
        rok,
        potravina_nazev,
        ROUND(AVG(prumerna_cena)::numeric, 2) AS prumerna_cena
    FROM t_martin_oktabec_project_sql_primary_final
    WHERE potravina_nazev IS NOT NULL
      AND prumerna_cena IS NOT NULL
    GROUP BY rok, potravina_nazev
),
mezirocni_zmeny AS (
    SELECT 
        rok,
        potravina_nazev,
        prumerna_cena,
        LAG(prumerna_cena) OVER (
            PARTITION BY potravina_nazev 
            ORDER BY rok
        ) AS predchozi_cena
    FROM rocni_ceny
),
procentualni_zmeny AS (
    SELECT 
        potravina_nazev,
        ROUND(((prumerna_cena - predchozi_cena) / predchozi_cena * 100)::numeric, 2) AS procentualni_zmena
    FROM mezirocni_zmeny
    WHERE predchozi_cena IS NOT NULL
)
SELECT 
    potravina_nazev,
    ROUND(AVG(procentualni_zmena)::numeric, 2) AS prumerny_rocni_narust_procent
FROM procentualni_zmeny
GROUP BY potravina_nazev
ORDER BY prumerny_rocni_narust_procent ASC;

-- Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?

WITH mezirocni_mzdy AS (
    SELECT 
        rok,
        ROUND(AVG(prumerna_mzda)::numeric, 2) AS prumerna_mzda
    FROM t_martin_oktabec_project_sql_primary_final
    WHERE prumerna_mzda IS NOT NULL
    GROUP BY rok
),
procenta_mzdy AS (
    SELECT 
        rok,
        prumerna_mzda,
        LAG(prumerna_mzda) OVER (ORDER BY rok) AS predchozi_mzda,
        ROUND(((prumerna_mzda - LAG(prumerna_mzda) OVER (ORDER BY rok)) / LAG(prumerna_mzda) OVER (ORDER BY rok) * 100)::numeric, 2) AS rust_mezd_pct
    FROM mezirocni_mzdy
),
mezirocni_ceny AS (
    SELECT 
        rok,
        potravina_nazev,
        ROUND(AVG(prumerna_cena)::numeric, 2) AS prumerna_cena
    FROM t_martin_oktabec_project_sql_primary_final
    WHERE prumerna_cena IS NOT NULL
    GROUP BY rok, potravina_nazev
),
ceny_s_lagem AS (
    SELECT 
        rok,
        potravina_nazev,
        prumerna_cena,
        LAG(prumerna_cena) OVER (PARTITION BY potravina_nazev ORDER BY rok) AS predchozi_cena
    FROM mezirocni_ceny
),
procenta_ceny AS (
    SELECT 
        rok,
        ROUND(AVG((prumerna_cena - predchozi_cena) / predchozi_cena * 100)::numeric, 2) AS rust_cen_pct
    FROM ceny_s_lagem
    WHERE predchozi_cena IS NOT NULL
    GROUP BY rok
)
SELECT 
    m.rok,
    m.rust_mezd_pct,
    c.rust_cen_pct,
    ROUND((c.rust_cen_pct - m.rust_mezd_pct)::numeric, 2) AS rozdil_pct
FROM procenta_mzdy m
JOIN procenta_ceny c ON m.rok = c.rok
ORDER BY m.rok;

-- Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?

WITH gdp_cr AS (
    SELECT 
        rok,
        gdp,
        LAG(gdp) OVER (ORDER BY rok) AS predchozi_gdp,
        ROUND(((gdp - LAG(gdp) OVER (ORDER BY rok)) / LAG(gdp) OVER (ORDER BY rok) * 100)::numeric, 2) AS rust_gdp_pct
    FROM t_martin_oktabec_project_sql_secondary_final
    WHERE country = 'Czech Republic'
),
mzdy_ceny AS (
    SELECT 
        m.rok,
        m.rust_mezd_pct,
        c.rust_cen_pct
    FROM (
        SELECT 
            rok,
            ROUND(((AVG(prumerna_mzda) - LAG(AVG(prumerna_mzda)) OVER (ORDER BY rok)) / LAG(AVG(prumerna_mzda)) OVER (ORDER BY rok) * 100)::numeric, 2) AS rust_mezd_pct
        FROM t_martin_oktabec_project_sql_primary_final
        WHERE prumerna_mzda IS NOT NULL
        GROUP BY rok
    ) m
    JOIN (
        SELECT 
            rok,
            ROUND(AVG(procentualni_zmena)::numeric, 2) AS rust_cen_pct
        FROM (
            SELECT 
                rok,
                potravina_nazev,
                (AVG(prumerna_cena) - LAG(AVG(prumerna_cena)) OVER (PARTITION BY potravina_nazev ORDER BY rok)) / LAG(AVG(prumerna_cena)) OVER (PARTITION BY potravina_nazev ORDER BY rok) * 100 AS procentualni_zmena
            FROM t_martin_oktabec_project_sql_primary_final
            WHERE prumerna_cena IS NOT NULL
            GROUP BY rok, potravina_nazev
        ) sub
        WHERE procentualni_zmena IS NOT NULL
        GROUP BY rok
    ) c ON m.rok = c.rok
)
SELECT 
    g.rok,
    g.rust_gdp_pct,
    mc.rust_mezd_pct,
    mc.rust_cen_pct,
    LEAD(mc.rust_mezd_pct) OVER (ORDER BY g.rok) AS rust_mezd_nasledujici_rok,
    LEAD(mc.rust_cen_pct) OVER (ORDER BY g.rok) AS rust_cen_nasledujici_rok
FROM gdp_cr g
JOIN mzdy_ceny mc ON g.rok = mc.rok
ORDER BY g.rok;