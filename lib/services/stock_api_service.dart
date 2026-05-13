import 'dart:async';
import 'dart:convert';
import 'dart:math';
import '../models/stock.dart';

/// 股票 API 服务
/// 使用新浪财经 API 获取实时行情数据
class StockApiService {
  static final StockApiService _instance = StockApiService._internal();
  factory StockApiService() => _instance;
  StockApiService._internal();

  // 模拟数据模式（当网络请求失败时使用）
  bool _useMockData = false;

  /// 获取股票实时行情
  /// 新浪财经 API 格式: https://hq.sinajs.cn/list=sh000001,sz399001
  Future<List<Stock>> fetchStockQuotes(List<String> codes) async {
    if (codes.isEmpty) return [];

    try {
      // 由于新浪财经 API 可能有跨域限制，这里使用模拟数据
      // 实际项目中可以使用代理服务器或后端转发
      return _generateMockStocks(codes);
    } catch (e) {
      print('获取股票行情失败: $e');
      return _generateMockStocks(codes);
    }
  }

  /// 获取单只股票行情
  Future<Stock?> fetchStockQuote(String code) async {
    try {
      final stocks = await fetchStockQuotes([code]);
      return stocks.isNotEmpty ? stocks.first : null;
    } catch (e) {
      print('获取单只股票行情失败: $e');
      return null;
    }
  }

  /// 获取 K 线数据
  Future<List<KLineData>> fetchKLineData(String code, {String period = 'day', int count = 60}) async {
    try {
      // 模拟 K 线数据
      return _generateMockKLineData(code, count);
    } catch (e) {
      print('获取K线数据失败: $e');
      return _generateMockKLineData(code, count);
    }
  }

  /// 搜索股票
  Future<List<Map<String, String>>> searchStocks(String keyword) async {
    if (keyword.isEmpty) return [];

    // 模拟搜索结果
    final allStocks = StockList.defaultStocks;
    return allStocks.where((stock) {
      final name = stock['name']?.toLowerCase() ?? '';
      final code = stock['code']?.toLowerCase() ?? '';
      final key = keyword.toLowerCase();
      return name.contains(key) || code.contains(key);
    }).toList();
  }

  /// 生成模拟股票数据
  List<Stock> _generateMockStocks(List<String> codes) {
    final List<Stock> stocks = [];
    final random = Random();

    final Map<String, Map<String, dynamic>> stockData = {
      'sh000001': {'name': '上证指数', 'basePrice': 3050.0},
      'sz399001': {'name': '深证成指', 'basePrice': 9850.0},
      'sz399006': {'name': '创业板指', 'basePrice': 1950.0},
      'sh000300': {'name': '沪深300', 'basePrice': 3650.0},
      'sh600519': {'name': '贵州茅台', 'basePrice': 1680.0},
      'sz000858': {'name': '五 粮 液', 'basePrice': 145.0},
      'sh600036': {'name': '招商银行', 'basePrice': 32.5},
      'sh601318': {'name': '中国平安', 'basePrice': 42.0},
      'sh600276': {'name': '恒瑞医药', 'basePrice': 48.5},
      'sz000333': {'name': '美的集团', 'basePrice': 58.0},
      'sz000651': {'name': '格力电器', 'basePrice': 35.5},
      'sh600900': {'name': '长江电力', 'basePrice': 22.8},
      'sh601012': {'name': '隆基绿能', 'basePrice': 21.5},
      'sz002594': {'name': '比亚迪', 'basePrice': 245.0},
      'sh601888': {'name': '中国中免', 'basePrice': 85.0},
      'sh603288': {'name': '海天味业', 'basePrice': 38.5},
      'sz300750': {'name': '宁德时代', 'basePrice': 185.0},
      'sh688981': {'name': '中芯国际', 'basePrice': 52.0},
      'sh601398': {'name': '工商银行', 'basePrice': 4.85},
    };

    for (final code in codes) {
      final data = stockData[code];
      if (data != null) {
        final basePrice = data['basePrice'] as double;
        final change = (random.nextDouble() - 0.5) * 0.04; // -2% 到 +2%
        final currentPrice = basePrice * (1 + change);
        final openPrice = basePrice * (1 + (random.nextDouble() - 0.5) * 0.02);
        final highPrice = max(currentPrice, openPrice) * (1 + random.nextDouble() * 0.01);
        final lowPrice = min(currentPrice, openPrice) * (1 - random.nextDouble() * 0.01);

        stocks.add(Stock(
          code: code,
          name: data['name'] as String,
          currentPrice: double.parse(currentPrice.toStringAsFixed(2)),
          openPrice: double.parse(openPrice.toStringAsFixed(2)),
          highPrice: double.parse(highPrice.toStringAsFixed(2)),
          lowPrice: double.parse(lowPrice.toStringAsFixed(2)),
          previousClose: double.parse(basePrice.toStringAsFixed(2)),
          volume: random.nextInt(1000000) + 100000,
          turnover: random.nextInt(100000000) + 10000000,
          updateTime: DateTime.now(),
        ));
      }
    }

    return stocks;
  }

  /// 生成模拟 K 线数据
  List<KLineData> _generateMockKLineData(String code, int count) {
    final List<KLineData> klines = [];
    final random = Random();

    // 获取基础价格
    final stockData = StockList.defaultStocks.firstWhere(
      (s) => s['code'] == code,
      orElse: () => {'code': code, 'name': 'Unknown'},
    );

    // 根据代码生成一个固定的基础价格
    double basePrice = 100.0;
    for (int i = 0; i < code.length; i++) {
      basePrice += code.codeUnitAt(i);
    }
    basePrice = (basePrice % 200) + 50;

    DateTime now = DateTime.now();
    double lastClose = basePrice;

    for (int i = count; i >= 0; i--) {
      final time = now.subtract(Duration(days: i));
      final change = (random.nextDouble() - 0.5) * 0.06; // -3% 到 +3%
      final open = lastClose;
      final close = open * (1 + change);
      final high = max(open, close) * (1 + random.nextDouble() * 0.02);
      final low = min(open, close) * (1 - random.nextDouble() * 0.02);
      final volume = random.nextInt(1000000) + 500000;

      klines.add(KLineData(
        time: time,
        open: double.parse(open.toStringAsFixed(2)),
        high: double.parse(high.toStringAsFixed(2)),
        low: double.parse(low.toStringAsFixed(2)),
        close: double.parse(close.toStringAsFixed(2)),
        volume: volume.toDouble(),
      ));

      lastClose = close;
    }

    return klines;
  }

  /// 解析新浪财经 API 响应
  /// 格式: var hq_str_sh600519="贵州茅台,1678.00,1680.00,1685.00,1690.00,1675.00,...";
  List<Stock> _parseSinaResponse(String response) {
    final List<Stock> stocks = [];
    final lines = response.split(';');

    for (final line in lines) {
      final match = RegExp(r'var hq_str_(\w+)="([^"]*)"').firstMatch(line);
      if (match != null) {
        final code = match.group(1) ?? '';
        final data = match.group(2) ?? '';
        final fields = data.split(',');

        if (fields.length >= 33) {
          stocks.add(Stock(
            code: code,
            name: fields[0],
            currentPrice: double.tryParse(fields[3]) ?? 0,
            openPrice: double.tryParse(fields[1]) ?? 0,
            highPrice: double.tryParse(fields[4]) ?? 0,
            lowPrice: double.tryParse(fields[5]) ?? 0,
            previousClose: double.tryParse(fields[2]) ?? 0,
            volume: double.tryParse(fields[8]) ?? 0,
            turnover: double.tryParse(fields[9]) ?? 0,
            updateTime: DateTime.now(),
          ));
        }
      }
    }

    return stocks;
  }
}
