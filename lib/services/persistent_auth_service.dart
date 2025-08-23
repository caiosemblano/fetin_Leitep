import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

class PersistentAuthService {
  static const String _keyRememberMe = 'remember_me';
  static const String _keyUserEmail = 'user_email';
  static const String _keyLastLogin = 'last_login';
  static const String _keyAutoLogout = 'auto_logout_enabled';
  static const String _keyLogoutTimeout = 'logout_timeout_minutes';
  
  // Configurações padrão
  static const int _defaultTimeoutMinutes = 30;
  static const int _maxInactivityDays = 30;

  /// Configurar preferências de login persistente
  static Future<void> setRememberMe({
    required bool remember,
    String? email,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool(_keyRememberMe, remember);
      
      if (remember && email != null) {
        await prefs.setString(_keyUserEmail, email);
        await prefs.setString(_keyLastLogin, DateTime.now().toIso8601String());
      } else {
        // Limpar dados se não quiser lembrar
        await prefs.remove(_keyUserEmail);
        await prefs.remove(_keyLastLogin);
      }
      
      AppLogger.info('Configurações de autenticação persistente salvas: remember=$remember');
    } catch (e) {
      AppLogger.error('Erro ao salvar preferências de autenticação', e);
    }
  }

  /// Verificar se deve manter usuário logado
  static Future<bool> shouldKeepLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool(_keyRememberMe) ?? false;
      
      if (!remember) return false;
      
      final lastLoginStr = prefs.getString(_keyLastLogin);
      if (lastLoginStr == null) return false;
      
      final lastLogin = DateTime.parse(lastLoginStr);
      final daysSinceLogin = DateTime.now().difference(lastLogin).inDays;
      
      // Se passou muito tempo, forçar novo login
      if (daysSinceLogin > _maxInactivityDays) {
        await clearAuthData();
        return false;
      }
      
      // Verificar se Firebase ainda tem usuário ativo
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        await clearAuthData();
        return false;
      }
      
      AppLogger.info('Usuário mantido logado: ${currentUser.email}');
      return true;
      
    } catch (e) {
      AppLogger.error('Erro ao verificar login persistente', e);
      return false;
    }
  }

  /// Verificar se deve fazer logout automático por inatividade
  static Future<bool> shouldAutoLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final autoLogout = prefs.getBool(_keyAutoLogout) ?? true;
      
      if (!autoLogout) return false;
      
      final timeoutMinutes = prefs.getInt(_keyLogoutTimeout) ?? _defaultTimeoutMinutes;
      final lastActivityStr = prefs.getString('last_activity');
      
      if (lastActivityStr == null) {
        // Primeira vez, registrar atividade
        await updateLastActivity();
        return false;
      }
      
      final lastActivity = DateTime.parse(lastActivityStr);
      final minutesInactive = DateTime.now().difference(lastActivity).inMinutes;
      
      if (minutesInactive >= timeoutMinutes) {
        AppLogger.info('Logout automático por inatividade: ${minutesInactive}min');
        return true;
      }
      
      return false;
    } catch (e) {
      AppLogger.error('Erro ao verificar logout automático', e);
      return false;
    }
  }

  /// Atualizar timestamp da última atividade
  static Future<void> updateLastActivity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_activity', DateTime.now().toIso8601String());
    } catch (e) {
      AppLogger.error('Erro ao atualizar última atividade', e);
    }
  }

  /// Obter email salvo
  static Future<String?> getSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserEmail);
    } catch (e) {
      AppLogger.error('Erro ao obter email salvo', e);
      return null;
    }
  }

  /// Obter configurações de logout automático
  static Future<Map<String, dynamic>> getAutoLogoutSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'enabled': prefs.getBool(_keyAutoLogout) ?? true,
        'timeoutMinutes': prefs.getInt(_keyLogoutTimeout) ?? _defaultTimeoutMinutes,
      };
    } catch (e) {
      AppLogger.error('Erro ao obter configurações de logout', e);
      return {
        'enabled': true,
        'timeoutMinutes': _defaultTimeoutMinutes,
      };
    }
  }

  /// Limpar todos os dados de autenticação
  static Future<void> clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyRememberMe);
      await prefs.remove(_keyUserEmail);
      await prefs.remove(_keyLastLogin);
      await prefs.remove('last_activity');
      
      AppLogger.info('Dados de autenticação limpos');
    } catch (e) {
      AppLogger.error('Erro ao limpar dados de autenticação', e);
    }
  }

  /// Fazer logout completo
  static Future<void> logout() async {
    try {
      // Logout do Firebase
      await FirebaseAuth.instance.signOut();
      
      // Limpar dados locais
      await clearAuthData();
      
      AppLogger.info('Logout realizado com sucesso');
    } catch (e) {
      AppLogger.error('Erro durante logout', e);
      rethrow;
    }
  }

  /// Configurar timeout personalizado
  static Future<void> setCustomTimeout(int minutes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLogoutTimeout, minutes);
      AppLogger.info('Timeout personalizado configurado: ${minutes}min');
    } catch (e) {
      AppLogger.error('Erro ao configurar timeout', e);
    }
  }

  /// Verificar status de autenticação
  static Future<Map<String, dynamic>> getAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUser = FirebaseAuth.instance.currentUser;
      
      return {
        'isLoggedIn': currentUser != null,
        'userEmail': currentUser?.email,
        'rememberMe': prefs.getBool(_keyRememberMe) ?? false,
        'autoLogout': prefs.getBool(_keyAutoLogout) ?? true,
        'timeoutMinutes': prefs.getInt(_keyLogoutTimeout) ?? _defaultTimeoutMinutes,
        'lastLogin': prefs.getString(_keyLastLogin),
        'lastActivity': prefs.getString('last_activity'),
      };
    } catch (e) {
      AppLogger.error('Erro ao obter status de autenticação', e);
      return {'isLoggedIn': false};
    }
  }

  /// Habilitar/desabilitar logout automático
  static Future<void> toggleAutoLogout(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAutoLogout, enabled);
      
      if (enabled) {
        await updateLastActivity();
      }
      
      AppLogger.info('Logout automático ${enabled ? 'habilitado' : 'desabilitado'}');
    } catch (e) {
      AppLogger.error('Erro ao alterar configuração de logout automático', e);
    }
  }
}
