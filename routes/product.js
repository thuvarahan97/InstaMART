var connection = require('./../config');

exports.getAllProducts = function(req, res) {
    if (typeof req.query.category_id != 'undefined') {
        var category_id = req.query.category_id;
        connection.query('SELECT category_id, category_name, product_id, product_name, min_price, max_price, product_image FROM (SELECT * FROM tbl_products NATURAL JOIN tbl_product_categories NATURAL JOIN tbl_categories) AS A NATURAL JOIN (SELECT product_id, MIN(unit_price) AS min_price, MAX(unit_price) AS max_price FROM tbl_product_variants GROUP BY product_id) AS B WHERE category_id = ? ORDER BY product_name', category_id, function (error, result, fields) {
            if (error) {
                res.render('products.ejs', {});
            }
            else {
                res.render('products.ejs', {result:result});
            }
        });
    }

    if (typeof req.query.product_brand != 'undefined') {
        var product_brand = req.query.product_brand;
        connection.query('SELECT product_id, product_name, min_price, max_price, product_image FROM tbl_products NATURAL JOIN (SELECT product_id, MIN(unit_price) AS min_price, MAX(unit_price) AS max_price FROM tbl_product_variants GROUP BY product_id) AS B WHERE product_brand = ? ORDER BY product_name', product_brand, function (error, result, fields) {
            if (error) {
                res.render('products.ejs', {});
            }
            else {
                res.render('products.ejs', {result:result});
            }
        });
    }

    if (typeof req.query.search != 'undefined') {
        var search = req.query.search;
        connection.query('SELECT product_id, product_name, min_price, max_price, product_image FROM tbl_products NATURAL JOIN (SELECT product_id, MIN(unit_price) AS min_price, MAX(unit_price) AS max_price FROM tbl_product_variants GROUP BY product_id) AS B WHERE product_name like "%' + search + '%"', function (error, result, fields) {
            if (error) {
                res.render('products.ejs', {});
            }
            else {
                res.render('products.ejs', {result:result});
            }
        });
    }
}

exports.getSingleProduct = function(req, res) {
    var product_id = req.query.product_id;
    connection.query('SELECT * FROM tbl_products NATURAL JOIN (SELECT product_id, MIN(unit_price) AS min_price, MAX(unit_price) AS max_price FROM tbl_product_variants GROUP BY product_id) AS B WHERE product_id = ?', product_id, function (error, result, fields) {
        if (error) {
            res.render('product-details.ejs', {});
        }
        else {
            res.render('product-details.ejs', {result:result});
        }
    });
}

exports.getSingleProductVariants = function(req, res) {
    var product_id = req.body.product_id;
    connection.query('SELECT A.*, GROUP_CONCAT(B.attribute_name) AS attribute_names, GROUP_CONCAT(B.attribute_value) AS attribute_values FROM tbl_product_variants A NATURAL JOIN tbl_product_variant_details B WHERE product_id = ? GROUP BY sku ORDER BY sku ASC', product_id, function (error, result, fields) {
        if (error) {
            res.send({});
        }
        else {
            res.send({result:result});
        }
    });
}

exports.addToCart = function(req, res) {
    var sku = req.body.product_variant;
    var quantity = req.body.quantity;
    
    var customer_id = '';
    if (req.session.customer_id != '' && req.session.customer_id != null) {
        customer_id = req.session.customer_id;
        
        connection.query('INSERT INTO tbl_carts (customer_id, sku, quantity, date_added, item_status) VALUES (?,?,?,NOW(),?) ON DUPLICATE KEY UPDATE quantity = ?, date_added = NOW()', [customer_id, sku, quantity, 'added', quantity], function (error, result, fields) {
            if (error) {
                res.redirect('/');
            }
            else {
                res.redirect('/cart');
            }
        });
    }
    else {
        connection.query('INSERT INTO tbl_customers (customer_type) VALUES (?); SELECT LAST_INSERT_ID() AS customer_id;', 'guest', function (error, result, fields) {
            if (error) {
                res.redirect('/');
            }
            else {
                req.session.customer_id = result[1][0]['customer_id'];
                customer_id = req.session.customer_id;

                connection.query('INSERT INTO tbl_carts (customer_id, sku, quantity, date_added, item_status) VALUES (?,?,?,NOW(),?)', [customer_id, sku, quantity, 'added'], function (error, result, fields) {
                    if (error) {
                        res.redirect('/');
                    }
                    else {
                        res.redirect('/cart');
                    }
                });
            }
        });
    }
    
}