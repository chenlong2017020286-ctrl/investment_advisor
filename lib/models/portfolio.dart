import 'stock.dart';

/// 持仓记录
class Position {
  final String code; // 股票代码
  final String name; // 股票名称
  int quantity; // 持仓数量
  double avgCost; // 平均成本
  DateTime firstBuyTime; // 首次买入时间
  DateTime lastUpdateTime; // 最后更新时间

  Position({
    required this.code,
    required this.name,
    required this.quantity,
    required this.avgCost,
    required this.firstBuyTime,
    required this.lastUpdateTime,
  });

  /// 计算当前市值
  double marketValue(double currentPrice) => quantity * currentPrice;

  /// 计算盈亏金额
  double profitLoss(double currentPrice) => quantity * (currentPrice - avgCost);

  /// 计算盈亏比例
  double profitLossPercent(double currentPrice) {
    if (avgCost == 0) return 0;
    return ((currentPrice - avgCost) / avgCost) * 100;
  }

  /// 是否盈利
  bool isProfit(double currentPrice) => currentPrice > avgCost;

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      avgCost: (json['avgCost'] ?? 0).toDouble(),
      firstBuyTime: DateTime.parse(json['firstBuyTime'] ?? DateTime.now().toIso8601String()),
      lastUpdateTime: DateTime.parse(json['lastUpdateTime'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'quantity': quantity,
      'avgCost': avgCost,
      'firstBuyTime': firstBuyTime.toIso8601String(),
      'lastUpdateTime': lastUpdateTime.toIso8601String(),
    };
  }
}

/// 交易记录
class Trade {
  final String id; // 交易ID
  final String code; // 股票代码
  final String name; // 股票名称
  final TradeType type; // 交易类型
  final int quantity; // 交易数量
  final double price; // 交易价格
  final double totalAmount; // 总金额
  final DateTime tradeTime; // 交易时间
  final double fee; // 手续费

  Trade({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.quantity,
    required this.price,
    required this.totalAmount,
    required this.tradeTime,
    this.fee = 0,
  });

  factory Trade.fromJson(Map<String, dynamic> json) {
    return Trade(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      type: TradeType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => TradeType.buy,
      ),
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      tradeTime: DateTime.parse(json['tradeTime'] ?? DateTime.now().toIso8601String()),
      fee: (json['fee'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'type': type.toString(),
      'quantity': quantity,
      'price': price,
      'totalAmount': totalAmount,
      'tradeTime': tradeTime.toIso8601String(),
      'fee': fee,
    };
  }
}

/// 交易类型
enum TradeType {
  buy, // 买入
  sell, // 卖出
}

/// 投资组合
class Portfolio {
  double cash; // 可用现金
  List<Position> positions; // 持仓列表
  List<Trade> trades; // 交易记录
  final double initialCapital; // 初始资金

  Portfolio({
    required this.cash,
    required this.positions,
    required this.trades,
    this.initialCapital = 1000000, // 默认100万
  });

  /// 计算持仓总市值
  double positionsMarketValue(Map<String, double> currentPrices) {
    double total = 0;
    for (var position in positions) {
      final price = currentPrices[position.code] ?? position.avgCost;
      total += position.marketValue(price);
    }
    return total;
  }

  /// 计算总资产
  double totalAssets(Map<String, double> currentPrices) {
    return cash + positionsMarketValue(currentPrices);
  }

  /// 计算总盈亏
  double totalProfitLoss(Map<String, double> currentPrices) {
    return totalAssets(currentPrices) - initialCapital;
  }

  /// 计算总盈亏比例
  double totalProfitLossPercent(Map<String, double> currentPrices) {
    if (initialCapital == 0) return 0;
    return (totalProfitLoss(currentPrices) / initialCapital) * 100;
  }

  /// 获取某股票的持仓
  Position? getPosition(String code) {
    try {
      return positions.firstWhere((p) => p.code == code);
    } catch (e) {
      return null;
    }
  }

  /// 买入股票
  void buyStock(Stock stock, int quantity, double price) {
    final totalCost = quantity * price;
    final fee = totalCost * 0.0003; // 0.03% 手续费
    final totalAmount = totalCost + fee;

    if (totalAmount > cash) {
      throw Exception('资金不足');
    }

    // 更新现金
    cash -= totalAmount;

    // 更新或创建持仓
    final existingPosition = getPosition(stock.code);
    if (existingPosition != null) {
      // 更新现有持仓
      final totalQuantity = existingPosition.quantity + quantity;
      final newAvgCost = ((existingPosition.quantity * existingPosition.avgCost) + totalCost) / totalQuantity;
      existingPosition.quantity = totalQuantity;
      existingPosition.avgCost = newAvgCost;
      existingPosition.lastUpdateTime = DateTime.now();
    } else {
      // 创建新持仓
      positions.add(Position(
        code: stock.code,
        name: stock.name,
        quantity: quantity,
        avgCost: price,
        firstBuyTime: DateTime.now(),
        lastUpdateTime: DateTime.now(),
      ));
    }

    // 记录交易
    trades.add(Trade(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      code: stock.code,
      name: stock.name,
      type: TradeType.buy,
      quantity: quantity,
      price: price,
      totalAmount: totalCost,
      tradeTime: DateTime.now(),
      fee: fee,
    ));
  }

  /// 卖出股票
  void sellStock(Stock stock, int quantity, double price) {
    final position = getPosition(stock.code);
    if (position == null || position.quantity < quantity) {
      throw Exception('持仓不足');
    }

    final totalIncome = quantity * price;
    final fee = totalIncome * 0.0003; // 0.03% 手续费
    final stampDuty = totalIncome * 0.001; // 0.1% 印花税
    final totalAmount = totalIncome - fee - stampDuty;

    // 更新现金
    cash += totalAmount;

    // 更新持仓
    position.quantity -= quantity;
    position.lastUpdateTime = DateTime.now();

    // 如果持仓为0，移除持仓
    if (position.quantity == 0) {
      positions.removeWhere((p) => p.code == stock.code);
    }

    // 记录交易
    trades.add(Trade(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      code: stock.code,
      name: stock.name,
      type: TradeType.sell,
      quantity: quantity,
      price: price,
      totalAmount: totalIncome,
      tradeTime: DateTime.now(),
      fee: fee + stampDuty,
    ));
  }

  factory Portfolio.fromJson(Map<String, dynamic> json) {
    return Portfolio(
      cash: (json['cash'] ?? 1000000).toDouble(),
      initialCapital: (json['initialCapital'] ?? 1000000).toDouble(),
      positions: (json['positions'] as List<dynamic>?)
              ?.map((e) => Position.fromJson(e))
              .toList() ??
          [],
      trades: (json['trades'] as List<dynamic>?)
              ?.map((e) => Trade.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cash': cash,
      'initialCapital': initialCapital,
      'positions': positions.map((e) => e.toJson()).toList(),
      'trades': trades.map((e) => e.toJson()).toList(),
    };
  }
}
