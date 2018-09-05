component{

	property name="snsSDK" inject="AmazonSNS@snssdk";

	function index( event, rc, prc ){
		return "SNS SDK";
	}

}