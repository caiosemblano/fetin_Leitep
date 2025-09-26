/// Constantes de temas e cores da aplicação
class ThemeConstants {
  // Cores principais
  static const String primaryColorHex = '#5DADE2';
  static const String secondaryColorHex = '#7FB3D3';
  static const String errorColorHex = '#E74C3C';
  static const String warningColorHex = '#F39C12';
  static const String successColorHex = '#27AE60';

  // Configurações de tema
  static const bool useSystemTheme = true;
  static const bool useMaterial3 = true;

  // Tamanhos
  static const double defaultBorderRadius = 8.0;
  static const double largeBorderRadius = 12.0;
  static const double smallBorderRadius = 4.0;

  static const double defaultElevation = 2.0;
  static const double largeElevation = 4.0;
  static const double smallElevation = 1.0;

  // Espaçamentos
  static const double defaultPadding = 16.0;
  static const double largePadding = 24.0;
  static const double smallPadding = 8.0;
  static const double extraSmallPadding = 4.0;
}

/// Constantes de strings da UI
class UIStrings {
  // Títulos de telas
  static const String dashboardTitle = 'Dashboard';
  static const String cowsTitle = 'Rebanho';
  static const String productionTitle = 'Produção';
  static const String activitiesTitle = 'Atividades';
  static const String reportsTitle = 'Relatórios';
  static const String settingsTitle = 'Configurações';

  // Labels comuns
  static const String save = 'Salvar';
  static const String cancel = 'Cancelar';
  static const String delete = 'Excluir';
  static const String edit = 'Editar';
  static const String add = 'Adicionar';
  static const String loading = 'Carregando...';
  static const String retry = 'Tentar novamente';
  static const String confirm = 'Confirmar';

  // Mensagens de erro
  static const String genericError = 'Ocorreu um erro inesperado';
  static const String networkError = 'Erro de conexão';
  static const String authError = 'Erro de autenticação';
  static const String permissionError = 'Permissão negada';
  static const String validationError = 'Dados inválidos';

  // Mensagens de sucesso
  static const String saveSuccess = 'Salvo com sucesso!';
  static const String deleteSuccess = 'Excluído com sucesso!';
  static const String updateSuccess = 'Atualizado com sucesso!';
}
