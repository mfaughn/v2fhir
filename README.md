# v2fhir

This is a work in progress.  There are many, many questions to be answered.
- So far I've only gotten to data types.  The primitives were done by hand.  The complex data types were done programmatically.
- Strictly speaking, NM is not a derivative of any FHIR primitive.  As such, it needs to be defined as a specialization, right?  I'm not at all sure I did that correctly.
- Is there a way to constrain a primitive type value to a regular expression using some element of ElementDefinition, e.g., patternExpression? alternatively, can it be done with a constraint? My first pass attempt was to do it with a constraint but I'm not sure I've done that right.  See st.json for an example.
- FT is derived from TX (which is FHIR string).  I'm not sure how to express the purpose of an FT by means of a differential from TX.  Can it be a constraint on TX without a differential??
- Does si.json properly use minValueInteger and maxValueInteger?
- Plenty of other stuff in here I'm not 100% sure of whether it is done correctly or not...
- 
