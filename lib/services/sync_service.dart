import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'sqlite_service.dart';

class SyncService {
  SyncService._(this.apiBaseUrl);
  static SyncService? _instance;
  factory SyncService(String apiBaseUrl) =>
      _instance ??= SyncService._(apiBaseUrl);

  final String apiBaseUrl;
  final SqliteService db = SqliteService.instance;
  final int batchSize = 100;

  Future<void> runSync() async {
    try {
      await db.init();
      await _pushPending();
      await _pullRemote();
    } catch (e) {
      print('Sync error: $e');
    }
  }

  Future<void> _pushPending() async {
    final pending = await db.getPendingOperations(limit: batchSize);
    if (pending.isEmpty) return;
    final branchId = await db.getBranchId();
    final body = {
      'branch_id': branchId,
      'operations': pending.map((p) {
        return {
          'id': p['id'],
          'branch_id': p['branch_id'],
          'op_type': p['op_type'],
          'payload': jsonDecode(p['payload'] as String),
          'client_ts': p['client_ts'],
          'checksum': p['checksum'],
        };
      }).toList()
    };

    try {
      final resp = await _postJson('/api/v1/sync/operations', body);
      if (resp is Map && resp.containsKey('applied')) {
        final applied = resp['applied'] as List<dynamic>;
        for (final a in applied) {
          final id = a['id'] as String;
          final serverLsn = a['server_lsn'] is int
              ? a['server_lsn'] as int
              : int.tryParse('${a['server_lsn']}');
          await db.markOperationSynced(id, serverLsn: serverLsn);
        }
      }
      if (resp is Map && resp.containsKey('errors')) {
        final errors = resp['errors'] as List<dynamic>;
        for (final e in errors) {
          final id = e['id'] as String?;
          if (id != null)
            await db.markOperationFailed(id, reason: e['message'] as String?);
        }
      }
    } catch (e) {
      print('Push error: $e');
      rethrow;
    }
  }

  Future<void> _pullRemote() async {
    var lastLsnStr = await db.getSyncMeta('last_server_lsn');
    var since = int.tryParse(lastLsnStr ?? '0') ?? 0;
    final branchId = await db.getBranchId();
    while (true) {
      final path =
          '/api/v1/sync/operations?since_lsn=$since&branch_id=${Uri.encodeComponent(branchId ?? '')}&limit=$batchSize';
      final resp = await _getJson(path);
      if (resp is! Map) break;
      final ops = resp['operations'] as List<dynamic>? ?? [];
      if (ops.isEmpty) break;
      for (final op in ops) {
        final id = op['id'] as String;
        final exists = await db.operationExists(id);
        if (!exists) {
          await db.insertOperationFromServer(op as Map<String, dynamic>);
          await db.applyOperation(op as Map<String, dynamic>);
        } else {
          await db.markOperationSynced(id, serverLsn: op['server_lsn'] as int?);
        }
        since = op['server_lsn'] is int ? op['server_lsn'] as int : since;
        await db.setSyncMeta('last_server_lsn', since.toString());
      }
      if (ops.length < batchSize) break;
    }
  }

  Future<dynamic> _postJson(String path, Object body) async {
    final uri = Uri.parse(apiBaseUrl + path);
    final client = HttpClient();
    final req = await client.postUrl(uri);
    req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    req.add(utf8.encode(jsonEncode(body)));
    final resp = await req.close();
    final text = await resp.transform(utf8.decoder).join();
    client.close();
    return jsonDecode(text);
  }

  Future<dynamic> _getJson(String path) async {
    final uri = Uri.parse(apiBaseUrl + path);
    final client = HttpClient();
    final req = await client.getUrl(uri);
    final resp = await req.close();
    final text = await resp.transform(utf8.decoder).join();
    client.close();
    return jsonDecode(text);
  }
}
