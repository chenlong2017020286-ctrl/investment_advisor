import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/stock.dart';
import '../providers/market_provider.dart';
import '../providers/portfolio_provider.dart';
import '../widgets/k_line_chart.dart';
import 'trade_screen.dart';

/// 股票详情页
class StockDetailScreen extends StatefulWidget {
  final String stockCode;

  const StockDetailScreen({
    Key? key,
    required this.stockCode,
  }) : super(key: key);

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  @override
  void initState() {
    super.initState();
    // 加载股票详情
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketProvider>().fetchStockDetail(widget.stockCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<MarketProvider>(
          builder: (context, provider, child) {
            final stock = provider.selectedStock;
            return stock != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stock.name),
                      Text(
                        _formatCode(stock.code),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  )
                : const Text('股票详情');
          },
        ),
        actions: [
          Consumer<MarketProvider>(
            builder: (context, provider, child) {
              final isInWatchList = provider.watchList.contains(widget.stockCode);
              return IconButton(
                icon: Icon(
                  isInWatchList ? Icons.star : Icons.star_border,
                  color: isInWatchList ? Colors.yellow : null,
                ),
                onPressed: () {
                  if (isInWatchList) {
                    provider.removeFromWatchList(widget.stockCode);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已从自选列表移除')),
                    );
                  } else {
                    provider.addToWatchList(widget.stockCode);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已添加到自选列表')),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Consumer2<MarketProvider, PortfolioProvider>(
        builder: (context, marketProvider, portfolioProvider, child) {
          final stock = marketProvider.selectedStock;

          if (stock == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final isUp = stock.isUp;
          final color = isUp ? Colors.red : Colors.green;
          final changeSymbol = isUp ? '+' : '';

          // 更新价格到投资组合
          portfolioProvider.updatePrice(stock.code, stock.currentPrice);

          // 获取持仓信息
          final hasPosition = portfolioProvider.hasPosition(stock.code);
          final positionQty = portfolioProvider.getPositionQuantity(stock.code);
          final avgCost = portfolioProvider.getPositionAvgCost(stock.code);

          return Column(
            children: [
              // 价格信息卡片
              _buildPriceCard(stock, color, changeSymbol),

              // 详细信息网格
              _buildDetailGrid(stock),

              // 持仓信息（如果有）
              if (hasPosition) _buildPositionCard(portfolioProvider, stock, color),

              // K线图
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: KLineChart(
                    data: marketProvider.kLineData,
                    showVolume: true,
                  ),
                ),
              ),

              // 操作按钮
              _buildActionButtons(stock, hasPosition, positionQty),
            ],
          );
        },
      ),
    );
  }

  /// 构建价格卡片
  Widget _buildPriceCard(Stock stock, Color color, String changeSymbol) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(color: color.withOpacity(0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stock.currentPrice.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$changeSymbol${stock.changePercent.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$changeSymbol${stock.changeAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildPriceInfo('最高', stock.highPrice.toStringAsFixed(2)),
              _buildPriceInfo('最低', stock.lowPrice.toStringAsFixed(2)),
              _buildPriceInfo('今开', stock.openPrice.toStringAsFixed(2)),
              _buildPriceInfo('昨收', stock.previousClose.toStringAsFixed(2)),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建价格信息项
  Widget _buildPriceInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建详细信息网格
  Widget _buildDetailGrid(Stock stock) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildDetailItem('成交量', _formatVolume(stock.volume))),
              Expanded(child: _buildDetailItem('成交额', _formatAmount(stock.turnover))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildDetailItem('振幅', '${((stock.highPrice - stock.lowPrice) / stock.previousClose * 100).toStringAsFixed(2)}%')),
              Expanded(child: _buildDetailItem('更新时间', _formatTime(stock.updateTime))),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建详情项
  Widget _buildDetailItem(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// 构建持仓卡片
  Widget _buildPositionCard(PortfolioProvider provider, Stock stock, Color color) {
    final quantity = provider.getPositionQuantity(stock.code);
    final avgCost = provider.getPositionAvgCost(stock.code) ?? 0;
    final marketValue = provider.getPositionMarketValue(stock.code);
    final profitLoss = provider.getPositionProfitLoss(stock.code);
    final profitLossPercent = provider.getPositionProfitLossPercent(stock.code);
    final isProfit = profitLoss >= 0;
    final profitColor = isProfit ? Colors.red : Colors.green;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '我的持仓',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPositionInfo('持仓数量', '$quantity股'),
                _buildPositionInfo('平均成本', avgCost.toStringAsFixed(2)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPositionInfo('当前市值', marketValue.toStringAsFixed(2)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isProfit ? '+' : ''}${profitLoss.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: profitColor,
                      ),
                    ),
                    Text(
                      '${isProfit ? '+' : ''}${profitLossPercent.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: profitColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建持仓信息
  Widget _buildPositionInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons(Stock stock, bool hasPosition, int positionQty) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TradeScreen(
                        stock: stock,
                        tradeType: TradeType.buy,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  '买入',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: hasPosition
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TradeScreen(
                              stock: stock,
                              tradeType: TradeType.sell,
                              maxQuantity: positionQty,
                            ),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: const Text(
                  '卖出',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 格式化股票代码
  String _formatCode(String code) {
    if (code.startsWith('sh')) {
      return 'SH${code.substring(2)}';
    } else if (code.startsWith('sz')) {
      return 'SZ${code.substring(2)}';
    } else if (code.startsWith('bj')) {
      return 'BJ${code.substring(2)}';
    }
    return code.toUpperCase();
  }

  /// 格式化成交量
  String _formatVolume(double volume) {
    if (volume >= 100000000) {
      return '${(volume / 100000000).toStringAsFixed(2)}亿';
    } else if (volume >= 10000) {
      return '${(volume / 10000).toStringAsFixed(2)}万';
    }
    return volume.toStringAsFixed(0);
  }

  /// 格式化成交额
  String _formatAmount(double amount) {
    if (amount >= 100000000) {
      return '${(amount / 100000000).toStringAsFixed(2)}亿';
    } else if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(2)}万';
    }
    return amount.toStringAsFixed(0);
  }

  /// 格式化时间
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}
