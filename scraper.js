var request = require('request');
var fs = require('fs');

function rq(opts) {
	request(opts,  function(error, response, body) {
		if (error || response.statusCode != 200) {
		 	console.log(error);
		 	console.log(response.statusCode);
		 	return;
		}
		var stop = false;
	 	body.data.forEach(function(v){
	 		if (!v.message || stop) return;
	 		if (v.created_time <= '2015-10-31T08:13:38+0000') {
	 			stop = true;
	 			return;
	 		}
	 		var line = v.id + '\t' + v.created_time + '\t' + v.message.replace(/\t/g, " ").replace(/\n/g, " ") + '\n';
	 		fs.appendFile('klmrants-new.tsv', line, function (err) {if (err) console.log(err)});
	 	});
	 	var lastdate = new Date(body.data[body.data.length-1].created_time);
	 	if (!stop) {
	 		rq({url:body.paging.next, json:true, method: 'GET'});
	 	}
	});
}

rq({
	url: 'https://graph.facebook.com/v2.0/KLM/feed', 
	method: 'GET',  
	qs: {access_token:'1723829011184661|Ky02TAkL0tKoh4iiMneJSsFGq5o'}, 
	json: true
})


// appid 1723829011184661
// appsecret 111f8f6c2a15097344a137c63ff57738


//  /oauth/access_token?
//      client_id={app-id}
//     &client_secret={app-secret}
//     &grant_type=client_credentials

// https://graph.facebook.com//oauth/access_token?client_id=1723829011184661&client_secret=111f8f6c2a15097344a137c63ff57738&grant_type=client_credentials

// access_token=1723829011184661|Ky02TAkL0tKoh4iiMneJSsFGq5o


// https://graph.facebook.com/v2.0/KLM/feed?access_token=1723829011184661|Ky02TAkL0tKoh4iiMneJSsFGq5o


