require 'json'
dts = V2::DataType.all.select { |dt| dt.components_count > 1 }.sort_by { |dt| dt.code } # don't want primitives, which have no components

# create code system of complex data types
concept = []
dts.each do |dt|
  concept << { code:"http://hl7.org/v2/StructureDefinition/#{dt.code}", display:dt.name }
end

path = File.expand_path("~/projects/v2fhir/fhir/data_type/complex/v2-cs-complex-data-types.json")
file = File.open(path, 'r')
json = JSON.load(file)
file.close
json['concept'] = concept

File.open(path, 'w+') { |f| f.puts JSON.pretty_generate(json) }


# Create StructureDefs for complex data types
path     = File.expand_path("~/projects/v2fhir/fhir/templates/cdt_template.json")
file     = File.open(path, 'r')
template = JSON.load(file)
file.close

dts.each do |dt|
  json = template.dup
  code = dt.code
  json['id']   = code
  json['url']  = "http://hl7.org/v2/StructureDefinition/#{code}"
  json['name'] = code
  json['type'] = "http://hl7.org/v2/StructureDefinition/#{code}"
  elements = []
  dt.components.each do |comp|
    el = {}
    el[:id]    = "#{code}.#{comp.sequence_number}"
    el[:path]  = el[:id]
    el[:short] = comp.name
    opt = comp.optionality.value
    el[:min]   =  case opt
                  when 'R'
                    1
                  when 'O', 'C'
                    0
                  else
                    raise "optionality is #{opt} for #{code}.#{comp.sequence_number}"
                  end
    el[:max]  = "1"
    el[:type] = [{ code: "http://hl7.org/v2/StructureDefinition/#{comp.type.code}"}]
    # TODO we have to parse Ch2 first in order to have the binding strength for all the tables readily available.  How fun...
    tbl = comp.vocab ? comp.vocab.code_systems.first.table_id.to_s.rjust(4, '0') : nil
    if tbl
      el[:binding] = {
        strength: "TBD",
        valueSet: "http://terminology.hl7.org/ValueSet/v2-#{tbl}"
      }
    end
    extensions = []
    if opt
      extensions << { 
        url: "http://hl7.org/fhir/StructureDefinition/v2-optionality",
        valueCode: opt
      }
    end
    if comp.min_length || comp.max_length
      extensions << { 
        url: "http://hl7.org/fhir/StructureDefinition/v2-length",
        extension: [
          {
            url: "min",
            valueInteger: comp.min_length
          },
          {
            url: "max",
            valueInteger: comp.max_length
          }
        ]
      }
    end
    if comp.c_length
      extensions << { 
        url: "http://hl7.org/fhir/StructureDefinition/v2-conformance-length",
        extension: [
          {
            url: "length",
            valueInteger: comp.c_length
          },
          {
            url: "noTruncate",
            valueInteger: !!(comp.may_truncate)
          }
        ]
      }
    end
    el[:extension] = extensions if extensions.any?
    elements << el
  end
  json['differential']['element'] = elements
  
  path = File.expand_path("~/projects/v2fhir/fhir/data_type/complex/#{dt.code.downcase}.json")
  File.open(path, 'w+') { |f| f.puts JSON.pretty_generate(json) }
end  
