class AppConstants {
  static const String appName = 'Nova ADEN';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Sistema de Gestión Comercial';
  
  // Configuración de base de datos
  static const String databaseName = 'nova_aden.db';
  static const int databaseVersion = 3;
  
  // Configuración de stock
  static const int defaultStockMinimo = 5;
  static const int defaultStockCritico = 2;
  
  // Configuración de moneda
  static const String defaultCurrency = 'CUP';
  static const double defaultMlcRate = 120.0;
  static const double defaultUsdRate = 1.0;
  
  // Configuración de UI
  static const int itemsPerPage = 20;
  static const Duration snackBarDuration = Duration(seconds: 2);
  static const Duration animationDuration = Duration(milliseconds: 300);
}
