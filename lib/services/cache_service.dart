import '../utils/app_logger.dart';

class CacheService {
  static final Map<String, CacheItem> _cache = {};
  static const Duration _defaultTtl = Duration(minutes: 5);

  // Cache para listas de vacas por usuário
  static const String _vacasCacheKey = 'vacas_';

  // Cache para registros de produção
  static const String _producaoCacheKey = 'producao_';

  // Cache para dados do dashboard
  static const String _dashboardCacheKey = 'dashboard_';

  /// Armazena dados no cache com TTL
  static void put(String key, dynamic data, {Duration? ttl}) {
    _cache[key] = CacheItem(
      data: data,
      timestamp: DateTime.now(),
      ttl: ttl ?? _defaultTtl,
    );

    AppLogger.info('🗄️ Cache armazenado: $key');
    _cleanupExpiredEntries();
  }

  /// Recupera dados do cache se ainda válidos
  static T? get<T>(String key) {
    final item = _cache[key];
    if (item == null) return null;

    if (item.isExpired) {
      _cache.remove(key);
      AppLogger.info('🗑️ Cache expirado removido: $key');
      return null;
    }

    AppLogger.info('✅ Cache hit: $key');
    return item.data as T?;
  }

  /// Verifica se existe cache válido para a chave
  static bool has(String key) {
    final item = _cache[key];
    if (item == null) return false;

    if (item.isExpired) {
      _cache.remove(key);
      return false;
    }

    return true;
  }

  /// Remove entrada específica do cache
  static void remove(String key) {
    _cache.remove(key);
    AppLogger.info('🗑️ Cache removido: $key');
  }

  /// Limpa todo o cache
  static void clear() {
    _cache.clear();
    AppLogger.info('🧹 Cache limpo completamente');
  }

  /// Remove entradas expiradas
  static void _cleanupExpiredEntries() {
    final expiredKeys = _cache.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _cache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      AppLogger.info(
          '🧹 Removidas ${expiredKeys.length} entradas expiradas do cache',);
    }
  }

  /// Gera chave de cache para vacas de um usuário
  static String vacasCacheKey(String userId) => '$_vacasCacheKey$userId';

  /// Gera chave de cache para registros de produção
  static String producaoCacheKey(String userId, String period) =>
      '$_producaoCacheKey${userId}_$period';

  /// Gera chave de cache para dashboard
  static String dashboardCacheKey(String userId) =>
      '$_dashboardCacheKey$userId';

  /// Invalida cache relacionado a vacas quando houver mudanças
  static void invalidateVacasCache(String userId) {
    final vacasKey = vacasCacheKey(userId);
    final dashboardKey = dashboardCacheKey(userId);

    remove(vacasKey);
    remove(dashboardKey);

    // Também remover caches de produção relacionados
    _cache.keys
        .where((key) => key.startsWith('$_producaoCacheKey$userId'))
        .toList()
        .forEach(remove);
  }

  /// Invalida cache de produção quando houver novos registros
  static void invalidateProducaoCache(String userId) {
    final dashboardKey = dashboardCacheKey(userId);
    remove(dashboardKey);

    _cache.keys
        .where((key) => key.startsWith('$_producaoCacheKey$userId'))
        .toList()
        .forEach(remove);
  }

  /// Retorna estatísticas do cache
  static Map<String, dynamic> getStats() {
    final valid = _cache.values.where((item) => !item.isExpired).length;
    final expired = _cache.values.where((item) => item.isExpired).length;

    return {
      'total': _cache.length,
      'valid': valid,
      'expired': expired,
      'hitRate': _calculateHitRate(),
    };
  }

  static const int _hits = 0;
  static const int _misses = 0;

  static double _calculateHitRate() {
    const total = _hits + _misses;
    return total == 0 ? 0.0 : _hits / total;
  }
}

class CacheItem {
  CacheItem({
    required this.data,
    required this.timestamp,
    required this.ttl,
  });
  final dynamic data;
  final DateTime timestamp;
  final Duration ttl;

  bool get isExpired => DateTime.now().isAfter(timestamp.add(ttl));
}
