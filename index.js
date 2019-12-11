var express=require("express");
var bodyParser=require('body-parser');
var app = express();

var authenticateController = require('./controllers/authenticate-controller');
var registerController = require('./controllers/register-controller');

app.use(bodyParser.urlencoded({extended:true}));
app.use(bodyParser.json());

app.use(express.static(__dirname + '/public'));

// app.get('/', function (req, res) {
//     res.sendFile( __dirname + "/public/" + "index.html" );  
// });

// app.get('/public/', function (req, res) {
//     res.sendFile( __dirname + "/public/" + "index.html" );  
// });

app.get('/login/', function (req, res) {
    res.sendFile( __dirname + "/public/" + "login.html" );  
});

/* route to handle login and registration */
app.post('/api/register',registerController.register);
app.post('/api/authenticate',authenticateController.authenticate);

app.post('/controllers/register-controller', registerController.register);
app.post('/controllers/authenticate-controller', authenticateController.authenticate);

app.listen(8012);