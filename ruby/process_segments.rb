require 'json'
segs = V2::SegmentDefinition.all

def create_segment_code_system(segs)
  # create code system of complex data types
  concept = []
  segs.each do |s|
    # puts "#{s.code} - #{s.name}"
    concept << { code:"http://hl7.org/v2/StructureDefinition/#{s.code}", display:s.name }
  end

  path = File.expand_path("~/projects/v2fhir/fhir/segment/v2-cs-segments.json")
  file = File.open(path, 'r')
  json = JSON.load(file)
  file.close
  json['concept'] = concept

  File.open(path, 'w+') { |f| f.puts JSON.pretty_generate(json) }
end

# FIXME what to do with Hxx and ... (Varies)?
def create_segment_structure_definitions(segs)
  # Create StructureDefs for complex data types
  path     = File.expand_path("~/projects/v2fhir/fhir/templates/segdef_template.json")
  file     = File.open(path, 'r')
  template = JSON.load(file)
  file.close

  segs.each do |seg|
    json = template.dup
    code = seg.code
    json['id']   = code
    json['title'] = "HL7 v2 #{code} Segment Definition"
    json['url']  = "http://hl7.org/v2/StructureDefinition/#{code}"
    json['name'] = code
    json['type'] = "http://hl7.org/v2/StructureDefinition/#{code}"
    elements = []
    seg.fields.each do |field|
      de = field.data_element
      # {
      #   "id" : "PID.1",
      #   "path" : "PID.1",
      #   "code" : [ { "system" : "http://hl7.org/v2/CodeSystem/Items", "code" : "00104" }],
      #   "short" : "Set ID - PID",
      #   "definition" : "This field contains the number that identifies this transaction. For the first occurrence of the segment, the sequence number shall be one, for the second occurrence, the sequence number shall be two, etc.",
      #   "min" : 0,
      #   "max" : "1",
      #   "type" : [{ "code" : "http://hl7.org/v2/StructureDefinition/SI"}],
      #   "maxLength" : 4
      # },
      # puts field.class.properties.keys.sort
      # puts
      # puts field.data_element.class.properties.keys.sort
      el = {}
      el[:id]    = "#{code}.#{field.sequence_number}"
      el[:path]  = el[:id]
      el[:short] = "#{field.name} - #{code}"
      el[:definition]  = field.definition_text.definition_content  if field.definition
      el[:description] = field.definition_text.description_content if field.definition
      el[:code]  = [ { system:"http://hl7.org/v2/CodeSystem/DataElements", code:de.item_number } ]
      opt = field.optionality.value
      el[:min]   =  case opt
                    when 'R'
                      1
                    when 'O'
                      0
                    when 'W'
                      0
                    when 'C', 'C(R/X)', 'C(RE/X)', 'B' # FIXME I suppose we have to go through by hand and see if we can craft invariants for these...
                      0
                    when '-' # WTF? FIXME
                      0
                    else
                      raise "optionality is #{opt} for #{code}.#{field.sequence_number} in #{seg.origin}"
                    end
      el[:max] = field.repetition ? "*" : "1"
      # Now we're into data elements
      if de.type.nil? && opt != 'W'
        puts "#{code}.#{field.sequence_number} in #{seg.origin} has data element with no type"
        raise
      end
      el[:type] = [{ code: "http://hl7.org/v2/StructureDefinition/#{de.type&.code}"}] if de.type&.code
      # TODO we have to parse Ch2 first in order to have the binding strength for all the tables readily available.  How fun...
      # FIXME what if we have multiple tables????
      tbl = de.vocab ? de.vocab.code_systems.first.table_id.to_s.rjust(4, '0') : nil
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
      if de.min_length || de.max_length
        extensions << { 
          url: "http://hl7.org/fhir/StructureDefinition/v2-length",
          extension: [
            {
              url: "min",
              valueInteger: de.min_length
            },
            {
              url: "max",
              valueInteger: de.max_length
            }
          ]
        }
      end
      if de.c_length
        extensions << { 
          url: "http://hl7.org/fhir/StructureDefinition/v2-conformance-length",
          extension: [
            {
              url: "length",
              valueInteger: de.c_length
            },
            {
              url: "noTruncate",
              valueInteger: !!(de.may_truncate)
            }
          ]
        }
      end
      el[:extension] = extensions if extensions.any?
      elements << el
    end
    json['differential']['element'] = elements
  
    path = File.expand_path("~/projects/v2fhir/fhir/segment/#{seg.code.downcase}.json")
    File.open(path, 'w+') { |f| f.puts JSON.pretty_generate(json) }
    puts "#{seg.code} written"
  end  
end
create_segment_code_system(segs)
create_segment_structure_definitions(segs)