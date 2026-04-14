package com.eosgrp.jdbc.dao;

import com.eosgrp.jdbc.core.QueryExecutor;

import java.util.List;
import java.util.Map;

public class OrderDao {

    public List<Map<String, Object>> getAllOrders() {
        String sql = "SELECT TOP 10 * FROM Sales.[Order]";
        return QueryExecutor.executeQuery(sql);
    }

    public List<Map<String, Object>> getOrdersByCustomerId(int customerId) {
        String sql = "SELECT * FROM Sales.[Order] WHERE CustomerId = " + customerId;
        return QueryExecutor.executeQuery(sql);
    }

    public List<Map<String, Object>> getRecentOrders() {
        String sql = "SELECT TOP 10 * FROM Sales.[Order] ORDER BY OrderDate DESC";
        return QueryExecutor.executeQuery(sql);
    }
}
