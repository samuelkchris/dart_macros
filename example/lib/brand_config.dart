
import 'package:dart_macros/dart_macros.dart';
import 'package:flutter/material.dart';

class BrandConfig {
  static Future<void> initialize(String clientId) async {
    // Initialize base macros
    FlutterMacros.initialize();

    // Load client configuration
    final config = _getClientConfig(clientId);

    // Register client-specific macros
    FlutterMacros.registerFromAnnotations([
      Define('CLIENT_ID', clientId),
      Define('APP_NAME', config.appName),
      Define('PRIMARY_COLOR', config.primaryColor.value),
      Define('ACCENT_COLOR', config.accentColor.value),
      Define('LOGO_ASSET', config.logoAsset),
      Define('CURRENCY_SYMBOL', config.currencySymbol),
      Define('FOOTER_TEXT', config.footerText),

      // Feature flags
      Define('FEATURE_GUEST_CHECKOUT', config.allowGuestCheckout),
      Define('FEATURE_LOYALTY_PROGRAM', config.hasLoyaltyProgram),
      Define('FEATURE_SUBSCRIPTIONS', config.hasSubscriptions),
      Define('FEATURE_WISHLISTS', config.hasWishlists),
      Define('FEATURE_REVIEWS', config.hasReviews),
      Define('FEATURE_LIVE_CHAT', config.hasLiveChat),

      // Checkout configuration
      Define('DEFAULT_SHIPPING_OPTION', config.defaultShipping),
      Define('SHOW_TAX_SEPARATE', config.showTaxSeparate),
      Define('MIN_ORDER_VALUE', config.minOrderValue),
    ]);

    // Register any region-specific compliance requirements
    Macros.registerMacro('REQUIRES_TAX_ID', config.requiresTaxId);
    Macros.registerMacro('REQUIRES_AGE_VERIFICATION', config.requiresAgeVerification);
  }

  // Getter methods for easy access
  static String get appName => Macros.get<String>('APP_NAME');
  static Color get primaryColor => Color(Macros.get<int>('PRIMARY_COLOR'));
  static Color get accentColor => Color(Macros.get<int>('ACCENT_COLOR'));
  static String get logoAsset => Macros.get<String>('LOGO_ASSET');
  static String get currencySymbol => Macros.get<String>('CURRENCY_SYMBOL');
  static String get footerText => Macros.get<String>('FOOTER_TEXT');
  static double get minOrderValue => Macros.get<double>('MIN_ORDER_VALUE');

  // Feature flag checks
  static bool get hasGuestCheckout => Macros.get<bool>('FEATURE_GUEST_CHECKOUT');
  static bool get hasLoyaltyProgram => Macros.get<bool>('FEATURE_LOYALTY_PROGRAM');
  static bool get hasSubscriptions => Macros.get<bool>('FEATURE_SUBSCRIPTIONS');
  static bool get hasWishlists => Macros.get<bool>('FEATURE_WISHLISTS');
  static bool get hasReviews => Macros.get<bool>('FEATURE_REVIEWS');
  static bool get hasLiveChat => Macros.get<bool>('FEATURE_LIVE_CHAT');

  // Client-specific configurations
  static _ClientConfig _getClientConfig(String clientId) {
    switch (clientId) {
      case 'fashion_store':
        return _ClientConfig(
          appName: 'FashionHub',
          primaryColor: Colors.indigo,
          accentColor: Colors.pink,
          logoAsset: 'assets/fashionhub_logo.png',
          currencySymbol: '\$',
          footerText: '© 2025 FashionHub Inc.',
          allowGuestCheckout: true,
          hasLoyaltyProgram: true,
          hasSubscriptions: false,
          hasWishlists: true,
          hasReviews: true,
          hasLiveChat: false,
          defaultShipping: 'standard',
          showTaxSeparate: true,
          minOrderValue: 20.0,
          requiresTaxId: false,
          requiresAgeVerification: false,
        );

      case 'electronics_store':
        return _ClientConfig(
          appName: 'TechWorld',
          primaryColor: Colors.blue,
          accentColor: Colors.amber,
          logoAsset: 'assets/techworld_logo.png',
          currencySymbol: '\$',
          footerText: '© 2025 TechWorld Electronics',
          allowGuestCheckout: false,
          hasLoyaltyProgram: true,
          hasSubscriptions: true,
          hasWishlists: true,
          hasReviews: true,
          hasLiveChat: true,
          defaultShipping: 'express',
          showTaxSeparate: true,
          minOrderValue: 0.0,
          requiresTaxId: false,
          requiresAgeVerification: false,
        );

      case 'liquor_store':
        return _ClientConfig(
          appName: 'Fine Spirits',
          primaryColor: Colors.brown,
          accentColor: Colors.amber,
          logoAsset: 'assets/finespirits_logo.png',
          currencySymbol: '£',
          footerText: '© 2025 Fine Spirits Ltd. Drink responsibly.',
          allowGuestCheckout: false,
          hasLoyaltyProgram: false,
          hasSubscriptions: true,
          hasWishlists: true,
          hasReviews: false,
          hasLiveChat: false,
          defaultShipping: 'standard',
          showTaxSeparate: true,
          minOrderValue: 25.0,
          requiresTaxId: false,
          requiresAgeVerification: true,
        );

      default:
        throw Exception('Unknown client ID: $clientId');
    }
  }
}

class _ClientConfig {
  final String appName;
  final Color primaryColor;
  final Color accentColor;
  final String logoAsset;
  final String currencySymbol;
  final String footerText;
  final bool allowGuestCheckout;
  final bool hasLoyaltyProgram;
  final bool hasSubscriptions;
  final bool hasWishlists;
  final bool hasReviews;
  final bool hasLiveChat;
  final String defaultShipping;
  final bool showTaxSeparate;
  final double minOrderValue;
  final bool requiresTaxId;
  final bool requiresAgeVerification;

  _ClientConfig({
    required this.appName,
    required this.primaryColor,
    required this.accentColor,
    required this.logoAsset,
    required this.currencySymbol,
    required this.footerText,
    required this.allowGuestCheckout,
    required this.hasLoyaltyProgram,
    required this.hasSubscriptions,
    required this.hasWishlists,
    required this.hasReviews,
    required this.hasLiveChat,
    required this.defaultShipping,
    required this.showTaxSeparate,
    required this.minOrderValue,
    required this.requiresTaxId,
    required this.requiresAgeVerification,
  });
}