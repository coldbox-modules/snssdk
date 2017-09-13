[![Build Status](https://travis-ci.org/coldbox-modules/snssdk.svg?branch=master)](https://travis-ci.org/coldbox-modules/snssdk)

# Welcome to the Amazon SNS SDK

This SDK allows you to add Amazon SNS capabilities to your ColdFusion (CFML) applications. It is also a ColdBox Module, so if you are using ColdBox, you get auto-registration and much more.

## Resources

* Source: https://github.com/coldbox-modules/snssdk
* Issues: https://github.com/coldbox-modules/snssdk/issues
* [Changelog](changelog.md)
* SNS API Reference: http://docs.aws.amazon.com/sns/latest/dg/welcome.html

## Installation 
This SDK can be installed as standalone or as a ColdBox Module.  Either approach requires a simple CommandBox command:

```
box install snssdk
```

Then follow either the standalone or module instructions below.

### Standalone

This SDK will be installed into a directory called `snssdk` and then the SDK can be instantiated via ` new snssdk.AmazonSNS()` with the following constructor arguments:

```
<cfargument name="accessKey" 			required="true">
<cfargument name="secretKey" 			required="true">
<cfargument name="encryption_charset" 	required="false" default="utf-8">
<cfargument name="ssl" 					required="false" default="false">
```

### ColdBox Module

This package also is a ColdBox module as well.  The module can be configured by creating an `snssdk` configuration structure in your application configuration file: `config/Coldbox.cfc` with the following settings:

```
snssdk = {
	// Your amazon access key
	accessKey = "",
	// Your amazon secret key
	secretKey = "",
	// The default encryption character set
	encryption_charset = "utf-8",
	// SSL mode or not on cfhttp calls.
	ssl = false
};
```

Then you can leverage the SDK CFC via the injection DSL: `AmazonSNS@snssdk`

## Usage

Please check out the included API Docs to see all the methods available to you using our SNS SDK.