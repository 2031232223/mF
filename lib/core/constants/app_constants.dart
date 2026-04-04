class AppConstants {
  static const String appName = 'Nova ADEN';
  static const String appDescription = 'Administrador de Negocio';
  static const String appVersion = '1.0.0';
  
  static const String databaseName = 'nova_aden.db';
  static const int databaseVersion = 3;
  
  static const int defaultStockMinimo = 5;
  static const int defaultStockCritico = 2;
  
  static const String defaultCurrency = 'CUP';
  static const double defaultMlcRate = 120.0;
  static const double defaultUsdRate = 1.0;
  
  static const int itemsPerPage = 20;
  static const Duration snackBarDuration = Duration(seconds: 2);
  static const Duration animationDuration = Duration(milliseconds: 300);
}
