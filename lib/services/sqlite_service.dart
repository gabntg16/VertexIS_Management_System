import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SqliteService {
  SqliteService._();
  static final SqliteService instance = SqliteService._();

  Database? _db;

  Future<void> init() async {
    if (_db != null && _db!.isOpen) return;
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'vertexis.db');
    _db = await openDatabase(path, version: 2, onCreate: (db, version) async {
      await db.execute('CREATE TABLE kv(key TEXT PRIMARY KEY, value TEXT)');
      await db.execute('''
        CREATE TABLE operations (
          id TEXT PRIMARY KEY,
          branch_id TEXT NOT NULL,
          op_type TEXT NOT NULL,
          payload TEXT NOT NULL,
          client_ts INTEGER NOT NULL,
          status TEXT NOT NULL,
          retries INTEGER DEFAULT 0,
          server_lsn INTEGER,
          checksum TEXT,
          created_at INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE products (
          id TEXT PRIMARY KEY,
          sku TEXT UNIQUE,
          name TEXT,
          metadata TEXT,
          version INTEGER DEFAULT 1,
          updated_at INTEGER
        )
      ''');
      await db.execute('''
        CREATE TABLE inventory (
          product_id TEXT NOT NULL,
          branch_id TEXT NOT NULL,
          quantity INTEGER DEFAULT 0,
          last_applied_lsn INTEGER,
          PRIMARY KEY(product_id, branch_id)
        )
      ''');
      await db.execute('''
        CREATE TABLE sync_meta (
          key TEXT PRIMARY KEY,
          value TEXT
        )
      ''');
    }, onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await db.execute('''
          CREATE TABLE operations (
            id TEXT PRIMARY KEY,
            branch_id TEXT NOT NULL,
            op_type TEXT NOT NULL,
            payload TEXT NOT NULL,
            client_ts INTEGER NOT NULL,
            status TEXT NOT NULL,
            retries INTEGER DEFAULT 0,
            server_lsn INTEGER,
            checksum TEXT,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE products (
            id TEXT PRIMARY KEY,
            sku TEXT UNIQUE,
            name TEXT,
            metadata TEXT,
            version INTEGER DEFAULT 1,
            updated_at INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE inventory (
            product_id TEXT NOT NULL,
            branch_id TEXT NOT NULL,
            quantity INTEGER DEFAULT 0,
            last_applied_lsn INTEGER,
            PRIMARY KEY(product_id, branch_id)
          )
        ''');
        await db.execute('''
          CREATE TABLE sync_meta (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
      }
    });
  }

  Future<String?> getString(String key) async {
    if (_db == null) await init();
    final maps = await _db!.query('kv', where: 'key = ?', whereArgs: [key]);
    if (maps.isEmpty) return null;
    return maps.first['value'] as String?;
  }

  Future<void> setString(String key, String value) async {
    if (_db == null) await init();
    await _db!.insert(
      'kv',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSyncMeta(String key) async {
    if (_db == null) await init();
    final maps =
        await _db!.query('sync_meta', where: 'key = ?', whereArgs: [key]);
    if (maps.isEmpty) return null;
    return maps.first['value'] as String?;
  }

  Future<void> setSyncMeta(String key, String value) async {
    if (_db == null) await init();
    await _db!.insert('sync_meta', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> setBranchId(String branchId) async {
    await setString('branch_id', branchId);
  }

  Future<String?> getBranchId() async {
    return await getString('branch_id');
  }

  Future<void> insertOperation(Map<String, dynamic> op) async {
    if (_db == null) await init();
    final row = {
      'id': op['id'],
      'branch_id': op['branch_id'],
      'op_type': op['op_type'],
      'payload':
          op['payload'] is String ? op['payload'] : jsonEncode(op['payload']),
      'client_ts': op['client_ts'],
      'status': op['status'] ?? 'pending',
      'retries': op['retries'] ?? 0,
      'checksum': op['checksum'],
      'created_at': op['created_at'] ?? DateTime.now().millisecondsSinceEpoch,
    };
    await _db!.insert('operations', row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getPendingOperations(
      {int limit = 100}) async {
    if (_db == null) await init();
    final rows = await _db!.query('operations',
        where: "status IN ('pending','failed')",
        orderBy: 'client_ts ASC',
        limit: limit);
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<void> markOperationSynced(String id,
      {int? serverLsn, String? serverTs}) async {
    if (_db == null) await init();
    final values = <String, Object?>{'status': 'synced'};
    if (serverLsn != null) values['server_lsn'] = serverLsn;
    await _db!.update('operations', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markOperationFailed(String id, {String? reason}) async {
    if (_db == null) await init();
    await _db!.update('operations', {'status': 'failed'},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> operationExists(String id) async {
    if (_db == null) await init();
    final rows = await _db!
        .query('operations', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isNotEmpty;
  }

  Future<void> insertOperationFromServer(Map<String, dynamic> op) async {
    if (_db == null) await init();
    final row = {
      'id': op['id'],
      'branch_id': op['branch_id'],
      'op_type': op['op_type'],
      'payload':
          op['payload'] is String ? op['payload'] : jsonEncode(op['payload']),
      'client_ts': op['client_ts'] ?? DateTime.now().millisecondsSinceEpoch,
      'status': 'synced',
      'server_lsn': op['server_lsn'],
      'checksum': op['checksum'],
      'created_at': op['created_at'] ?? DateTime.now().millisecondsSinceEpoch,
    };
    await _db!.insert('operations', row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> applyOperation(Map<String, dynamic> op) async {
    if (_db == null) await init();
    final payload = op['payload'];
    Map<String, dynamic> data;
    if (payload is String)
      data = jsonDecode(payload) as Map<String, dynamic>;
    else
      data = Map<String, dynamic>.from(payload ?? {});

    final opType =
        op['op_type'] as String? ?? data['op_type'] as String? ?? 'unknown';
    final branchId = op['branch_id'] ?? data['branch_id'];
    final serverLsn = op['server_lsn'] ?? data['server_lsn'];

    if (data.containsKey('deltas')) {
      final deltas = data['deltas'] as List<dynamic>;
      final batch = _db!.batch();
      for (final d in deltas) {
        final productId = d['product_id'] as String;
        final delta = d['delta'] as int;
        batch.rawInsert(
            'INSERT OR IGNORE INTO inventory(product_id, branch_id, quantity, last_applied_lsn) VALUES(?, ?, 0, ?)',
            [productId, branchId, serverLsn]);
        batch.rawUpdate(
            'UPDATE inventory SET quantity = quantity + ?, last_applied_lsn = ? WHERE product_id = ? AND branch_id = ?',
            [delta, serverLsn, productId, branchId]);
      }
      await batch.commit(noResult: true);
    } else if (data.containsKey('items') && opType == 'sale') {
      final items = data['items'] as List<dynamic>;
      final batch = _db!.batch();
      for (final it in items) {
        final productId = it['product_id'] as String;
        final qty = (it['qty'] as num).toInt();
        batch.rawInsert(
            'INSERT OR IGNORE INTO inventory(product_id, branch_id, quantity, last_applied_lsn) VALUES(?, ?, 0, ?)',
            [productId, branchId, serverLsn]);
        batch.rawUpdate(
            'UPDATE inventory SET quantity = quantity - ?, last_applied_lsn = ? WHERE product_id = ? AND branch_id = ?',
            [qty, serverLsn, productId, branchId]);
      }
      await batch.commit(noResult: true);
    }
  }

  Future<void> deleteKey(String key) async {
    if (_db == null) await init();
    await _db!.delete('kv', where: 'key = ?', whereArgs: [key]);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
