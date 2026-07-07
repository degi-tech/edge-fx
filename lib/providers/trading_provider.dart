import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../services/deriv_service.dart';
import '../services/ai_service.dart';

enum MarketView { dashboard, botBuilder, freeBots, bulkTrader, manualTrader, copyTrading, charts, analysisTools }

class ActivityItem {
  final String title;
  final String status;
  final Color color;
  ActivityItem(this.title, this.status, this.color);
}

class TradingProvider extends ChangeNotifier {
  DerivService? _derivService;
  AiService? _aiService;
  
  MarketView _currentView = MarketView.dashboard;
  MarketView get currentView => _currentView;

  double? _currentPrice;
  final List<double> _priceHistory = [];
  String _aiAdvice = "Connect live stream to start AI analysis...";
  bool _isAnalyzing = false;
  
  bool _isAuthorized = false;
  String? _userName;
  double _balance = 0.0;
  String _currency = 'USD';

  final List<ActivityItem> _activities = [];

  // Manual Trading
  double _stake = 10.0;
  String _selectedSymbol = 'R_100';

  bool get isAuthorized => _isAuthorized;
  String? get userName => _userName;
  double get balance => _balance;
  double? get currentPrice => _currentPrice;
  List<double> get priceHistory => _priceHistory;
  String get aiAdvice => _aiAdvice;
  bool get isAnalyzing => _isAnalyzing;
  double get stake => _stake;
  String get selectedSymbol => _selectedSymbol;
  List<ActivityItem> get activities => _activities;

  TradingProvider() {
    _derivService = DerivService(appId: '33LkncGXigSRqxUn4iEfO');
    _derivService?.connect();
    _listenToMessages();
    _checkUrlForToken();
    
    // Auto-auth with your PAT if no URL token is present
    Future.delayed(const Duration(seconds: 2), () {
      if (!_isAuthorized) {
        authorizeWithToken('pat_0bb29d9c580304bf335501f99fb09997480b4815b910fd34992b9f12e6e2ee43');
      }
    });
  }

  void _checkUrlForToken() {
    final uri = Uri.base;
    String? token = uri.queryParameters['token1'];
    
    if (token == null && uri.fragment.contains('token1')) {
      final fragmentParts = uri.fragment.split('?');
      if (fragmentParts.length > 1) {
        token = Uri.splitQueryString(fragmentParts[1])['token1'];
      }
    }

    if (token != null) {
      addActivity('URL Token Detected', 'Authorizing...', Colors.blue);
      authorizeWithToken(token);
    }
  }

  void _listenToMessages() {
    _derivService?.messageStream.listen((msg) {
      if (msg.startsWith('Error')) {
        addActivity('Server Error', msg.replaceFirst('Error: ', ''), Colors.red);
      } else {
        addActivity('Server Info', msg, Colors.cyan);
      }
    });
  }

  void authorizeWithToken(String token) {
    _derivService?.authorize(token);
    _listenToAuth();
  }

  void _listenToAuth() {
    _derivService?.authStream.listen((auth) {
      if (auth.containsKey('fullname')) {
        _isAuthorized = true;
        _userName = auth['fullname'];
        _balance = double.parse(auth['balance'].toString());
        _currency = auth['currency'];
        addActivity('Auth Success', 'Account: $_userName', Colors.green);
      } else if (auth.containsKey('balance')) {
        // Handle balance subscription updates
        _balance = double.parse(auth['balance'].toString());
      }
      notifyListeners();
    });
  }

  void loginToDeriv(String appId) {
    // Automatically detects if you are on localhost, Firebase, or GitHub Pages
    final origin = html.window.location.origin;
    final path = html.window.location.pathname;
    final redirectUrl = Uri.encodeComponent('$origin$path');
    
    final authUrl = 'https://oauth.deriv.com/oauth2/authorize?app_id=$appId&l=en&brand=deriv&redirect_uri=$redirectUrl';
    print('Redirecting to: $authUrl');
    html.window.location.href = authUrl;
  }

  void addActivity(String title, String status, Color color) {
    _activities.insert(0, ActivityItem(title, status, color));
    if (_activities.length > 20) _activities.removeLast();
    notifyListeners();
  }

  void setView(MarketView view) {
    _currentView = view;
    notifyListeners();
  }

  void updateStake(double value) {
    _stake = value;
    notifyListeners();
  }

  void startTrading(String symbol) {
    _selectedSymbol = symbol;
    _derivService?.connect();
    _derivService?.subscribeTicks(symbol);
    addActivity('Stream Started', symbol, Colors.blue);

    _derivService?.tickStream.listen((tick) {
      _currentPrice = (tick['quote'] as num).toDouble();
      _priceHistory.add(_currentPrice!);
      if (_priceHistory.length > 50) _priceHistory.removeAt(0);
      notifyListeners();
    });
  }

  Future<void> analyzeMarket() async {
    if (_aiService == null || _priceHistory.isEmpty) return;
    _isAnalyzing = true;
    notifyListeners();
    _aiAdvice = await _aiService!.getTradingAdvice(_priceHistory);
    _isAnalyzing = false;
    notifyListeners();
  }

  void placeTrade(String type) {
    if (!_isAuthorized) {
      addActivity('Trade Denied', 'Not Authorized', Colors.red);
      return;
    }
    _derivService?.buy(_selectedSymbol, _stake, type);
  }

  @override
  void dispose() {
    _derivService?.dispose();
    super.dispose();
  }
}
