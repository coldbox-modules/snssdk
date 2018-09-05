component extends="coldbox.system.testing.BaseTestCase" appMapping="root"{

	/*********************************** LIFE CYCLE Methods ***********************************/

	function beforeAll(){
		super.beforeAll();
	}

	function afterAll(){
		super.afterAll();
	}

/*********************************** BDD SUITES ***********************************/

	function run(){

		describe( "SNS SDK", function(){

			beforeEach(function( currentSpec ){
				setup();
			});

			it( "can load the module", function(){
				var sdk = getInstance( "AmazonSNS@snssdk" );
				expect( sdk ).toBeComponent();
			});

		});

	}

}