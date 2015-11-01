var static = require('node-static');
var monetdb = require('monetdb');
var url = require('url');

var conn = monetdb.connect({host : 'localhost', dbname: 'hackathon', debug: false} , function(err) {
    if (err) console.log('connection failed' + err);
});

// static content/query callback web server
var app = require('http').createServer(function (req, resp) {
	var u = url.parse(req.url, true);
	if (u.query.d) {
		conn.query('select id, tsstr, txt from dd2 where date=\''  + u.query.d + '\' and '+ u.query.c +' order by tsstr desc;', function(err, res) {
		    if (err)  {
		    	console.log(err);
		    	return;
		    }
			resp.writeHead(200, {"Content-Type": "application/json; charset=utf-8"});
			resp.end(JSON.stringify(res));
		});
		return;
	}
	if (u.query.f) {
		conn.query('select odest, count(*) as n from dd2 left join dd4 using(id) where odest is not null and '+ u.query.f +'  group by odest order by n desc limit 5;', function(err, res) {
		    if (err)  {
		    	console.log(err);
		    	return;
		    }
			resp.writeHead(200, {"Content-Type": "application/json; charset=utf-8"});
			resp.end(JSON.stringify(res));
		});
		return;
	}
	if (u.query.o) {
		conn.query('select dt, sum(lostbag) as lostbag, sum(overbook) as overbook, sum(cancelled) as cancelled from regex group by dt order by dt;', function(err, res) {
		    if (err)  {
		    	console.log(err);
		    	return;
		    }
		    ret = [];
		    res.data.forEach(function(r) {
		    	ret.push({date:r[0], lostbag:parseInt(r[1]), overbook : parseInt(r[2]), cancelled: parseInt(r[3])});
		    });
			resp.writeHead(200, {"Content-Type": "application/json; charset=utf-8"});
			resp.end(JSON.stringify(ret));
		});
		return;
	}





	file.serve(req, resp);
});

var file = new static.Server(__dirname + '/public');
app.listen(8000);


