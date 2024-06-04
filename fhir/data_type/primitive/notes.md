### v2 primitives and their relationship to FHIR primitives
- in the datatype_profile, it specifies that derivation = constraint.  I think this implies that there is something to derive it from (i.e., a FHIR primitive) but I'm not sure we can correctly derive all v2 primitives from FHIR primitives.  For example, NM 


- DT = date `/^\d{4}([01]\d([0123]\d)?)?$/` not perfect regex...allows months and days like "44"

- DTM = dateTime `/^\d{4}([01]\d([0123]\d(([01][0-9]|2[0-3])([0-5]\d([0-5]\d(\.\d{1,4})?)?)?)?)?)?([+-][01]\d[034][05])?$/`

- FT is derived from TX (which is FHIR string).  I'm not sure how to express the purpose of an FT by means of a differential from TX.  Can it be a constraint on TX without a differential??

- GTS is derived from ST and follows v3 GTS rules.  Same issues as FT regarding constraint and differential expression.

- ID = FHIR code, must be bound to an HL7-defined VS

- IS = FHIR code, must be bound to a non-HL7-defined VS

- NM doesn't precisely map to any FHIR primitive.  Additionally, it isn't clear what the length restriction is since Ch2's definition of length applies to strings, not numerics.  E.g., are we talking about the string representation when we talk about length, in which case the minus sign and decimal point take space OR are we talking about bit sizes?  Presumably we are talking about the former, in which case we can represent larger positive integers than negative integers by 1 order of magnitude.  The same is true for integers vs. decimal values.

- SI also doesn't have an analog.  This is a whole number from 0-9999.  You would use FHIR int

- SNM - derived from string.  `/^[\+0-9]+$/`  ...though I think they really mean `/^\+?\d+$/`

- ST not exactly like FHIR.  FHIR allows leading white space where v2 does not.  apparently this is not intended for long strings either (> 1000 characters) `/^\S.*/`

- TM this is a string that conforms this this regex `^([01][0-9]|2[0-3])([0-5]\d([0-5]\d(\.\d{1,4})?)?)?([+-][01]\d[034][05])?$` note: regex is for UTC offsets.  more relaxed would simply be `^([01][0-9]|2[0-3])(\d{2}(\d{2}(\.\d{1,4})?)?)?([+-][01]\d{3})?`
  * this is not derived from FHIR time data type because v2 TM can include time zone offset and FHIR time cannot.

- TX = FHIR string

- Varies = a reference to any v2 Data Type.  In FHIR, can you have a Reference to an abstract type and leave it at that?


Note that FHIR assumes numeric types are base 10...
