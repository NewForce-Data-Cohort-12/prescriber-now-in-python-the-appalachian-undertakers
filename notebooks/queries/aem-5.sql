-- 5. Top prescribers
	-- a. Where are the top 10 opioid prescribers located?
		-- query:
			/* SELECT CONCAT_WS(' ', provider_first_name, provider_last_name_or_org) AS provider
				,  total_claim_count_across_all_opioid_drugs
				,  provider_city AS city
				,  'TN' AS state
				,  'US' AS country
			FROM top_10_osp; */
		-- result:
			/* provider			total_claim_count_across_all_opioid_drugs	city				state	country
			"DAVID COFFEY"		9275										"ONEIDA"			"TN"	"US"
			"JUSTIN KINDRICK"	8405										"CROSSVILLE"		"TN"	"US"
			"SHARON CATHERS"	7274										"KNOXVILLE"			"TN"	"US"
			"MICHELLE PAINTER"	5709										"BRISTOL"			"TN"	"US"
			"RICHARD CLARK"		5607										"JAMESTOWN"			"TN"	"US"
			"JAMES LADSON"		5423										"MURFREESBORO"		"TN"	"US"
			"DWIGHT WILLETT"	5221										"KINGSTON"			"TN"	"US"
			"ALICIA TAYLOR"		5088										"LA FOLLETTE"		"TN"	"US"
			"JENNIFER GREEN"	4979										"KNOXVILLE"			"TN"	"US"
			"AMY BOWSER"		4979										"GALLATIN"			"TN"	"US" */
	-- b. Who is the top prescriber in each county?
		-- query: SELECT * FROM total_osbp_ranked_per_county WHERE rank = 1;
	-- c. What proportion of opioids are prescribed by the top 10 prescribers? Top 50? Top 100?
		-- query:
			/*	, n AS
				(SELECT SUM(top_10_osp.total_claim_count_across_all_opioid_drugs) AS top_10_sum_total_claim_count
				FROM top_10_osp)
				, d AS
				(SELECT SUM(total_opioid_scripts_by_provider.total_claim_count_across_all_opioid_drugs) AS sum_total_claim_count
				FROM total_opioid_scripts_by_provider)
				, p AS (SELECT * FROM n CROSS JOIN d)
				SELECT ROUND(top_10_sum_total_claim_count * 100 / sum_total_claim_count, 2) || '%'
					AS percent_of_prescriptions_from_top_10_prescribers FROM p; */

WITH opioid_scripts AS (
	SELECT npi
		,  drug_name
		,  total_claim_count
	FROM prescription
	JOIN drug -- inner join so we don't include any prescription records referencing drugs for which we don't know the opioid status
	USING(drug_name)
	WHERE opioid_drug_flag = 'Y' -- only the general opioid flag is needed since all long acting opioids already declare it as well
)
, opioid_scripts_providers AS (
	SELECT opioid_scripts.*
		,  prescriber.nppes_provider_last_org_name AS provider_last_name_or_org
		,  prescriber.nppes_provider_first_name AS provider_first_name
		-- ,  prescriber.nppes_provider_street1	-- street granularity not necessary
		-- ,  prescriber.nppes_provider_street2	-- street granularity not necessary
		,  prescriber.nppes_provider_city AS provider_city
		,  prescriber.nppes_provider_zip5 AS provider_zip
		-- ,  prescriber.nppes_provider_zip4	-- zip+4 granularity not necessary
		-- ,  prescriber.nppes_provider_state	-- all records are from TN
		-- ,  prescriber.nppes_provider_country	-- all records are from US
	FROM opioid_scripts JOIN prescriber USING(npi)
)
, total_opioid_scripts_by_provider AS (
	SELECT npi
		,  string_agg(drug_name, ', ') AS drugs
		,  SUM(total_claim_count) AS total_claim_count_across_all_opioid_drugs
		,  provider_last_name_or_org
		,  provider_first_name
		,  provider_city
		,  provider_zip
	FROM opioid_scripts_providers
	GROUP BY npi, provider_last_name_or_org, provider_first_name, provider_city, provider_zip
)
, top_10_osp AS (
	SELECT * FROM total_opioid_scripts_by_provider ORDER BY total_claim_count_across_all_opioid_drugs DESC LIMIT 10
)
, total_opioid_scripts_by_provider_county AS (
	SELECT total_opioid_scripts_by_provider.*
		,  fips_county.county
	FROM total_opioid_scripts_by_provider
	JOIN zip_fips ON zip = provider_zip
	JOIN fips_county USING(fipscounty)
)
, total_osbp_ranked_per_county AS (
	SELECT ROW_NUMBER() OVER (
		PARTITION BY county ORDER BY total_claim_count_across_all_opioid_drugs DESC
	)	AS rank, *
	FROM total_opioid_scripts_by_provider_county
)
, n AS
(SELECT SUM(top_10_osp.total_claim_count_across_all_opioid_drugs) AS top_10_sum_total_claim_count
FROM top_10_osp)
, d AS
(SELECT SUM(total_opioid_scripts_by_provider.total_claim_count_across_all_opioid_drugs) AS sum_total_claim_count
FROM total_opioid_scripts_by_provider)
, p AS (SELECT * FROM n CROSS JOIN d)
SELECT ROUND(top_10_sum_total_claim_count * 100 / sum_total_claim_count, 2) || '%'
	AS percent_of_prescriptions_from_top_10_prescribers FROM p;
