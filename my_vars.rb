# Rally Parameters
$rally_url                   =  "https://rally1.rallydev.com"
$rally_username              =  "user@company.com"
$rally_password              =  "t0p$3cr3t"
$rally_api_key               =  nil #use instead of a username/password
$rally_workspace             =  ""
$wsapi_version               =  "v2.0"

$delim                       = ","

# Mode:
# :custom_only   -> Exports Custom Field definitions and occurrences Only
# :standard_only -> Exports Standard Field definitions Only; no occurrences
# :all_fields    -> Exports All field definitions; only occurrences for custom fields
$mode                        = :custom_only

$output_filename             = "field_definitions_export.csv"

$artifact_types              = ["Defect","HierarchicalRequirement","PortfolioItem","Task","TestCase"]
