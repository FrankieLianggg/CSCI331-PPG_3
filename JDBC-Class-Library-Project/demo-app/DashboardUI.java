package com.eosgrp.jdbc.ui;

import com.eosgrp.jdbc.dao.CustomerDao;
import com.eosgrp.jdbc.dao.OrderDao;
import com.eosgrp.jdbc.dao.ProductDao;
import com.eosgrp.jdbc.factory.DaoFactory;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.util.List;
import java.util.Map;
import java.util.Vector;

public class DashboardUI extends JFrame {

    private final JTextArea statusArea;
    private final JTable resultTable;
    private final DefaultTableModel tableModel;

    public DashboardUI() {
        setTitle("JDBC Class Library Dashboard");
        setSize(900, 600);
        setLocationRelativeTo(null);
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setLayout(new BorderLayout(10, 10));

        JLabel titleLabel = new JLabel("JDBC Class Library Dashboard", SwingConstants.CENTER);
        titleLabel.setFont(new Font("Arial", Font.BOLD, 22));
        add(titleLabel, BorderLayout.NORTH);

        JPanel buttonPanel = new JPanel(new FlowLayout(FlowLayout.CENTER, 15, 10));

        JButton loadCustomersButton = new JButton("Load Customers");
        JButton loadOrdersButton = new JButton("Load Orders");
        JButton loadProductsButton = new JButton("Load Products");
        JButton clearButton = new JButton("Clear");

        buttonPanel.add(loadCustomersButton);
        buttonPanel.add(loadOrdersButton);
        buttonPanel.add(loadProductsButton);
        buttonPanel.add(clearButton);

        add(buttonPanel, BorderLayout.SOUTH);

        tableModel = new DefaultTableModel();
        resultTable = new JTable(tableModel);
        JScrollPane tableScrollPane = new JScrollPane(resultTable);

        statusArea = new JTextArea(6, 30);
        statusArea.setEditable(false);
        statusArea.setLineWrap(true);
        statusArea.setWrapStyleWord(true);
        JScrollPane statusScrollPane = new JScrollPane(statusArea);

        JSplitPane splitPane = new JSplitPane(JSplitPane.VERTICAL_SPLIT, tableScrollPane, statusScrollPane);
        splitPane.setDividerLocation(400);
        add(splitPane, BorderLayout.CENTER);

        loadCustomersButton.addActionListener(e -> loadCustomers());
        loadOrdersButton.addActionListener(e -> loadOrders());
        loadProductsButton.addActionListener(e -> loadProducts());
        clearButton.addActionListener(e -> clearDisplay());
    }

    private void loadCustomers() {
        try {
            CustomerDao customerDao = DaoFactory.getCustomerDao();
            List<Map<String, Object>> data = customerDao.getAllCustomers();
            displayResults(data);
            statusArea.setText("Customers loaded successfully. Rows returned: " + data.size());
        } catch (Exception e) {
            statusArea.setText("Error loading customers: " + e.getMessage());
            e.printStackTrace();
        }
    }

    private void loadOrders() {
        try {
            OrderDao orderDao = DaoFactory.getOrderDao();
            List<Map<String, Object>> data = orderDao.getAllOrders();
            displayResults(data);
            statusArea.setText("Orders loaded successfully. Rows returned: " + data.size());
        } catch (Exception e) {
            statusArea.setText("Error loading orders: " + e.getMessage());
            e.printStackTrace();
        }
    }

    private void loadProducts() {
        try {
            ProductDao productDao = DaoFactory.getProductDao();
            List<Map<String, Object>> data = productDao.getAllProducts();
            displayResults(data);
            statusArea.setText("Products loaded successfully. Rows returned: " + data.size());
        } catch (Exception e) {
            statusArea.setText("Error loading products: " + e.getMessage());
            e.printStackTrace();
        }
    }

    private void clearDisplay() {
        tableModel.setRowCount(0);
        tableModel.setColumnCount(0);
        statusArea.setText("Display cleared.");
    }

    private void displayResults(List<Map<String, Object>> results) {
        tableModel.setRowCount(0);
        tableModel.setColumnCount(0);

        if (results == null || results.isEmpty()) {
            statusArea.setText("No data returned.");
            return;
        }

        Map<String, Object> firstRow = results.get(0);
        Vector<String> columnNames = new Vector<>(firstRow.keySet());
        tableModel.setColumnIdentifiers(columnNames);

        for (Map<String, Object> row : results) {
            Vector<Object> rowData = new Vector<>();
            for (String column : columnNames) {
                rowData.add(row.get(column));
            }
            tableModel.addRow(rowData);
        }
    }
}
