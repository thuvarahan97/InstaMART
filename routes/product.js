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
    connection.query('SELECT product_id, product_name, min_price, max_price, product_image FROM tbl_products NATURAL JOIN (SELECT product_id, MIN(unit_price) AS min_price, MAX(unit_price) AS max_price FROM tbl_product_variants GROUP BY product_id) AS B WHERE product_name like "%' + search + '%"', function (error, result, fields) {
        if (error) {
            res.render('products.ejs', {});
        }
        else {
            res.render('products.ejs', {result:result});
        }
    });
}