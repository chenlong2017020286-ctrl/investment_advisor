import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/stock.dart';
import '../models/portfolio.dart';

/// 投资组合状态管理
class PortfolioProvider extends ChangeNotifier {
  SharedPreferences? _prefs;

  // 投资组合
  Portfolio _portfolio = Portfolio(
    cash: 1000000, // 初始资金100万
    positions: [],
    trades: [],
    initialCapital: 1000000,
  );
  Portfolio get portfolio => _portfolio;

  // 是否正在加载
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 错误信息
  String? _error;
  String? get error => _error;

  // 当前价格缓存（用于计算盈亏）
  final Map<String, double> _currentPrices = {};

  PortfolioProvider() {
    _init();
  }

  /// 初始化
  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadPortfolio();
  }

  /// 加载投资组合数据
  Future<void> _loadPortfolio() async {
    final portfolioJson = _prefs?.getString('portfolio');
    if (portfolioJson != null) {
      try {
        final data = jsonDecode(portfolioJson);
        _portfolio = Portfolio.fromJson(data);
        notifyListeners();
      } catch (e) {
        print('加载投资组合失败: $e');
      }
    }
  }

  /// 保存投资组合数据
  Future<void> _savePortfolio() async {
    final data = jsonEncode(_portfolio.toJson());
    await _prefs?.setString('portfolio', data);
  }

  /// 更新股票价格
  void updatePrices(Map<String, double> prices) {
    _currentPrices.addAll(prices);
    notifyListeners();
  }

  /// 更新单个股票价格
  void updatePrice(String code, double price) {
    _currentPrices[code] = price;
    notifyListeners();
  }

  /// 买入股票
  Future<void> buyStock(Stock stock, int quantity) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (quantity <= 0) {
        throw Exception('买入数量必须大于0');
      }

      final price = stock.currentPrice;
      final totalCost = quantity * price * 1.0003; // 包含手续费

      if (totalCost > _portfolio.cash) {
        throw Exception('可用资金不足');
      }

      _portfolio.buyStock(stock, quantity, price);
      await _savePortfolio();

      // 更新价格缓存
      _currentPrices[stock.code] = price;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 卖出股票
  Future<void> sellStock(Stock stock, int quantity) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (quantity <= 0) {
        throw Exception('卖出数量必须大于0');
      }

      final position = _portfolio.getPosition(stock.code);
      if (position == null || position.quantity < quantity) {
        throw Exception('持仓数量不足');
      }

      final price = stock.currentPrice;
      _portfolio.sellStock(stock, quantity, price);
      await _savePortfolio();

      // 更新价格缓存
      _currentPrices[stock.code] = price;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 获取持仓的当前市值
  double getPositionMarketValue(String code) {
    final position = _portfolio.getPosition(code);
    if (position == null) return 0;
    final price = _currentPrices[code] ?? position.avgCost;
    return position.marketValue(price);
  }

  /// 获取持仓的盈亏
  double getPositionProfitLoss(String code) {
    final position = _portfolio.getPosition(code);
    if (position == null) return 0;
    final price = _currentPrices[code] ?? position.avgCost;
    return position.profitLoss(price);
  }

  /// 获取持仓的盈亏比例
  double getPositionProfitLossPercent(String code) {
    final position = _portfolio.getPosition(code);
    if (position == null) return 0;
    final price = _currentPrices[code] ?? position.avgCost;
    return position.profitLossPercent(price);
  }

  /// 计算总资产
  double get totalAssets => _portfolio.totalAssets(_currentPrices);

  /// 计算总盈亏
  double get totalProfitLoss => _portfolio.totalProfitLoss(_currentPrices);

  /// 计算总盈亏比例
  double get totalProfitLossPercent => _portfolio.totalProfitLossPercent(_currentPrices);

  /// 计算持仓总市值
  double get positionsMarketValue => _portfolio.positionsMarketValue(_currentPrices);

  /// 获取可用资金
  double get availableCash => _portfolio.cash;

  /// 获取初始资金
  double get initialCapital => _portfolio.initialCapital;

  /// 获取某股票的持仓数量
  int getPositionQuantity(String code) {
    final position = _portfolio.getPosition(code);
    return position?.quantity ?? 0;
  }

  /// 获取某股票的平均成本
  double? getPositionAvgCost(String code) {
    final position = _portfolio.getPosition(code);
    return position?.avgCost;
  }

  /// 判断是否持有某股票
  bool hasPosition(String code) {
    return _portfolio.getPosition(code) != null;
  }

  /// 重置模拟盘
  Future<void> resetPortfolio() async {
    _portfolio = Portfolio(
      cash: 1000000,
      positions: [],
      trades: [],
      initialCapital: 1000000,
    );
    _currentPrices.clear();
    await _savePortfolio();
    notifyListeners();
  }

  /// 清除错误信息
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
