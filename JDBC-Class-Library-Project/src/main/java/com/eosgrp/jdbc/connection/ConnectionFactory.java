package com.eosgrp.jdbc.connection;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import com.eosgrp.jdbc.config.DbConfig;

public class ConnectionFactory {

    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(
            DbConfig.URL,
            DbConfig.USER,
            DbConfig.PASSWORD
        );
    }
}
