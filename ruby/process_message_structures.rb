require 'json'
structs = V2::MessageStructure.all

def create_message_structure_code_system(structs)
  # create code system of complex data types
  concept = []
  structs.each do |s|
    # NOTE - FIXME - there are still issues with there being multiple msg structures for the same code.  This is being handled now by appending a letter to the code (A, B, C, etc..).
    concept << { code:"http://hl7.org/v2/StructureDefinition/#{s.code}", display:s.code }
  end

  path = File.expand_path("~/projects/v2fhir/fhir/message_structure/v2-cs-message-structures.json")
  file = File.open(path, 'r')
  json = JSON.load(file)
  file.close
  json['concept'] = concept

  File.open(path, 'w+') { |f| f.puts JSON.pretty_generate(json) }
end

# FIXME what to do with Hxx and ... (Varies)?
def create_message_structures(structs)
  # Create StructureDefs for complex data types
  path     = File.expand_path("~/projects/v2fhir/fhir/templates/msg_struct_template.json")
  file     = File.open(path, 'r')
  template = JSON.load(file)
  file.close

  structs.each do |struct|
    json = template.dup
    code = struct.code
    url_code = code#.gsub('_', '-')
    json['id']   = url_code
    json['title'] = "HL7 v2 #{code} Segment Definition"
    json['url']  = "http://hl7.org/v2/StructureDefinition/#{url_code}"
    json['name'] = code
    json['type'] = "http://hl7.org/v2/StructureDefinition/#{url_code}"
    elements = []
    struct.segments.each_with_index do |seg, i|
      elements.push(create_fhir_segment(code, seg, i, struct.origin))
    end
    json['differential']['element'] = elements
  
    path = File.expand_path("~/projects/v2fhir/fhir/message_structure/#{code.downcase}.json")
    File.open(path, 'w+') { |f| f.puts JSON.pretty_generate(json) }
    # puts "#{code} written"
  end  
end

def create_fhir_segment(prefix, seg, i, origin)
  fhir = {}
  case seg
  when V2::Segment
    element_id = "#{i+1}-#{seg.type.code}"
    element_type = "http://hl7.org/v2/StructureDefinition/#{seg.type.code}"
    text = seg.description
  when V2::SegmentSequence
    element_id = "#{i+1}-#{seg.name}"
    element_type = 'BackboneElement'
    text = seg.name
    sub_elements = []
    seg.segments.each_with_index do |sseg, j|
      sub_elements << create_fhir_segment("#{prefix}.#{element_id}", sseg, j, origin)
    end
  when V2::SegmentChoice
    # FIXME can we programmatically create and apply constraints here?
    element_id = "#{i+1}-#{seg.name}"
    element_type = 'BackboneElement'
    text = seg.name
    sub_elements = []
    seg.groups.each_with_index do |group, j|
      sub_elements << create_fhir_segment("#{prefix}.#{element_id}", group, j, origin)
    end
    puts Rainbow("Have a look at #{prefix}.#{element_id} in #{origin}").cyan
  when V2::ExampleSegment
    element_id = "#{i+1}-#{seg.name}"
    element_type = 'code'
    text = seg.description
  when V2::SegmentGroup
    element_id = "#{i+1}"
    element_type = 'BackboneElement'
    text = "Choice group #{element_id} within #{seg.segment_choice.name}"
    sub_elements = []
    seg.segments.each_with_index do |sseg, j|
      sub_elements << create_fhir_segment("#{prefix}.#{element_id}", sseg, j, origin)
    end
  else
    raise "what do I do with a #{seg.class}?"
  end
  unless seg.is_a?(V2::SegmentGroup)
    raise "#{prefix}.#{element_id} has status #{seg.status}" if seg.status&.[](0)
  end
  # puts "Doing #{prefix}.#{element_id}.  Status is #{seg.status}"
  
  fhir[:id]         = "#{prefix}.#{element_id}" 
  fhir[:path]       = "#{prefix}.#{element_id}"
  fhir[:short]      = 
  fhir[:definition] = 
  if seg.is_a?(V2::SegmentGroup)
    fhir[:min]        = 0
    fhir[:max]        = "1"
  else
    fhir[:min]        = seg.optional ? 1 : 0
    fhir[:max]        = seg.repeat ? "*" : "1"
  end
  fhir[:type]       = [{ code:element_type }]
  elements = [fhir]
  elements.push(sub_elements) if sub_elements&.any?
  elements
end

create_message_structure_code_system(structs)
create_message_structures(structs)