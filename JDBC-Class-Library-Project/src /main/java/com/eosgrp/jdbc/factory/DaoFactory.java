package com.eosgrp.jdbc.factory;

import com.eosgrp.jdbc.dao.*;

public class DaoFactory {

    public static CustomerDao getCustomerDao() {
        return new CustomerDao();
    }

    public static OrderDao getOrderDao() {
        return new OrderDao();
    }

    public static ProductDao getProductDao() {
        return new ProductDao();
    }
}
