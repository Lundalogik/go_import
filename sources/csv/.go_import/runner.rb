
require 'go_import'
require_relative("../converter")

# COWORKER_FILE and other file names should be defined ../converter.rb

def process_rows(file_name)
    data = File.open(file_name, 'r').read.encode('UTF-8',"ISO-8859-1")
    rows = GoImport::CsvHelper::text_to_hashes(data)
    rows.each do |row|
        yield row
    end
end

def convert_source
    puts "Trying to convert CSV source to LIME Go..."

    converter = Converter.new

    # A rootmodel is used to represent all entitite/models that is
    # exported
    rootmodel = GoImport::RootModel.new

    converter.configure(rootmodel)

    # coworkers
    # start with these since they are referenced
    # from everywhere....
    if defined?(COWORKER_FILE) && !COWORKER_FILE.nil? && !COWORKER_FILE.empty?
        process_rows COWORKER_FILE do |row|
            rootmodel.add_coworker(converter.to_coworker(row))
        end
    end

    # organizations
    if defined?(ORGANIZATION_FILE) && !ORGANIZATION_FILE.nil? && !ORGANIZATION_FILE.empty?
        process_rows ORGANIZATION_FILE do |row|
            rootmodel.add_organization(converter.to_organization(row, rootmodel))
        end
    end

    # persons
    # depends on organizations
    if defined?(PERSON_FILE) && !PERSON_FILE.nil? && !PERSON_FILE.empty?
        process_rows PERSON_FILE do |row|
            # adds it self to the employer
            converter.to_person(row, rootmodel)
        end
    end

    # deals
    # deals can reference coworkers (responsible), organizations
    # and persons (contact)
    if defined?(DEAL_FILE) && !DEAL_FILE.nil? && !DEAL_FILE.empty?
        process_rows DEAL_FILE do |row|
            rootmodel.add_deal(converter.to_deal(row, rootmodel))
        end
    end

    return rootmodel
end

