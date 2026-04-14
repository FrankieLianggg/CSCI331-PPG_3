package com.eosgrp.jdbc.dao;

import com.eosgrp.jdbc.core.QueryExecutor;

import java.util.List;
import java.util.Map;

public class ProductDao {

    public List<Map<String, Object>> getAllProducts() {
        String sql = "SELECT TOP 10 * FROM Production.Product";
        return QueryExecutor.executeQuery(sql);
    }

    public List<Map<String, Object>> getProductsBySupplierId(int supplierId) {
        String sql = "SELECT * FROM Production.Product WHERE SupplierId = " + supplierId;
        return QueryExecutor.executeQuery(sql);
    }

    public List<Map<String, Object>> getProductsInStock() {
        String sql = "SELECT * FROM Production.Product WHERE UnitsInStock > 0";
        return QueryExecutor.executeQuery(sql);
    }
}
