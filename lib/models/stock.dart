/// 股票数据模型
class Stock {
  final String code; // 股票代码
  final String name; // 股票名称
  final double currentPrice; // 当前价格
  final double openPrice; // 开盘价
  final double highPrice; // 最高价
  final double lowPrice; // 最低价
  final double previousClose; // 昨收价
  final double volume; // 成交量
  final double turnover; // 成交额
  final DateTime updateTime; // 更新时间

  Stock({
    required this.code,
    required this.name,
    required this.currentPrice,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.previousClose,
    required this.volume,
    required this.turnover,
    required this.updateTime,
  });

  /// 计算涨跌幅
  double get changePercent {
    if (previousClose == 0) return 0;
    return ((currentPrice - previousClose) / previousClose) * 100;
  }

  /// 计算涨跌额
  double get changeAmount => currentPrice - previousClose;

  /// 是否上涨
  bool get isUp => changeAmount >= 0;

  /// 复制并更新数据
  Stock copyWith({
    String? code,
    String? name,
    double? currentPrice,
    double? openPrice,
    double? highPrice,
    double? lowPrice,
    double? previousClose,
    double? volume,
    double? turnover,
    DateTime? updateTime,
  }) {
    return Stock(
      code: code ?? this.code,
      name: name ?? this.name,
      currentPrice: currentPrice ?? this.currentPrice,
      openPrice: openPrice ?? this.openPrice,
      highPrice: highPrice ?? this.highPrice,
      lowPrice: lowPrice ?? this.lowPrice,
      previousClose: previousClose ?? this.previousClose,
      volume: volume ?? this.volume,
      turnover: turnover ?? this.turnover,
      updateTime: updateTime ?? this.updateTime,
    );
  }

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      currentPrice: (json['currentPrice'] ?? 0).toDouble(),
      openPrice: (json['openPrice'] ?? 0).toDouble(),
      highPrice: (json['highPrice'] ?? 0).toDouble(),
      lowPrice: (json['lowPrice'] ?? 0).toDouble(),
      previousClose: (json['previousClose'] ?? 0).toDouble(),
      volume: (json['volume'] ?? 0).toDouble(),
      turnover: (json['turnover'] ?? 0).toDouble(),
      updateTime: DateTime.parse(json['updateTime'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'currentPrice': currentPrice,
      'openPrice': openPrice,
      'highPrice': highPrice,
      'lowPrice': lowPrice,
      'previousClose': previousClose,
      'volume': volume,
      'turnover': turnover,
      'updateTime': updateTime.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Stock(code: $code, name: $name, price: $currentPrice, change: ${changePercent.toStringAsFixed(2)}%)';
  }
}

/// K线数据模型
class KLineData {
  final DateTime time; // 时间
  final double open; // 开盘价
  final double high; // 最高价
  final double low; // 最低价
  final double close; // 收盘价
  final double volume; // 成交量

  KLineData({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  /// 是否上涨
  bool get isUp => close >= open;
}

/// 股票代码列表（预设的热门股票）
class StockList {
  static const List<Map<String, String>> defaultStocks = [
    {'code': 'sh000001', 'name': '上证指数'},
    {'code': 'sz399001', 'name': '深证成指'},
    {'code': 'sz399006', 'name': '创业板指'},
    {'code': 'sh000300', 'name': '沪深300'},
    {'code': 'sh600519', 'name': '贵州茅台'},
    {'code': 'sh000858', 'name': '五粮液'},
    {'code': 'sz000858', 'name': '五 粮 液'},
    {'code': 'sh600036', 'name': '招商银行'},
    {'code': 'sh601318', 'name': '中国平安'},
    {'code': 'sh600276', 'name': '恒瑞医药'},
    {'code': 'sz000333', 'name': '美的集团'},
    {'code': 'sz000651', 'name': '格力电器'},
    {'code': 'sh600900', 'name': '长江电力'},
    {'code': 'sh601012', 'name': '隆基绿能'},
    {'code': 'sz002594', 'name': '比亚迪'},
    {'code': 'sh601888', 'name': '中国中免'},
    {'code': 'sh603288', 'name': '海天味业'},
    {'code': 'sz300750', 'name': '宁德时代'},
    {'code': 'sh688981', 'name': '中芯国际'},
    {'code': 'sh601398', 'name': '工商银行'},
  ];
}
