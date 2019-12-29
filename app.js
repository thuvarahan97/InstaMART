// module dependencies.
var express=require("express");
var session = require('express-session');
var bodyParser = require('body-parser');
var routes = require('./routes');
var user = require('./routes/user');
var cart = require('./routes/cart');
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
    saveUninitialized: false,
    cookie: {
        maxAge: 24 * 60 * 60 * 1000
    }
}));

app.use(function (req, res, next) {
    // if (req.session.loggedin) {
    //     req.session.cart_count = 0;
    //     connection.query('SELECT COUNT(*) AS count FROM view_cart_items WHERE customer_id=?', req.session.customer_id, function (error, result, fields) {
    //         if (!error) {
    //             req.session.cart_count = result[0]['count'];
    //             res.locals.cart_count = req.session.cart_count;
    //         }
    //    });
    // }
    if (!req.session.loggedin && req.session.customer_id==null) {
        req.session.customer_id = '';
    }
    res.locals.loggedin = req.session.loggedin;
    res.locals.customer_id = req.session.customer_id;
    res.locals.username = req.session.username;
    // res.locals.cart_count = req.session.cart_count;
    next();
});

// all routes
app.get('/', routes.index);                         //call for main index page
app.get('/signup', user.signup);                    //call for signup page
app.post('/signup', user.signup);                   //call for signup post
app.get('/login', user.login);                      //call for login page
app.post('/login', user.login);                     //call for login post
app.get('/user/logout', user.logout);               //call for logout
app.get('/cart', cart.viewCart);                    //call for cart page
app.get('/checkout', checkout.viewCheckout);        //call for checkout page
app.post('/checkout', checkout.viewCheckout);       //call for checkout page
app.get('/payment', checkout.confirmPayment);       //call for payment page
app.post('/payment', checkout.confirmPayment);      //call for payment page

app.post('/changeQuantity', cart.changeQuantity);   //Change quantity of cart item
app.post('/deleteCartItem', cart.deleteCartItem);   //Remove cart item

app.listen(8080);