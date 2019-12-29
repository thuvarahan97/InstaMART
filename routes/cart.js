var connection = require('./../config');

exports.viewCart = function(req, res){
    if (req.session.loggedin) {
        connection.query('SELECT * FROM view_cart_items WHERE customer_id=?', req.session.customer_id, function (error, result, fields) {
            if (error) {
                message = "Error occured! Try again.";
                // res.render('cart.ejs',{mode: mode, output: output, message: message});
            }
            else {
                res.render('cart.ejs',{result:result});
            }
        });
    }
    else {
        connection.query('SELECT * FROM view_cart_items WHERE customer_id=?', req.session.customer_id, function (error, result, fields) {
            if (error) {
                message = "Error occured! Try again.";
                // res.render('cart.ejs',{mode: mode, output: output, message: message});
            }
            else {
                res.render('cart.ejs',{result:result});
            }
        });
    }
};


exports.changeQuantity = function(req, res){
    var sku = req.body.sku;
    var quantity = req.body.quantity;
    connection.query('UPDATE view_cart_items SET quantity=? WHERE customer_id=? AND sku=?', [quantity, req.session.customer_id, sku], function (error, result, fields) {
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
    connection.query('UPDATE tbl_carts SET item_status=? WHERE customer_id=? AND sku=?', ['removed', req.session.customer_id, sku], function (error, result, fields) {
        if (error) {
            res.send({result:'failed'});
        }
        else {
            res.send({result:'success'});
        }
    });
}