#inspired by Rally-Export-FieldDefinitions (https://github.com/markwilliams970/Rally-Export-FieldDefinitions)
require 'rally_api'
require 'csv'

$file_encoding                                 = 'UTF-8'

my_vars= File.dirname(__FILE__) + "/my_vars.rb"
if FileTest.exist?( my_vars ) then require my_vars end

begin    
    # Connect to Rally --------------------------------------------------
    config                                     = {:base_url => "#{$rally_url}/slm"}
    config[:username]                          = $rally_username
    config[:password]                          = $rally_password
    config[:api_key]                           = $rally_api_key
    config[:workspace]                         = $rally_workspace
    config[:version]                           = $wsapi_version

    puts "Connecting to Rally:"
    puts "\t  :base_url : #{config[:base_url]}"
    puts "\t  :username : #{config[:username]}" 
    if  !config[:api_key].nil? && !config[:api_key].empty?
        hidden_apikey = config[:api_key][0..4] + config[:api_key][5..-5].gsub(/./,'.') + config[:api_key][-4,4]
        puts "\t  :api_key  : #{hidden_apikey}"
    end
    puts "\t  :workspace: #{config[:workspace]}"
    puts "\t  :version  : #{config[:version]}"

    begin
        @rally = RallyAPI::RallyRestJson.new(config)
        puts "Connected:"
        puts "\tSubscription: #{@rally.rally_default_workspace.rally_object['Subscription']['_refObjectName']}"
        puts "\tWorkspace   : #{@rally.rally_workspace_name}"
    rescue Exception => ex
        puts "ERROR: #{ex.message}"
        puts "       Cannot connect to Rally"
        raise "       Problem connecting to Rally at: '#{config[:base_url]}'"
    end

    # Connected to Rally --------------------------------------------------
    
    artifact_types = $artifact_types

    $output_fields = %w{Workspace ArtifactType TypeDefOID AttrDefOID AttrDefName AttrDefType Hidden Required Custom AttrCreatedOn Occurrences OccurrenceLastModified AllowedValues}
    
    puts "Summarizing field definitions..."

    summary_csv = CSV.open($output_filename, "wb", {:col_sep => $delim, :encoding => $file_encoding})
    summary_csv << $output_fields

    artifact_types.each do | this_type |
        puts "\tProcessing artifact type: #{this_type}"

        typedef_query                          = RallyAPI::RallyQuery.new()
        typedef_query.type                     = :typedefinition
        typedef_query.workspace                = @rally.rally_default_workspace
        typedef_query.query_string             = "(ElementName = \"#{this_type}\")"

        type_definitions                       = @rally.find(typedef_query)
        field_hash                             = {}

        type_definitions.each do | this_typedef |
            this_typedef.read
            this_typedef_objectid              = this_typedef["ObjectID"]
            this_typedef_name                  = this_typedef["Name"]
            attribute_defs                     = this_typedef["Attributes"]
            
            type_has_revision_date = attribute_defs.any? { |attribute| attribute["ElementName"] == "LastUpdateDate" }
            
            attribute_defs.each do | this_attribute_def |

                this_attribute_def_workspace   = this_typedef["Workspace"]
                this_attribute_def_objectid    = this_attribute_def["ObjectID"]
                this_attribute_def_name        = this_attribute_def["Name"]
                this_attribute_def_type        = this_attribute_def["AttributeType"]
                this_attribute_def_hidden      = this_attribute_def["Hidden"]
                this_attribute_def_required    = this_attribute_def["Required"]
                this_attribute_def_iscustom    = this_attribute_def["Custom"]
                this_attribute_def_createdon   = this_attribute_def["CreationDate"]
                
                #skip if mode does not include this attribute
                next if $mode == :custom_only && !this_attribute_def_iscustom
                next if $mode == :standard_only && this_attribute_def_iscustom
                
                allowed_values = []

                this_attribute_def_type = this_attribute_def['RealAttributeType']

                this_attribute_def['AllowedValues'].each do | attribute_def_value |

                    this_value = attribute_def_value['StringValue']
                    allowed_values.push(this_value) unless this_value.eql?("")
                end

                field_hash[this_attribute_def['ElementName']] = {
                    "type" => this_attribute_def_type,
                    "allowed" => allowed_values
                }
            
                #Owner, Created By, Submitted By standard user fields are being returned as OBJECT, not User
                #for output purposes, there is no need to include Users for allowed values
                if this_attribute_def_type == "USER" or (this_attribute_def_type == "OBJECT" && ["Submitted By", "Created By", "Owner"].include?(this_attribute_def_name)) then
                    this_attribute_def_type = "USER"
                end
                
                # No need to include users as allowed values
                allowed_values_string = this_attribute_def_type == "USER" ? "<Valid Users>" : allowed_values.to_s.gsub("\"","").gsub(/\\"/,'""')
                                
                occurrences_count = ""
                occurrence_last_modified = ""
                
                #retrieve occurrences for custom fields
                #exclude readonly, non-filterable fields
                #also exclude booleans, since they are never null
                if this_attribute_def_iscustom && this_attribute_def["Filterable"] && !this_attribute_def["ReadOnly"] && this_attribute_def_type != "BOOLEAN" then

                    puts "Getting occurrences for #{this_type}.#{this_attribute_def['ElementName']}..."
                    
                    #need to account for types that do not have a "LastUpdateDate" for demonstrating the last time a record was modified with an occurrence
                    #if the field doesn't exist, use the CreationDate
                    occurrence_date_field = type_has_revision_date ? "LastUpdateDate" : "CreationDate"
                    

                    occurrence_query                          = RallyAPI::RallyQuery.new()
                    occurrence_query.type                     = this_type
                    occurrence_query.workspace                = @rally.rally_default_workspace
                    occurrence_query.page_size                = 1
                    occurrence_query.limit                    = 1
                    occurrence_query.fetch                    = occurrence_date_field
                    occurrence_query.order                    = "#{occurrence_date_field} Desc" 

                    occurrence_query.query_string = this_attribute_def_type != "MULTI_VALUE" ? "(#{this_attribute_def['ElementName']} != null)" : "(#{this_attribute_def['ElementName']} !contains null)"

                    occurrences                               = @rally.find(occurrence_query)

                    occurrences_count = occurrences.total_results

                    if occurrences_count > 0 then
                        last_occurrence = occurrences[0]
                        
                        #if we can't use LastUpdateDate, then we can't report on last modified occurrence
                        if type_has_revision_date then
                            occurrence_last_modified = last_occurrence.LastUpdateDate
                        end
                        
                        puts "#{this_type}.#{this_attribute_def['ElementName']} - Occurrences: #{occurrences_count}; Last Modified Occurrence: #{last_occurrence} on #{occurrence_last_modified}"
                    end
                end
                    
                if this_type == "HierarchicalRequirement" then
                    this_type = "UserStory"
                end
                    
                output_record              = []
                output_record              << this_attribute_def_workspace
                output_record              << this_type
                output_record              << this_typedef_objectid
                output_record              << this_attribute_def_objectid
                output_record              << this_attribute_def_name
                output_record              << this_attribute_def['RealAttributeType']
                output_record              << this_attribute_def_hidden
                output_record              << this_attribute_def_required
                output_record              << this_attribute_def_iscustom
                output_record              << this_attribute_def_createdon

                output_record              << occurrences_count
                output_record              << occurrence_last_modified
                output_record              << allowed_values_string

                summary_csv << output_record
            end #} of 'attribute_defs.each do | this_attribute_def |'
        end #} of 'type_definitions.each do | this_typedef |'
    end #} of 'artifact_types.each do | this_type |'

    puts "Output file: '#{$output_filename}'"
    puts "Done!"

end