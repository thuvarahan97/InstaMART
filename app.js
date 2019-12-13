// module dependencies.
var express=require("express");
var session = require('express-session');
var bodyParser = require('body-parser');
var routes = require('./routes');
var user = require('./routes/user');
var checkout = require('./routes/checkout');
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
    res.locals.loggedin = req.session.loggedin;
    res.locals.user_id = req.session.user_id;
    res.locals.username = req.session.username;
    next();
})

// all routes
app.get('/', routes.index);                 //call for main index page
app.get('/signup', user.signup);            //call for signup page
app.post('/signup', user.signup);           //call for signup post
app.get('/login', user.login);              //call for login page
app.post('/login', user.login);             //call for login post
app.get('/user/logout', user.logout);       //call for logout
app.get('/checkout', checkout.checkout);    //call for checkout page

app.listen(8080);