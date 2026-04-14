package com.eosgrp.jdbc.util;

import java.sql.SQLException;

public class JdbcExceptionHandler {

    public static void handle(SQLException e) {
        System.err.println("JDBC Error Message: " + e.getMessage());
        System.err.println("SQL State: " + e.getSQLState());
        System.err.println("Error Code: " + e.getErrorCode());

        Throwable cause = e.getCause();
        if (cause != null) {
            System.err.println("Cause: " + cause.getMessage());
        }

        e.printStackTrace();
    }

    public static RuntimeException wrap(SQLException e) {
        handle(e);
        return new RuntimeException("Database operation failed.", e);
    }
}
