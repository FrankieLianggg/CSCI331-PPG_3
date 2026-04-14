package com.eosgrp.jdbc.core;

import com.eosgrp.jdbc.connection.ConnectionFactory;

import java.sql.Connection;
import java.sql.SQLException;

public class TransactionManager {

    private Connection connection;

    public void beginTransaction() throws SQLException {
        connection = ConnectionFactory.getConnection();
        connection.setAutoCommit(false);
    }

    public Connection getConnection() {
        return connection;
    }

    public void commit() throws SQLException {
        if (connection != null) {
            connection.commit();
            connection.setAutoCommit(true);
            connection.close();
            connection = null;
        }
    }

    public void rollback() {
        if (connection != null) {
            try {
                connection.rollback();
                connection.setAutoCommit(true);
                connection.close();
            } catch (SQLException e) {
                e.printStackTrace();
            } finally {
                connection = null;
            }
        }
    }
}
