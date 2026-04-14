package com.eosgrp.jdbc.core;

import com.eosgrp.jdbc.connection.ConnectionFactory;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

public class UpdateExecutor {

    public static int executeUpdate(String sql, Object... params) {
        try (Connection conn = ConnectionFactory.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            setParameters(stmt, params);
            return stmt.executeUpdate();

        } catch (SQLException e) {
            e.printStackTrace();
            return 0;
        }
    }

    private static void setParameters(PreparedStatement stmt, Object... params) throws SQLException {
        if (params == null) {
            return;
        }

        for (int i = 0; i < params.length; i++) {
            stmt.setObject(i + 1, params[i]);
        }
    }
}
