# Architecture

This project follows a layered architecture:

- Config Layer: Handles database configuration
- Connection Layer: Creates JDBC connections
- Core Layer: Executes SQL queries and transactions
- DAO Layer: Encapsulates database operations
- Factory Layer: Uses Abstract Factory pattern to create DAOs
- Model Layer: Represents database entities
- UI Layer: Provides user interaction

Data Flow:
UI → DAO → Core → JDBC → Database
