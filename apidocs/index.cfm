<cfparam name="url.version" default="0">
<cfparam name="url.path" 	default="#expandPath( "./SNSSDK-APIDocs" )#">
<cfscript>
	docName = "SNSSDK-APIDocs";
	base 	= expandPath( "/snssdk" );
	docbox 	= new docbox.DocBox( properties = {
		projectTitle 	= "SNSSDK v#url.version#",
		outputDir 		= url.path
	} );
	docbox.generate( source=base, mapping="snssdk", excludes="(tests|apidocs|testbox)" );
</cfscript>

<!---
<cfzip action="zip" file="#expandPath('.')#/#docname#.zip" source="#expandPath( docName )#" overwrite="true" recurse="yes">
<cffile action="move" source="#expandPath('.')#/#docname#.zip" destination="#url.path#">
--->

<cfoutput>
<h1>APIDocs Created v#url.version#!</h1>
<a href="#docName#/index.html">Go to Docs!</a>
</cfoutput>

