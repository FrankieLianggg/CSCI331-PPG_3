package com.eosgrp.jdbc;

import com.eosgrp.jdbc.connection.ConnectionFactory;

import java.sql.Connection;
import java.sql.SQLException;

public class ConnectionTest {

    public static void main(String[] args) {
        try (Connection connection = ConnectionFactory.getConnection()) {
            if (connection != null && !connection.isClosed()) {
                System.out.println("Connection successful!");
                System.out.println("Database Product: " + connection.getMetaData().getDatabaseProductName());
                System.out.println("Database Version: " + connection.getMetaData().getDatabaseProductVersion());
                System.out.println("Driver Name: " + connection.getMetaData().getDriverName());
                System.out.println("Driver Version: " + connection.getMetaData().getDriverVersion());
            } else {
                System.out.println("Connection failed.");
            }
        } catch (SQLException e) {
            System.err.println("Unable to connect to the database.");
            e.printStackTrace();
        }
    }
}
