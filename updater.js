var request = require('request');
var fs = require('fs');
var monetdb = require('monetdb');

var conn = monetdb.connect({host : 'localhost', dbname: 'hackathon', debug: false} , function(err) {
    if (err) console.log('connection failed' + err);
});



var dateboundary = new Date(2010, 1, 1, 0, 0, 0, 0);



function rq(opts) {
	request(opts,  function(error, response, body) {
		if (error || response.statusCode != 200) {
		 	console.log(error);
		 	console.log(response.statusCode);
		 	return;
		}
		var ct = true;
	 	body.data.forEach(function(v) {
	 		if (!v.message || !ct) return;
	 		var lasttime = v.created_time;
	 		if (lasttime <= maxts) {
	 			console.log("stopping at " + lasttime);
	 			ct = false;
	 			conn.disconnect();

	 			return;
	 		} 
	 		var line = v.id + '\t' + v.created_time + '\t' + v.message.replace(/\t/g, " ").replace(/\n/g, " ") + '\n';
	 		conn.query("INSERT INTO klmrants VALUES(?,?,?)", [v.id, v.created_time, line]);
	 		//fs.appendFile('klmrants.tsv', line, function (err) {if (err) console.log(err)});
	 	});
	 	var lastdate = new Date(body.data[body.data.length-1].created_time);
	 	if (lastdate && lastdate > dateboundary && ct) {
	 		rq({url:body.paging.next, json:true, method: 'GET'});
	 	}
	});
}

var maxts = "";

conn.query('SELECT max(tsstr) from klmrants', function(err, res) {
    if (err) {
    	console.log(err);
    	return;
    }
    maxts = res.data[0][0];
	rq({
		url: 'https://graph.facebook.com/v2.0/KLM/feed', 
		method: 'GET',  
		qs: {access_token:'1723829011184661|Ky02TAkL0tKoh4iiMneJSsFGq5o'}, 
		json: true
	});
});


// appid 1723829011184661
// appsecret 111f8f6c2a15097344a137c63ff57738


//  /oauth/access_token?
//      client_id={app-id}
//     &client_secret={app-secret}
//     &grant_type=client_credentials

// https://graph.facebook.com//oauth/access_token?client_id=1723829011184661&client_secret=111f8f6c2a15097344a137c63ff57738&grant_type=client_credentials

// access_token=1723829011184661|Ky02TAkL0tKoh4iiMneJSsFGq5o


// https://graph.facebook.com/v2.0/KLM/feed?access_token=1723829011184661|Ky02TAkL0tKoh4iiMneJSsFGq5o

 // 5mins judges

