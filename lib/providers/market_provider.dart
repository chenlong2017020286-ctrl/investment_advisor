import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/stock.dart';
import '../services/stock_api_service.dart';

/// 行情数据状态管理
class MarketProvider extends ChangeNotifier {
  final StockApiService _apiService = StockApiService();
  SharedPreferences? _prefs;

  // 股票列表
  List<Stock> _stocks = [];
  List<Stock> get stocks => _stocks;

  // 自选股列表
  List<String> _watchList = [];
  List<String> get watchList => _watchList;

  // 是否正在加载
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 错误信息
  String? _error;
  String? get error => _error;

  // 自动刷新定时器
  Timer? _refreshTimer;

  // 刷新间隔（秒）
  static const int refreshInterval = 5;

  // 当前选中的股票
  Stock? _selectedStock;
  Stock? get selectedStock => _selectedStock;

  // K线数据
  List<KLineData> _kLineData = [];
  List<KLineData> get kLineData => _kLineData;

  MarketProvider() {
    _init();
  }

  /// 初始化
  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadWatchList();
    await fetchStocks();
    startAutoRefresh();
  }

  /// 加载自选股
  Future<void> _loadWatchList() async {
    final watchListJson = _prefs?.getStringList('watchlist') ?? [];
    _watchList = watchListJson;

    // 如果没有自选股，添加默认股票
    if (_watchList.isEmpty) {
      _watchList = StockList.defaultStocks
          .take(10)
          .map((s) => s['code']!)
          .toList();
      await _saveWatchList();
    }
  }

  /// 保存自选股
  Future<void> _saveWatchList() async {
    await _prefs?.setStringList('watchlist', _watchList);
  }

  /// 获取股票行情
  Future<void> fetchStocks() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final stocks = await _apiService.fetchStockQuotes(_watchList);
      _stocks = stocks;

      // 更新选中股票的数据
      if (_selectedStock != null) {
        final updatedStock = stocks.firstWhere(
          (s) => s.code == _selectedStock!.code,
          orElse: () => _selectedStock!,
        );
        _selectedStock = updatedStock;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = '获取行情失败: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 获取单只股票详情
  Future<void> fetchStockDetail(String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final stock = await _apiService.fetchStockQuote(code);
      if (stock != null) {
        _selectedStock = stock;
        // 获取K线数据
        await fetchKLineData(code);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = '获取股票详情失败: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 获取K线数据
  Future<void> fetchKLineData(String code, {int count = 60}) async {
    try {
      _kLineData = await _apiService.fetchKLineData(code, count: count);
      notifyListeners();
    } catch (e) {
      print('获取K线数据失败: $e');
    }
  }

  /// 添加自选股
  Future<void> addToWatchList(String code) async {
    if (!_watchList.contains(code)) {
      _watchList.add(code);
      await _saveWatchList();
      await fetchStocks();
      notifyListeners();
    }
  }

  /// 移除自选股
  Future<void> removeFromWatchList(String code) async {
    _watchList.remove(code);
    await _saveWatchList();
    _stocks.removeWhere((s) => s.code == code);
    notifyListeners();
  }

  /// 搜索股票
  Future<List<Map<String, String>>> searchStocks(String keyword) async {
    return await _apiService.searchStocks(keyword);
  }

  /// 开始自动刷新
  void startAutoRefresh() {
    stopAutoRefresh();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: refreshInterval),
      (_) => fetchStocks(),
    );
  }

  /// 停止自动刷新
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// 获取股票当前价格
  double? getStockPrice(String code) {
    try {
      return _stocks.firstWhere((s) => s.code == code).currentPrice;
    } catch (e) {
      return null;
    }
  }

  /// 获取股票名称
  String? getStockName(String code) {
    try {
      return _stocks.firstWhere((s) => s.code == code).name;
    } catch (e) {
      // 从默认列表查找
      final stock = StockList.defaultStocks.firstWhere(
        (s) => s['code'] == code,
        orElse: () => {'code': code, 'name': code},
      );
      return stock['name'];
    }
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}
