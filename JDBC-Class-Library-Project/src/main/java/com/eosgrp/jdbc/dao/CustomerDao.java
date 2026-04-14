package com.eosgrp.jdbc.dao;

import com.eosgrp.jdbc.core.QueryExecutor;
import java.util.*;

public class CustomerDao {

    public List<Map<String, Object>> getAllCustomers() {
        String sql = "SELECT TOP 10 * FROM Sales.Customer";
        return QueryExecutor.executeQuery(sql);
    }
}
