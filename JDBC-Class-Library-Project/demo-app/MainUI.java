package com.eosgrp.jdbc.ui;

import javax.swing.SwingUtilities;

public class MainUI {
    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> {
            DashboardUI dashboard = new DashboardUI();
            dashboard.setVisible(true);
        });
    }
}
