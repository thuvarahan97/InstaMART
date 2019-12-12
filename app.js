// module dependencies.
var express=require("express");
var session = require('express-session');
var bodyParser = require('body-parser');
var routes = require('./routes');
var user = require('./routes/user');
var http = require('http');
var path = require('path');
var app = express();

//all environments
app.set('port', process.env.PORT || 8080);
app.set('views', __dirname + '/views');
app.set('view engine', 'ejs');
app.use(bodyParser.urlencoded({extended:false}));
app.use(bodyParser.json());
app.use(express.static(path.join(__dirname, 'public')));
app.use(session({
	secret: 'InstaMART2019',
	resave: false,
    saveUninitialized: true
}));

app.use(function (req, res, next) {
    res.locals.isLoggedIn = req.session.loggedin;
    next();
})

// app.get('/login/', function(req, res) {
// 	if (req.session.loggedin) {
// 		res.redirect('/');
// 	} else {
// 		res.sendFile( __dirname + "/public/" + "login.html" ); 
// 	}
// });

// routes
app.get('/', routes.index);//call for main index page
app.get('/signup', user.signup);//call for signup page
app.post('/signup', user.signup);//call for signup post 
app.get('/login', user.login);//call for login page
app.post('/login', user.login);//call for login post
app.get('/user/logout', user.logout);//call for logout

app.listen(8080);