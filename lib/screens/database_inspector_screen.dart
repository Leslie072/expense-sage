import 'package:flutter/material.dart';
import 'package:expense_sage/helpers/db.helper.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseInspectorScreen extends StatefulWidget {
  const DatabaseInspectorScreen({super.key});

  @override
  State<DatabaseInspectorScreen> createState() => _DatabaseInspectorScreenState();
}

class _DatabaseInspectorScreenState extends State<DatabaseInspectorScreen> {
  List<String> _tables = [];
  String? _selectedTable;
  List<Map<String, dynamic>> _tableData = [];
  List<Map<String, dynamic>> _tableSchema = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    setState(() => _isLoading = true);
    try {
      final db = await getDBInstance();
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
      );
      
      setState(() {
        _tables = result.map((row) => row['name'] as String).toList();
      });
    } catch (e) {
      _showError('Error loading tables: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTableData(String tableName) async {
    setState(() => _isLoading = true);
    try {
      final db = await getDBInstance();
      
      // Get table schema
      final schemaResult = await db.rawQuery("PRAGMA table_info($tableName)");
      
      // Get table data
      final dataResult = await db.query(tableName);
      
      setState(() {
        _selectedTable = tableName;
        _tableSchema = schemaResult;
        _tableData = dataResult;
      });
    } catch (e) {
      _showError('Error loading table data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Inspector'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTables,
          ),
        ],
      ),
      body: Row(
        children: [
          // Tables List
          Container(
            width: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                right: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: const Text(
                    'Tables',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: _tables.length,
                          itemBuilder: (context, index) {
                            final table = _tables[index];
                            final isSelected = table == _selectedTable;
                            
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              child: ListTile(
                                title: Text(
                                  table,
                                  style: TextStyle(
                                    fontWeight: isSelected 
                                        ? FontWeight.bold 
                                        : FontWeight.normal,
                                    color: isSelected 
                                        ? Colors.indigo 
                                        : Colors.black87,
                                  ),
                                ),
                                selected: isSelected,
                                selectedTileColor: Colors.indigo.shade100,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                onTap: () => _loadTableData(table),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          
          // Table Content
          Expanded(
            child: _selectedTable == null
                ? const Center(
                    child: Text(
                      'Select a table to view its contents',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Table Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.table_chart, color: Colors.indigo),
                            const SizedBox(width: 8),
                            Text(
                              _selectedTable!,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_tableData.length} rows',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Schema Info
                      if (_tableSchema.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Schema:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: _tableSchema.map((column) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${column['name']} (${column['type']})',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      
                      // Table Data
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _tableData.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No data in this table',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  )
                                : SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: SingleChildScrollView(
                                      child: DataTable(
                                        columns: _tableData.first.keys
                                            .map((key) => DataColumn(
                                                  label: Text(
                                                    key,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ))
                                            .toList(),
                                        rows: _tableData
                                            .map((row) => DataRow(
                                                  cells: row.values
                                                      .map((value) => DataCell(
                                                            Container(
                                                              constraints: const BoxConstraints(
                                                                maxWidth: 200,
                                                              ),
                                                              child: Text(
                                                                value?.toString() ?? 'NULL',
                                                                overflow: TextOverflow.ellipsis,
                                                                style: TextStyle(
                                                                  color: value == null 
                                                                      ? Colors.grey 
                                                                      : Colors.black87,
                                                                  fontStyle: value == null 
                                                                      ? FontStyle.italic 
                                                                      : FontStyle.normal,
                                                                ),
                                                              ),
                                                            ),
                                                          ))
                                                      .toList(),
                                                ))
                                            .toList(),
                                      ),
                                    ),
                                  ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
