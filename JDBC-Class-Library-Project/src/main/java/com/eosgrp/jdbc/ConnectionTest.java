package com.eosgrp.jdbc;

import com.eosgrp.jdbc.connection.ConnectionFactory;
import com.eosgrp.jdbc.util.JdbcExceptionHandler;

import java.sql.Connection;
import java.sql.SQLException;

public class ConnectionTest {

    public static void main(String[] args) {
        try (Connection connection = ConnectionFactory.getConnection()) {
            System.out.println("Connection successful!");
            System.out.println("Database Product: " + connection.getMetaData().getDatabaseProductName());
            System.out.println("Database Version: " + connection.getMetaData().getDatabaseProductVersion());
            System.out.println("Driver Name: " + connection.getMetaData().getDriverName());
            System.out.println("Driver Version: " + connection.getMetaData().getDriverVersion());
        } catch (SQLException e) {
            JdbcExceptionHandler.handle(e);
        }
    }
}
