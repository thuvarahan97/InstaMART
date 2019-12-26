var connection = require('./../config');

exports.viewCart = function(req, res){
    var mode = 'signup';
    var output = 'error';
    var message = '';
    
    if(req.method == "POST"){

    }
    else {
        if (req.session.loggedin) {
            // res.render('checkout.ejs',{mode: mode, output: output, message: message});
        }
        else {
            connection.query('SELECT * FROM view_cart_items WHERE customer_id=?', '0000000086', function (error, result, fields) {
                if (error) {
                    message = "Error occured! Try again.";
                    // res.render('cart.ejs',{mode: mode, output: output, message: message});
                }
                else {
                    res.render('cart.ejs',{result:result});
                }
            });
        }
    }
};


exports.changeQuantity = function(req, res){
    var sku = req.body.sku;
    var quantity = req.body.quantity;
    connection.query('UPDATE view_cart_items SET quantity=? WHERE customer_id=? AND sku=?', [quantity, '0000000086', sku], function (error, result, fields) {
        if (error) {
            res.send({result:'failed'});
        }
        else {
            res.send({result:'success'});
        }
    });
}

exports.deleteCartItem = function(req, res){
    var sku = req.body.sku;
    connection.query('UPDATE tbl_carts SET item_status=? WHERE customer_id=? AND sku=?', ['removed', '0000000086', sku], function (error, result, fields) {
        if (error) {
            res.send({result:'failed'});
        }
        else {
            res.send({result:'success'});
        }
    });
}