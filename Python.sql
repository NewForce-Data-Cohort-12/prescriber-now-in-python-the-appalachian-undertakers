SELECT 
    SUM(p.total_drug_cost) AS total_opioid_spending
FROM prescription p
JOIN drug d ON p.drug_name = d.drug_name
WHERE d.opioid_drug_flag::int = 1;  -- cast text to integer

SELECT *
FROM prescription
LIMIT 5;

SELECT SUM(p.total_drug_cost) AS total_opioid_spending
FROM prescription p
JOIN drug d ON p.drug_name = d.drug_name
WHERE d.opioid_drug_flag = 'Y';

SELECT 
    z.fipscounty,
    SUM(p.total_drug_cost) AS opioid_spending
FROM prescription p
JOIN drug d ON p.drug_name = d.drug_name
JOIN prescriber pr ON p.npi = pr.npi
JOIN zip_fips z ON pr.nppes_provider_zip5 = z.zip
WHERE d.opioid_drug_flag = 'Y'
GROUP BY z.fipscounty;

SELECT 
    d.opioid_drug_flag,
    SUM(p.total_drug_cost) AS total_spending
FROM prescription p
JOIN drug d ON p.drug_name = d.drug_name
GROUP BY d.opioid_drug_flag;

SELECT 
    c.fipscounty,
    SUM(CASE WHEN d.opioid_drug_flag = 'Y' THEN p.total_drug_cost ELSE 0 END) AS opioid_spending,
    SUM(CASE WHEN d.opioid_drug_flag = 'N' THEN p.total_drug_cost ELSE 0 END) AS nonopioid_spending,
    od.overdose_deaths
FROM prescription p
JOIN drug d ON p.drug_name = d.drug_name
JOIN cbsa c ON c.cbsa = p.npi::varchar  -- or the correct mapping you have
JOIN overdose_deaths od ON od.fipscounty::varchar = c.fipscounty
GROUP BY c.fipscounty, od.overdose_deaths
ORDER BY c.fipscounty;

SELECT * FROM prescriber LIMIT 5;




WITH county_opioid AS (
    SELECT
        zf.fipscounty,
        SUM(rx.total_drug_cost * zf.res_ratio) AS opioid_spend
    FROM prescription AS rx
    JOIN drug AS d ON rx.drug_name = d.drug_name
    JOIN prescriber AS p ON rx.npi = p.npi
    JOIN zip_fips AS zf ON p.nppes_provider_zip5 = zf.zip
    WHERE d.opioid_drug_flag = 'Y'
    GROUP BY zf.fipscounty
)
SELECT
    fc.county,
    fc.state,
    ROUND(co.opioid_spend, 2) AS opioid_spend,
    pop.population,
    ROUND(co.opioid_spend / pop.population, 2) AS opioid_spend_per_capita
FROM county_opioid AS co
JOIN fips_county AS fc ON co.fipscounty = fc.fipscounty
JOIN population AS pop ON pop.fipscounty = co.fipscounty
ORDER BY opioid_spend_per_capita DESC
LIMIT 20;

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public';

SELECT * FROM overdose_deaths LIMIT 5;

SELECT 
    fc.county,
    fc.state,
    od.overdose_deaths,
    pop.population,
    ROUND(od.overdose_deaths::numeric / pop.population, 4) AS deaths_per_capita
FROM overdose_deaths AS od
JOIN fips_county AS fc 
    ON od.fipscounty::text = fc.fipscounty   -- cast numeric to text
JOIN population AS pop 
    ON od.fipscounty::text = pop.fipscounty
WHERE od.year = 2018   -- or any year you want
ORDER BY deaths_per_capita DESC
LIMIT 1;

