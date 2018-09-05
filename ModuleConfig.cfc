/**
 * Copyright Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * This module connects your application to Amazon SNS
 **/
component {

	// Module Properties
	this.title 				= "Amazon SNS SDK";
	this.author 			= "Ortus Solutions, Corp";
	this.webURL 			= "https://www.ortussolutions.com";
	this.description 		= "This SDK will provide you with Amazon SNS connectivity for any ColdFusion (CFML) application.";
	this.autoMapModels		= false;

	/**
	 * Configure
	 */
	function configure(){

		// Settings
		variables.settings = {
			accessKey          = "",
			secretKey          = "",
			encryption_charset = "utf-8",
			ssl                = false,
			defaultRegionName  = "us-east-1",
			defaultServiceName = "sns",
			signatureAlgorithm = "AWS4-HMAC-SHA256",
			hashAlorithm       = "SHA256"
		};
	}

	/**
	* Fired when the module is registered and activated.
	*/
	function onLoad(){
		var snsSettings = controller.getSetting( "moduleSettings" ).snssdk;

		// Map Akismet Library
		binder.map( "AmazonSNS@snssdk" )
			.to( "#moduleMapping#.models.AmazonSNS" )
			.initArg( name="accessKey", 			value=snsSettings.accessKey )
			.initArg( name="secretKey", 			value=snsSettings.secretKey )
			.initArg( name="encryption_charset", 	value=snsSettings.encryption_charset )
			.initArg( name="ssl", 					value=snsSettings.ssl )
			.initArg( name="defaultRegionName", 	value=snsSettings.defaultRegionName )
			.initArg( name="defaultServiceName", 	value=snsSettings.defaultServiceName )
			.initArg( name="encryption_charset", 	value=snsSettings.encryption_charset );
	}

	/**
	* Fired when the module is unregistered and unloaded
	*/
	function onUnload(){
	}

}
