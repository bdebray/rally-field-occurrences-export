# Agile Central: Field Occurrences Export

This script will retrieve the fields defined for a provided set of types and export to a .csv file. The data export includes field definitions such as creation date, visibility, type and allowed values (if applicable). 

Exported data will also include occurrence data, such as the number of records with a value for the field and the latest date that a record with the field populated was updated. Occurrence data will be included for Custom fields only.

## Getting Started

### Prerequisites

Ensure ruby is installed. The script requires the following gems:

* [csv](https://rubygems.org/gems/csv)
* [rally_api](https://rubygems.org/gems/rally_api)

### Installing & Running

1. Download or clone this repository
2. Update the my_vars.rb file:
   - **username/password OR api_key** (Required): Specify a valid username and password OR an API Key with sufficient, read-only access
   - **workspace** (Required): Specify a Workspace Name
   - **delim** (Required): Allows specifying the delimiter used; default is a comma
   - **mode** (Required): Specify what types of fields to be included: `:custom_only` for custom fields, `:standard_only` for standard, non-custom fields or `:all_fields` for custom and standard. Note that field occurrence data will only be included with custom fields
   - **output_filename** (Required): Use the default provided filename or rename, if desired. Must contain the ".csv" extension
   - **artifact_types** (Required): List all work item/object types to be included in the output
3. Open terminal/console, navigate to the downloaded/cloned directory and run `ruby rally_field_occurrences.rb`

### Output

The .csv will contain the following data:

| Field/Heading          | Description                                                                                                                |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| Workspace              | Name of the workspace that contains the field definition                                                                   |
| ArtifactType           | Type for the field definition (i.e. User Story, PortfolioItem, Defect)                                                     |
| TypeDefOID             | Object ID for the type; can be used to reference in the Web Services API                                                   |
| AttrDefOID             | Object ID for the field; can be used to reference in the Web Services API                                                  |
| AttrDefName            | Display Name of the field                                                                                                  |
| AttrDefType            | Type of the field (i.e. Text, Date, Drop-Down, etc.)                                                                       |
| Hidden                 | Whether the field is hidden for the workspace (note: not project-specific)                                                 |
| Required               | Whether the field is required                                                                                              |
| Custom                 | Whether the field is custom                                                                                                |
| AttrCreatedOn          | When the field was created                                                                                                 |
| Occurrences            | How many records for the artifact type have a value for the field (custom fields only; see limitations)                    |
| OccurrenceLastModified | The last time a record for the artifact type was modified with a value for the field (custom fields only; see limitations) |
| AllowedValues          | A list of values allowed for the field; specifically, drop down and multi-value drop down fields                           |

### Known Limitations

- Any custom fields that are not queryable in the WebServices API will not include occurrence data.
- Any custom boolean fields will not include occurrence data.
- Any types that do not have a LastUpdateDate field will not include OccurrenceLastModified values for the occurrence data

### References and Recognitions

This app was inspired by the [Rally-Export-FieldDefinitions script](https://github.com/markwilliams970/Rally-Export-FieldDefinitions)