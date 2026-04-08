WITH distinct_generic_drugs AS (
	SELECT DISTINCT generic_name
		,  opioid_drug_flag
		,  long_acting_opioid_drug_flag
		,  antibiotic_drug_flag
		,  antipsychotic_drug_flag
	FROM drug
)
SELECT * FROM distinct_generic_drugs;