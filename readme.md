[![Build Status](https://travis-ci.org/coldbox-modules/snssdk.svg?branch=development)](https://travis-ci.org/coldbox-modules/snssdk)

# Welcome to the Amazon SNS SDK

This SDK allows you to add Amazon SNS capabilities to your ColdFusion (CFML) applications. It is also a ColdBox Module, so if you are using ColdBox, you get auto-registration and much more.

## Resources

* Source: https://github.com/coldbox-modules/snssdk
* Issues: https://github.com/coldbox-modules/snssdk/issues
* [Changelog](changelog.md)
* API Docs: https://apidocs.ortussolutions.com/#/coldbox-modules/snssdk/
* SNS API Reference: http://docs.aws.amazon.com/sns/latest/dg/welcome.html

## Installation 

This SDK can be installed as standalone or as a ColdBox Module.  Either approach requires a simple CommandBox command:

```
box install snssdk
```

Then follow either the standalone or module instructions below.

### Standalone

This SDK will be installed into a directory called `snssdk` and then the SDK can be instantiated via ` new snssdk.models.AmazonSNS()` with the following constructor arguments:

```html
<cfargument name="accessKey" 			required="true">
<cfargument name="secretKey" 			required="true">
<cfargument name="encryption_charset" 	required="false" default="utf-8">
<cfargument name="ssl" 					required="false" default="false">
<cfargument name="defaultRegionName		required="false" default="us-east-1",
<cfargument name="defaultServiceName 	required="false" default="sns",
<cfargument name="signatureAlgorithm 	required="false" default="AWS4-HMAC-SHA256",
<cfargument name="hashAlorithm 			required="false" default="SHA256"
```

### ColdBox Module

This package also is a ColdBox module as well.  The module can be configured by creating a `snssdk` structure in the `variables.moduleSettings` configuration area of your `config/ColdBox.cfc` with the following settings:

```js
snssdk = {
	// Your amazon access key
	accessKey = "",
	// Your amazon secret key
	secretKey = "",
	// The default encryption character set
	encryption_charset = "utf-8",
	// SSL mode or not on cfhttp calls.
	ssl = false
	defaultRegionName = "us-east-1",
	defaultServiceName = "sns",
	signatureAlgorithm = "AWS4-HMAC-SHA256",
	hashAlorithm = "SHA256"
};
```

Then you can leverage the SDK CFC via the WireBox ID: `AmazonSNS@snssdk`

## Usage

Please check out the included API Docs to see all the methods available to you using our SNS SDK or visit them online at https://apidocs.ortussolutions.com/#/coldbox-modules/snssdk/