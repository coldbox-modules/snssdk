/*-----------------------------------------------------------------------
********************************************************************************
Copyright 2005-2007 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.coldboxframework.com | www.luismajano.com | www.ortussolutions.com
********************************************************************************

Amazon SNS REST Wrapper

Version 1.0 - Gavin Pickin created. 

Credits:

Derived from https://github.com/coldbox-modules/s3sdk created by Luis Majano ( Ortus Solutions )

Modified to use the V4 Signature generation with modifications from https://gist.github.com/Leigh-/a2798584b79fd9072605a4cc7ff60df4 
Created by Leigh: https://github.com/Leigh-


You will have to create some settings in your ColdBox configuration file:

aws_accessKey : The Amazon access key
aws_secretKey : The Amazon secret key
aws_encryption_charset : encryptyion charset (Optional, defaults to utf-8)
aws_ssl : Whether to use ssl on all cals or not (Optional, defaults to false)
-----------------------------------------------------------------------*/

component singleton{

	// DI
	property name="log" inject="logbox:logger:{this}";

	// Properties
	property name="accessKey";
	property name="secretKey";
	property name="encryption_charset";
	property name="ssl";
	property name="URLEndPoint";
	property name="defaultRegionName";
	property name="defaultServiceName";
	property name="signatureAlgorithm";
	property name="hashAlorithm";

	// STATIC Contsants
	this.ACL_PRIVATE 			= "private";
	this.ACL_PUBLIC_READ 		= "public-read";
	this.ACL_PUBLIC_READ_WRITE 	= "public-read-write";
	this.ACL_AUTH_READ 			= "authenticated-read";

	/**
	* Constructor
	* @accessKey
	* @secretKey
	* @encryption_charset
	* @ssl
	* @defaultRegionName
	* @defaultServiceName
	* @signatureAlgorithm
	* @hashAlorithm
	*
	* @returnType AmazonSNS
	*/
	public function init( 
		required accessKey,
		required secretKey,
		encryption_charset="utf-8",
		ssl=false,
		string defaultRegionName = "us-east-1",
		string defaultServiceName = "sns",
		signatureAlgorithm = "AWS4-HMAC-SHA256",
		hashAlorithm = "SHA256"
		) {
		
			for( var thiskey in arguments ){
				variables[ thisKey ] = arguments[ thisKey ];
			}

			if( !isBoolean( arguments.ssl ) ){
				variables.ssl = false; 
			} else { 
				variables.ssl = arguments.ssl; 
			}

			variables.defaultRegionName = arguments.defaultRegionName;
			variables.defaultServiceName = arguments.defaultServiceName;
			
			// Algorithms used in calculating the signature
			variables.signatureAlgorithm	= arguments.signatureAlgorithm;
			variables.hashAlorithm 	 		= arguments.hashAlorithm;
		
			updateURLEndpoint();
			return this;
	}

	/**
	* setAuth - Set the Amazon credentials
	* @accessKey
	* @secretKey
	*/ 
    function setAuth( required accessKey, required secretKey ){
			variables.accessKey = arguments.accessKey;
			variables.secretKey = arguments.secretKey;
	}
	
	/**
	* Set SSL flag and alter the internal URL End point pointer
	* @useSSL Set to true or false
	*/
    function setSSL( useSSL=true ){
    	if( isBoolean( arguments.useSSL ) ){
    		variables.ssl = arguments.useSSL;	
    	}
    	updateURLEndpoint();
	}

	/**
	* Set Region and alter the internal URL End point pointer
	* @region Set to the name of the new Region
	*/
    function setRegion( region ){
    	if( structKeyExists( arguments, "region" ) && len( arguments.region ) ){
    		variables.defaultRegionName = arguments.region;	
    	}
		updateURLEndpoint();
	}
	
	/**
	* Using the service name, region, and ssl setting, update the URLEndPoint for the Service
	*/
	function updateURLEndpoint(){
		if( variables.ssl ){
			variables.URLEndPoint = "https://#variables.defaultServiceName#.#variables.defaultRegionName#.amazonaws.com"; 
		} else{ 
			variables.URLEndPoint = "http://#variables.defaultServiceName#.#variables.defaultRegionName#.amazonaws.com"; 
		}
	}
	
//------------------------------------------- PUBLIC ------------------------------------------>
	
	/**
	* publishToPhone
	* @phoneNumber
	* @message
	*/ 
	function publishToPhone( required phoneNumber, required message ){
		// Invoke call
		var results = awsRequest(
			parameters = {
				"Action"		= "Publish",
				"PhoneNumber" 	= arguments.phoneNumber,
				"Message" 		= arguments.message
			} 
		);
		// error
		if( results.error ){
			throw( message="Error making Amazon REST Call", detail=results.message );
		}

		return results;
	}	
	
	/**
	* publishToTopic
	* @arn
	* @message
	*/ 
	function publishToTopic( required arn, required message ){
		// Invoke call
		var results = awsRequest(
			parameters = {
				"Action"		= "Publish",
				"TopicArn" 	= arguments.arn,
				"Message" 		= arguments.message
			} 
		);
		// error
		if( results.error ){
			throw( message="Error making Amazon REST Call", detail=results.message );
		}

		return results;
	}
	
	/**
	* publishToTarget
	* @arn
	* @message
	*/ 
	function publishToTarget( required arn, required message ){
		// Invoke call
		var results = awsRequest(
			parameters = {
				"Action"		= "Publish",
				"TargetArn" 	= arguments.arn,
				"Message" 		= arguments.message
			} 
		);
		// error
		if( results.error ){
			throw( message="Error making Amazon REST Call", detail=results.message );
		}

		return results;
	}

	function ListTopics(){
		// Invoke call
		var results = awsRequest(
			method	= "GET",
			headers = {
				"content-type": "application/x-www-form-urlencoded;"	
			},
			parameters = {
				"Action":"ListTopics"
			}	
		);
		// error
		if( results.error ){
			throw( message="Error making Amazon REST Call", detail=results.message );
		}
		return results;
	}	
	 
	
	
	
	
	
	
	
	
	
	

















//------------------------------------------- PRIVATE ------------------------------------------>

	/**
	* AWS Request - Invoke an Amazon REST Call
	* @method The HTTP method to invoke
	* @resource The resource to hit in the amazon service.
	* @body The body content of the request if passed.
	* @headers An struct of HTTP headers to send
	* @amzHeaders An struct of amz header name-value pairs to send
	* @parameters An struct of HTTP URL parameters to send in the request
	* @timeout The default call timeout
	*/
    private struct function awsRequest(
    	method		=	"GET",
    	resource	=	"",
    	body		=	"",
    	headers		=	structNew(),
    	amzHeaders	=	structNew(),
    	parameters	=	structNew(),
    	timeout		=	20 ){
    
			var results = {
				error 			= false,
				response 		= {},
				message 		= "",
				responseheader 	= {}
			};
			var HTTPResults = "";
			//var timestamp = GetHTTPTimeString( Now() );
			var utcDateTime = dateConvert("local2UTC", now());
			var dateStamp = dateFormat( utcDateTime, "YYYYMMDD" );
			var timestamp = dateStamp &"T"& replace(timeFormat(utcDateTime, "HH:mm:ss"), ":", "", "all" ) & "Z";
			var param = "";
			var md5 = "";
			var amz = "";
			var sortedAMZ = listToArray( listSort( structKeyList( arguments.amzHeaders ), "textnocase" ) );

			// Default Content Type
			if( NOT structKeyExists( arguments.headers, "content-type" ) ){
				arguments.headers[ "content-type" ] = "";
			}

			// Prepare amz headers in sorted order
			for(var x=1; x lte ArrayLen( sortedAMZ ); x++){
				// Create amz signature string
				arguments.headers[ sortedAMZ[ x ]] = arguments.amzHeaders[sortedAMZ[ x ]];
				amz = amz & "\n" & sortedAMZ[ x ] & ":" & arguments.amzHeaders[sortedAMZ[ x ]];
			}

			// Create Signature
			//var signature = "#arguments.method#\n#md5#\n#arguments.headers['content-type']#\n#timestamp##amz#\n/#arguments.resource#";
			//log.debug( "Prepared Signature: #signature#" );
			//signature = createSignature( signature );
		
		var signatureData = generateSignatureData(
			requestMethod 		= "#arguments.method#"
			,hostName			= "sns.us-east-1.amazonaws.com"
			,requestURI			= "/"
			,requestBody		= arguments.body
			,requestHeaders		= arguments.headers
			,requestParams		= arguments.parameters
			,regionName			= "us-east-1"
			,serviceName		= "sns"
			,dateStamp			= "#dateStamp#"
			,amzDate			= "#timestamp#"
			,signedPayload		= true
		);
		//writeDump( arguments );
		//writeDump( signatureData );

		// REST CAll
		http method="#arguments.method#"
				url="#variables.URLEndPoint#/#arguments.resource#"
				charset="utf-8"
				result="HTTPResults"
				timeout="#arguments.timeout#"{
			
			// Amazon Global Headers
			httpparam type="header" name="Date" value="#timestamp#";
			httpparam type="header" name="Authorization" value="#signatureData.AUTHORIZATIONHEADER#";
			
			// Headers
			for( var param in arguments.headers ){
				httpparam type="header" name="#param#" value="#arguments.headers[param]#";
			}
			
			// URL Parameters: encoded automatically by CF
			for( var param in arguments.parameters ){
				httpparam type="URL" name="#param#" value="#arguments.parameters[param]#";
			}
			
			// Body
			if( len( arguments.body ) ){
				httpparam type="body" value="#arguments.body#";
			}
					
		}

		//writeDump( HTTPResults ); abort;
		
		// Log
		//log.debug( "Amazon Rest Call ->Arguments: #arguments.toString()#, ->Encoded Signature=#signature#", HTTPResults );

		// Set Results
		results.response 		= HTTPResults.fileContent;
		results.responseHeader 	= HTTPResults.responseHeader;
		// Error Detail
		results.message = HTTPResults.errorDetail;
		if( len( HTTPResults.errorDetail ) ){ results.error = true; }

		// Check XML Parsing?
		if( structKeyExists( HTTPResults.responseHeader, "content-type" ) AND
		    HTTPResults.responseHeader["content-type"] eq "application/xml" AND
			isXML( HTTPResults.fileContent ) 
		){
			results.response = XMLParse( HTTPResults.fileContent );
			// Check for Errors
			if( NOT listFindNoCase( "200,204", HTTPResults.responseHeader.status_code ) ){
				// check error xml
				results.error 	= true;
				results.message = "Code: #results.response.error.code.XMLText#. Message: #results.response.error.message.XMLText#";
			}
		}

		return results;
	}

	/**
	*  Generates Signature 4 properties for the supplied request settings.
	*
	*  @requestMethod   - Request operation, ie PUT, GET, POST, etcetera.
	*  @hostName   	    - Target host name, example: bucketname.s3.amazonaws.com
	*  @requestURI 	    - Absolute path of the URI. Portion of the URL after the host, to the "?" beginning the query string
	*  @requestBody     - Body of the request. Either a string or binary value.
	*  @requestHeaders  - Structure of http headers for used the request. Mandatory host and date headers are automatically generated.
	*  @requestParams   - Structure containing any url parameters for the request. Mandatory parameters are automatically generated.
	*  @signedPayload   - If true, include hash of requestPayload in signature calculations. Otherwise, literal "UNSIGNED-PAYLOAD". Default is true.
	*  @excludeHeaders  - (Optional) List of header names AWS can exclude from the signing process. Default is an empty array, which means all headers should be "signed"
	*  @amzDate 	    - (Optional) Override the automatic X-Amz-Date calculation with this value. Current UTC date. If supplied, @dateStamp is required.  Format: yyyyMMddTHHnnssZ
	*  @regionName 	    - (Optional) Override the instance region name with this value. Example "us-east-1"
	*  @serviceName	    - (Optional) Override the instance service name with this value. Example "s3"
	*  @dateStamp	    - (Optional) Override the automatic dateStamp calculation with this value. Current UTC date (only). If supplied, @amzDate is required. Format: yyyyMMdd 
	*  @returns  Signature value, authorization header and all properties part of the signature calculation: ALGORITHM,AMZDATE,AUTHORIZATIONHEADER,CANONICALHEADERS,CANONICALQUERYSTRING,CANONICALREQUEST,CANONICALURI,CREDENTIALSCOPE,DATESTAMP,EXCLUDEHEADERS,HOSTNAME,REGIONNAME,REQUESTHEADERS,REQUESTMETHOD,REQUESTPARAMS,REQUESTPAYLOAD,SERVICENAME,IGNATURE,SIGNEDHEADERS,SIGNKEYBYTES,STRINGTOSIGN
    *
	*/
	public struct function generateSignatureData(
		required string requestMethod
		, required string hostName
		, required string requestURI
		, required any requestBody
		, required struct requestHeaders
		, required struct requestParams
		, boolean signedPayload = true
		, array excludeHeaders = []
		, string regionName
		, string serviceName
		, string amzDate 
		, string dateStamp 
	) {
		
		// Initialize properties
		var props = {}; 
		var headerNames = '';
		var hasQueryParams = structCount(arguments.requestParams) > 0;
		var utcDateTime = dateConvert("local2UTC", now());
		
		
		// Generate UTC time stamps 
		props.dateStamp = dateFormat( utcDateTime, "YYYYMMDD" );
		//props.amzDate = props.dateStamp &"T"& replace(timeFormat(utcDateTime, "HH:mm:ssZ"), ":", "", "all" );
		props.amzDate = props.dateStamp &"T"& replace(timeFormat(utcDateTime, "HH:mm:ss"), ":", "", "all" ) & "Z";
		//writeDump( props );
		// Override current utc date and time
		if (structKeyExists(arguments, "amzDate") || structKeyExists(arguments, "dateStamp")) {
			props.dateStamp = arguments.dateStamp;
			props.amzDate = arguments.amzDate;
		}
		//writeDump( props );
		// Apply instance level region/service name settings
		props.regionName = variables.defaultRegionName;
		props.serviceName = variables.defaultServiceName;
		
		// Override instance level region/service names 
		if (structKeyExists(arguments, "regionName")) {
			props.regionName = arguments.regionName;
		}
		if (structKeyExists(arguments, "serviceName")) {
			props.serviceName = arguments.serviceName;
		}
		
		/////////////////////////////////////
		// 	Basic request properties
		/////////////////////////////////////
		props.algorithm 	= variables.signatureAlgorithm;
		props.hostName 		= arguments.hostName;
		props.requestMethod 	= arguments.requestMethod;
		props.canonicalURI 	= buildCanonicalURI( requestURI = arguments.requestURI );
		// For signed requests, the payload is a checksum
		props.requestPayload    = arguments.signedPayload ? hash256( arguments.requestBody ) : arguments.requestBody ;
		props.credentialScope 	= buildCredentialScope( dateStamp=props.dateStamp, serviceName=props.serviceName, regionName=props.regionName );
		
	
		/////////////////////////////////////
		// 	Validate headers/parameters 
		/////////////////////////////////////
		props.requestHeaders 	= duplicate( arguments.requestHeaders );
		props.requestParams 	= duplicate( arguments.requestParams );
		
		// Host header is mandatory for ALL requests
		props.requestHeaders["Host"] = arguments.hostName;

		// Signed requests must include a checksum, ie hash of payload
		if (arguments.signedPayload) {
			//props.requestHeaders["X-Amz-Content-Sha256"] = props.requestPayload;
		} 
		
		// Apply mandatory headers and parameters
		if (hasQueryParams) {
			
			// First, normalize request headers 
			props.requestHeaders = cleanHeaders( props.requestHeaders );
			props.excludeHeaders = cleanHeaderNames( arguments.excludeHeaders );
			// Identify which headers will be included in the signing process 
			props.signedHeaders = buildSignedHeaders( requestHeaders=props.requestHeaders, excludeNames=props.excludeHeaders );

			// When passing all parameters in query string, canonical query string must also 
			// include the parameters used as part of the signing process, ie hashing algorithm,
			// credential scope, date, and signed headers parameters.
//			props.requestParams["X-Amz-Algorithm"] = variables.signatureAlgorithm;
//			props.requestParams["X-Amz-Credential"] = variables.accessKeyId &"/"& props.credentialScope;
//			props.requestParams["X-Amz-SignedHeaders"] = props.signedHeaders;
//			props.requestParams["X-Amz-Date"] = props.amzDate;
			
			// Finally, normalize url parameters
			props.requestParams = encodeQueryParams( queryParams=props.requestParams );
			
		}
		// All other request types (PUT, DELETE, POST, ....)
		else {
		
			// Host header is mandatory for ALL requests
			props.requestHeaders["Host"] = arguments.hostName;
			// Date header is mandatory when not passing values in url
			props.requestHeaders["X-Amz-Date"] = props.amzDate;

			// For signed requests, include a checksum header, ie hash of payload
			if (arguments.signedPayload) {
				//props.requestHeaders["X-Amz-Content-Sha256"] = props.requestPayload;
			} 
		
			// Normalize headers and url parameters
			props.requestHeaders = cleanHeaders( props.requestHeaders );
			props.excludeHeaders = cleanHeaderNames( arguments.excludeHeaders );
			// Identify which headers will be included in the signing process 
			props.signedHeaders = buildSignedHeaders( requestHeaders=props.requestHeaders, excludeNames=props.excludeHeaders );
			props.requestParams = encodeQueryParams( queryParams=props.requestParams );
			
		}
		

		/////////////////////////////////////////
		// 	Generate signature
		/////////////////////////////////////////
		
		// Generate header, query, and request strings
		props.canonicalQueryString = buildCanonicalQueryString( requestParams=props.requestParams );
		props.canonicalHeaders = buildCanonicalHeaders( requestHeaders=props.requestHeaders );
		props.canonicalRequest = buildCanonicalRequest( argumentCollection=props );

		// Generate signature and authorization strings
		props.stringToSign = generateStringToSign( argumentCollection=props );
		props.signKeyBytes = generateSignatureKey( argumentCollection=props );
		props.signature = lcase( binaryEncode( hmacBinary( message=props.stringToSign, key=props.signKeyBytes), "hex") );
		props.authorizationHeader = buildAuthorizationHeader( argumentCollection=props );
		
		// (Debugging) Convert binary values into human readable form 
		props.signKeyBytes = binaryEncode( props.signKeyBytes, "hex" );

		return props;
	}

	/**
	*  Generates request string to sign
	*
	*  @amzDate   	     - Current timestamp in UTC. Format yyyyMMddTHHnnssZ
	*  @credentialScope  - String defining scope of request. See buildCredentialScope().
	*  @canonicalRequest - Canonical request string
	*  @returns  	     - String to be signed 
	*/
	private string function generateStringToSign(
		required string amzDate
		, required string credentialScope 
		, required string canonicalRequest
	) {

		// Format: Algorithm + '\n' + RequestDate + '\n' + CredentialScope + '\n' + HashedCanonicalRequest
		var elements = [ variables.signatureAlgorithm
						, arguments.amzDate
						, arguments.credentialScope
						, hash256( arguments.canonicalRequest ) 
					];

		return arrayToList( elements, chr(10) );
	}
	
	/**
	*  Generate canonical request string
	*
	*  @requestMethod   		- Request operation, ie PUT, GET, POST, etcetera.
	*  @canonicalURI 	    	- Canonical URL string. See buildCanonicalURI
	*  @canonicalHeaders   		- Canonical header string. See buildCanonicalHeaders
	*  @canonicalQueryString   	- Canonical query string. See buildCanonicalQueryString
	*  @signedHeaders  		    - List of signed headers. See buildSignedHeaders
	*  @requestPayload  		- For signed requests, this is the hash of the request body. Otherwise, the raw request body
	*/
	private string function buildCanonicalRequest(
		required string requestMethod
		, required string canonicalURI
		, required string canonicalQueryString
		, required string canonicalHeaders
		, required string signedHeaders
		, required string requestPayload ){
		
		var canonicalRequest = "";
		
		// Build ordered list of elements in the request, delimited by new lines
		// Note: Headers and signed headers should never be empty. "Host" header is always required.
		canonicalRequest = arguments.requestMethod & chr(10) 
							& arguments.canonicalURI & chr(10) 
							& arguments.canonicalQueryString & chr(10) 
							& arguments.canonicalHeaders & chr(10) 
							& arguments.signedHeaders & chr(10) 
							& arguments.requestPayload ;

		return canonicalRequest;
	}
	
	/**
	 * Generates canonical query string
	 * <ul>
	 *	<li>URI-encode each parameter name and value according to RFC 3986 </li>
	 *	<li>Percent-encode all other characters with %XY, where X and Y are hexadecimal characters (0-9 and uppercase A-F)  </li>
	 *	<li>Sort the encoded parameter names by character code in ascending order (ASCII order) </li>
	 *	<li>Build the canonical query string by starting with the first parameter name in the sorted list. </li>
	 *	<li>For each parameter, append the URI-encoded parameter name, followed by the character '=' (ASCII code 61), followed by the URI-encoded parameter value. Use an empty string for parameters that have no value. </li>
	 *	<li>Append the character '&' (ASCII code 38) after each parameter value, except for the last value in the list. </li>
	 *  </ul>
	 *
	 * @requestParams Structure containing all parameters passed via the query string. 
	 * @isEncoded If true, the supplied parameters are already url encoded
	 * @returns canonical query string 
	 */
	private string function buildCanonicalQueryString(required struct requestParams, boolean isEncoded = true) {
		var encodedParams = "";
		var paramNames = "";
		var paramPairs = "";
		
		// Ensure parameter names and values are URL encoded first
		encodedParams = isEncoded ? arguments.requestParams : encodeQueryParams( arguments.requestParams );
		
		// Extract and sort encoded parameter names
		paramNames = structKeyArray( encodedParams );
		arraySort( paramNames, "text", "asc" );

		// Build array of sorted name/value pairs
		paramPairs = [];
		arrayEach( paramNames, function(string param) {
			arrayAppend( paramPairs, arguments.param &"="& encodedParams[ arguments.param ] );
		});
		
		// Finally, generate sorted list of parameters, delimited by "&"
		return arrayToList(paramPairs, "&");
	}
	
	
	/**
	 * Generates a list of signed header names. 
	 *
	 * <p>"...By adding this list of headers, you tell AWS which headers in the request 
	 * are part of the signing process and which ones AWS can ignore (for example, any 
	 * additional headers added by a proxy) for purposes of validating the request."</p>
	 *
	 * @requestHeaders Raw headers to be included in request
	 * @excludeNames Names of any headers AWS should ignore for the signing process
	 * @returns Sorted list of signed header names, delimited by semi-colon ";"
	 */
	private string function buildSignedHeaders(required struct requestHeaders, required array excludeNames ) {
		var name = "";
		var headerNames = [];
		var allHeaders = !arrayLen(arguments.excludeNames);
		
		// Identify which headers are "signed"
		structEach( arguments.requestHeaders, function(string name, any value) {
			if (allHeaders || !arrayFindNoCase( excludeNames, arguments.name)) {
				arrayAppend( headerNames, arguments.name );
			}
		});

		// Sort header names in ASCII order
		arraySort( headerNames, "text", "asc" );
		
		// Return list of names
		return arrayToList( headerNames, ";" );
	}
	
	/**
	 * Generates a list of canonical headers
	 * @requestHeaders Structure containing headers to be included in request hash
	 * @returns Sorted list of header pairs, delimited by new lines
	 */
	private string function buildCanonicalHeaders(required struct requestHeaders ) {
		var pairs = "";
		var names = "";
		var headers = "";
		
		// Scrub the header names and values first
		headers = cleanHeaders( arguments.requestHeaders );

		// Sort header names in ASCII order
		names = structKeyArray( headers );
		arraySort( names, "text", "asc" );
		
		// Build array of sorted header name and value pairs
		pairs = [];
		arrayEach( names, function(string key) {
			arrayAppend( pairs, arguments.key &":"& headers[ arguments.key ] );
		});
		
		// Generate list. Note: List must END WITH a new line character
		return arrayToList( pairs, chr(10)) & chr(10);
	}
	

	/**
	 * Generates canonical URI. Encoded, absolute path component of the URI, 
	 * which is everything in the URI from the HTTP host to the question mark character ("?") 
	 * that begins the query string parameters (if any)
	 * @uriPath URI or path. If empty, "/" will be used
	 * @returns URL encoded path
	 */
	private string function buildCanonicalURI(required string requestURI) {

		var path = arguments.requestURI;
		// Return "/" for empty path
		if (!len(trim(path))) {
			path = "/";
		}
		// Convert to absolute path (if needed)
		if (left(path, 1) != "/") {
			path = "/"& path;
		}

		// Encode path, but preserve slashes "/"
		path = replace( _urlEncode( path ), "%2F", "/", "all");

		return path;
	}
	
	
	/**
	 * Generates signing key for AWS Signature V4
	 * 
	 * <p>Source: http://stackoverflow.com/questions/32513197/how-to-derive-a-sign-in-key-for-aws-signature-version-4-in-coldfusion</p>
	 * 
	 * @dateStamp Date stamp in YYYYMMDD format. Example: 20150830
	 * @regionName 	Region name that is part of the service's endpoint (alphanumeric). Example: "us-east-1"
	 * @serviceName Service name that is part of the service's endpoint (alphanumeric). Example: "s3"
	 * @algorithm HMAC algorithm. Default is "HMACSHA256"
	 * @returns signing key in binary 
	*/
	private binary function generateSignatureKey(
		required string dateStamp
		, required string regionName 
		, required string serviceName 
		, string algorithm = "HMACSHA256"
	){
	
		var kSecret = charsetDecode("AWS4" & variables.secretKey, "UTF-8");
		var kDate = hmacBinary( arguments.dateStamp, kSecret  );
		// Region information as a lowercase alphanumeric string
		var kRegion = hmacBinary( lcase(arguments.regionName), kDate  );
		// Service name information as a lowercase alphanumeric string 
		var kService = hmacBinary( lcase(arguments.serviceName), kRegion  );
		// A special termination string: aws4_request
		var kSigning = hmacBinary( "aws4_request", kService  );

		return kSigning;
	}	
	

	/**
	*  Generates string indicating the scope for which the signature is valid. Credential scope 
	*  is represented by a slash-separated string of dimensions in the following order:
	*
	*         dateStamp / regionName / serviceName / terminationString
	*
	*  @dateStamp   - Current date in UTC (must be same as X-Amz-Date date). Format yyyyMMdd
	*  @regionName 	- Name of the target region, UTF-8 encoded. Example "us-east-1"
	*  @serviceName	- Name of the target service, UTF-8 encoded. Example "s3"
	*  @returns  	- formatted string. Example:  20150830/us-east-1/iam/aws4_request
	*/
	private string function buildCredentialScope(
		required string dateStamp
		, required string regionName 
		, required string serviceName 
	) {

		return arguments.dateStamp &"/"&  lcase(arguments.regionName) &"/"& lcase(arguments.serviceName) &"/"& "aws4_request";
	}
	
	/**
	*  Generates Authorization header string. 
	*
	*  Format:  algorithm + ' ' + 'Credential=' + access_key + '/' + credential_scope 
	*					+ ', ' +  'SignedHeaders=' + signed_headers + ', ' 
	*					+ 'Signature=' + signature
	*
	*  @dateStamp   - Current date in UTC (must be same as X-Amz-Date date). Format yyyyMMdd
	*  @regionName 	- Name of the target region, UTF-8 encoded. Example "us-east-1"
	*  @serviceName	- Name of the target service, UTF-8 encoded. Example "s3"
	*  @returns  	- formatted string. Example:  20150830/us-east-1/iam/aws4_request
	*/
	private string function buildAuthorizationHeader( 
		required struct requestHeaders
		, required string signedHeaders
		, required string credentialScope
		, required string signature 
	) {
		var authHeader = variables.signatureAlgorithm &" "
							& "Credential=" & variables.accessKey &"/"& arguments.credentialScope & ", "
							& "SignedHeaders=" & arguments.signedHeaders & ", " 
							& "Signature="& arguments.signature;
		return authHeader;
	}
	
	/**
	*  Generates string indicating the scope for which the signature is valid
	*
	*  @dateStamp   - Current date in UTC (must be same as X-Amz-Date date). Format yyyyMMdd
	*  @regionName 	- Name of the target region, UTF-8 encoded. Example "us-east-1"
	*  @serviceName	- Name of the target service, UTF-8 encoded. Example "s3"
	*  @returns  	- Credential header string. Example:  20150830/us-east-1/iam/aws4_request
	*/
	private string function buildCredentialString(
		required string dateStamp
		, required string regionName 
		, required string serviceName 
	){
		return variables.accessKey &"/"& buildCredentialScope( argumentCollection=arguments );
	}
	
	
	/**
	 * Convenience method which generates a (binary) HMAC code for the specified message
	 * 
	 * @message Message to sign
	 * @key HMAC key in binary form
	 * @algorithm Signing algorithm. [ Default is "HMACSHA256" ]
	 * @encoding Character encoding of message string. [ Default is UTF-8 ]
	 * @returns HMAC value for the specified message as binary (currently unsupported in CF11)
	*/
	private binary function hmacBinary (
		required string message 
		, required binary key 
		, string algorithm = "HMACSHA256"
		, string encoding = "UTF-8"
	){
		// Generate HMAC and decode result into binary
		return binaryDecode( HMAC( arguments.message, arguments.key, arguments.algorithm, arguments.encoding), "hex" );
	}	

	
	/**
	 * Convenience method that hashes the supplied value, with SHA256
	 * @text value to hash
	 * @returns hashed value, in lower case
	 */
	private string function hash256 ( required any text ){
		return lcase( hash(arguments.text, "SHA-256") );
	}	
	
	
	/**
	 * URL encode query parameters and names
	 * @params Structure containing all query parameters for the request
	 * @returns new structure with all parameter names and values encoded
	 */
	private struct function encodeQueryParams(required struct queryParams) {
		// First encode parameter names and values 
		var encodedParams = {};
		structEach( arguments.queryParams, function(string key, string value) {
			encodedParams[ _urlEncode(arguments.key) ] = _urlEncode( arguments.value );
		});	
		return encodedParams;
	}
	
	/**
	 * Scrubs header names and values:
	 * <ul>
	 *    <li>Removes leading and trailing spaces from names and values</li>
	 *	  <li>Converts sequential spaces to single space in names and values</li>
	 *	  <li>Converts all header names to lower case</li>
	 * </ul>
	 * @headers Header names and values to scrub
	 * @returns structure of parsed header names and values
	 */
	private struct function cleanHeaders(required struct headers) {
		var headerName  = "";
		var headerValue = "";
		var cleaned  = {};
		
		structEach( arguments.headers, function(string key, string value) {
			headerName  = cleanHeader( arguments.key );
			headerValue = cleanHeader( arguments.value );
			cleaned[ lcase( headerName ) ] = headerValue;
		});	
		
		return cleaned;
	}

	/**
	 * Scrubs header names and values:
	 * <ul>
	 *    <li>Removes leading and trailing spaces</li>
	 *	  <li>Converts sequential spaces to single space</li>
	 *	  <li>Converts all names to lower case</li>
	 * </ul>
	 * @headers Header names to scrub
	 * @returns array of parsed header names
	 */
	private array function cleanHeaderNames(required array names) {
		var headerName  = "";

		var cleaned  = [];
		arrayEach( names, function(string headerName) {
			arrayAppend( cleaned, cleanHeader( arguments.headerName ) );
		});		
		
		return cleaned;
	}
	

	/**
	 * Removes extraneous white space from header names or values.
	 * See http://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
	 *
	 * <ul>
	 *    <li>Removes leading and trailing spaces</li>
	 *	  <li>Converts sequential spaces to single space</li>
	 * </ul>
	 * @text Text to scrub
	 * @returns parsed text
	 */
	private string function cleanHeader(required string text) {
		return reReplace( trim( arguments.text ), "\s+", chr(32), "all" );
	}

	
	/**
	 * URL encodes the supplied string per RFC 3986, which defines the following as 
	 * unreserved characters that should NOT be encoded:
	 *
	 * A-Z, a-z, 0-9, hyphen ( - ), underscore ( _ ), period ( . ), and tilde ( ~ ). 
     *	 
	 * @value string to encode
	 * @returns URI encoded string
	 */
	private string function _urlEncode( string value ) {
		var encodedValue = encodeForURL(arguments.value);
		// Reverse encoding of tilde "~"
		encodedValue = replace( encodedValue, encodeForURL("~"), "~", "all" );
		// Fix encoding of spaces, ie replace '+' into "%20"
		encodedValue = replace( encodedValue, "+", "%20", "all" );
		// Asterisk "*" should be encoded
		encodedValue = replace( encodedValue, "*", "%2A", "all" );
		
		return encodedValue;
	}

	/**
	 * Returns current UTC date and time in the following formats:
	 *   - dateStamp - Current UTC date, format: YYYYMMDD
	 *   - timeStamp - Current UTC date and time, format: YYYYMMDDTHHnnssZ
	 * @returns structure containing date and time strings
	 */
	public struct function getUTCStrings() {
		var utcDateTime = dateConvert("local2UTC", now());
		var result = {};
		
		// Generate UTC time stamps 
		result.dateStamp = dateFormat( utcDateTime, "YYYYMMDD" );
		result.amzDate = result.dateStamp &"T"& timeFormat(utcDateTime, "HHnnssZ");
		result.timeStamp = dateFormat( utcDateTime, "YYYY-MM-DD") &"T"& timeFormat(utcDateTime, "HH:nn:ssZ");
		return result;
	}

}