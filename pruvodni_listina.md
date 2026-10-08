## 1. Cíl projektu
Vytvořit 2 tabulky k profiltrování dat a jeden hlavní soubor main k vytvoření datových podkladů k zodpovězení daných otázek.

---

## 2. Datové zdroje a jejich transformace

### Použité tabulky:
* `czechia_payroll` – Data o mzdách (filtrováno na `value_type_code = 5958` a `calculation_code = 200`).
* `czechia_payroll_industry_branch` – Číselník odvětví.
* `czechia_price` – Ceny potravin.
* `czechia_price_category` – Číselník kategorií potravin.
* `economies` & `countries` – Makroekonomické ukazatele pro evropské státy.

### Důležitá zjištění při zpracování dat:
1. **Filtrování mezd:** V databázovém prostředí byl pro průměrnou hrubou mzdu identifikován kód `5958` (místo standardního 5764) a přepočtený počet zaměstnanců (`calculation_code = 200`).
2. **Časové období:** Srovnatelné období s kompletním překryvem cen a mezd je **2006–2018**.
3. **Struktura primární tabulky:** Tabulka `t_martin_oktabec_project_sql_primary_final` byla vytvořena pomocí `UNION ALL`. Z logiky věci obsahuje řádek buď data o mzdách (sloupce cen jsou `NULL`), nebo data o cenách (sloupce mezd jsou `NULL`).
4. **Ošetření NULL v sekundární tabulce a analýze:**
   * V tabulce `economies` chybí u některých států hodnoty `gini` nebo `taxes`.
   * V 5. výzkumné otázce vrací analytická funkce `LEAD()` pro rok 2018 hodnotu `NULL`, jelikož data pro rok 2019 již nejsou k dispozici.

---

## 3. Výstupní tabulky

* `t_martin_oktabec_project_sql_primary_final` (760 řádků): Obsahuje agregovaná data mezd podle odvětví a cen podle kategorií potravin za roky 2006–2018.
* `t_martin_oktabec_project_sql_secondary_final` (945 řádků): Obsahuje HDP, Gini, populaci a daně pro evropské státy v odpovídajícím období 2006–2018.

---

## 4. Stručné výsledky výzkumných otázek

1. **Růst mezd:** Mzdy nerostou ve všech odvětvích nepřetržitě. K meziročním poklesům docházelo např. v roce 2013 (např. Peněžnictví $-8,83\,\%$) nebo v roce 2020 u Ubytování a stravování.
2. **Kupní síla (Chléb a mléko):** Za průměrnou mzdu bylo v roce 2006 možné koupit **1 312 kg chleba** a **1 465 l mléka**, zatímco v roce 2018 to bylo **1 365 kg chleba** (+53 kg) a **1 669 l mléka** (+204 l).
3. **Nejpomaleji zdražující potravina:** **Cukr krystalový** s průměrným meziročním poklesem ceny o **1,92 % ročně**.
4. **Růst cen vs. mezd (>10 %):** Neexistuje rok, kdy by ceny potravin předstihly mzdy o více než 10 procentních bodů. Nejvyšší rozdíl byl v roce 2013 (7,57 p. b. ve prospěch cen).
5. **Vliv HDP:** Výrazné změny HDP se na růstu mezd projevují se zpožděním **1 roku**. Ceny potravin reagují pružněji (např. v roce 2009 při propadu HDP ihned klesly o $6,59\,\%$).