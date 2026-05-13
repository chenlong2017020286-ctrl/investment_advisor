import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/market_provider.dart';
import '../providers/portfolio_provider.dart';
import '../models/portfolio.dart';
import 'stock_detail_screen.dart';
import 'trade_screen.dart';

/// 持仓页
class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({Key? key}) : super(key: key);

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('模拟持仓'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '持仓', icon: Icon(Icons.pie_chart)),
            Tab(text: '交易记录', icon: Icon(Icons.history)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<MarketProvider>().fetchStocks();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PositionsTab(),
          TradeHistoryTab(),
        ],
      ),
    );
  }
}

/// 持仓列表标签页
class PositionsTab extends StatelessWidget {
  const PositionsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<PortfolioProvider, MarketProvider>(
      builder: (context, portfolioProvider, marketProvider, child) {
        // 更新价格
        if (marketProvider.stocks.isNotEmpty) {
          final prices = <String, double>{};
          for (var stock in marketProvider.stocks) {
            prices[stock.code] = stock.currentPrice;
          }
          portfolioProvider.updatePrices(prices);
        }

        final portfolio = portfolioProvider.portfolio;
        final positions = portfolio.positions;

        if (positions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  '暂无持仓',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  '去行情页面选择股票进行模拟交易',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // 资产概览卡片
            _buildAssetCard(portfolioProvider),

            // 持仓列表
            Expanded(
              child: ListView.builder(
                itemCount: positions.length,
                itemBuilder: (context, index) {
                  final position = positions[index];
                  final currentPrice = portfolioProvider.portfolio.cash; // 占位
                  final stockName = marketProvider.getStockName(position.code) ?? position.name;

                  return _buildPositionItem(
                    context,
                    position,
                    stockName,
                    portfolioProvider,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// 构建资产卡片
  Widget _buildAssetCard(PortfolioProvider provider) {
    final totalAssets = provider.totalAssets;
    final totalProfitLoss = provider.totalProfitLoss;
    final totalProfitLossPercent = provider.totalProfitLossPercent;
    final availableCash = provider.availableCash;
    final positionsValue = provider.positionsMarketValue;

    final isProfit = totalProfitLoss >= 0;
    final profitColor = isProfit ? Colors.red : Colors.green;
    final profitSymbol = isProfit ? '+' : '';

    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '总资产',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              '¥${totalAssets.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: profitColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$profitSymbol${totalProfitLoss.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: profitColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$profitSymbol${totalProfitLossPercent.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: profitColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAssetInfoItem('可用资金', '¥${availableCash.toStringAsFixed(2)}'),
                _buildAssetInfoItem('持仓市值', '¥${positionsValue.toStringAsFixed(2)}'),
                _buildAssetInfoItem('初始资金', '¥${provider.initialCapital.toStringAsFixed(2)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建资产信息项
  Widget _buildAssetInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 构建持仓项
  Widget _buildPositionItem(
    BuildContext context,
    Position position,
    String stockName,
    PortfolioProvider provider,
  ) {
    final marketValue = provider.getPositionMarketValue(position.code);
    final profitLoss = provider.getPositionProfitLoss(position.code);
    final profitLossPercent = provider.getPositionProfitLossPercent(position.code);
    final isProfit = profitLoss >= 0;
    final profitColor = isProfit ? Colors.red : Colors.green;
    final profitSymbol = isProfit ? '+' : '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StockDetailScreen(stockCode: position.code),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stockName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatCode(position.code),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '¥${marketValue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '$profitSymbol${profitLoss.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: profitColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: profitColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              '$profitSymbol${profitLossPercent.toStringAsFixed(2)}%',
                              style: TextStyle(
                                fontSize: 10,
                                color: profitColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPositionDetail('持仓数量', '${position.quantity}股'),
                  _buildPositionDetail('平均成本', '¥${position.avgCost.toStringAsFixed(2)}'),
                  _buildPositionDetail('当前价', '¥${(marketValue / position.quantity).toStringAsFixed(2)}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建持仓详情
  Widget _buildPositionDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
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
}

/// 交易记录标签页
class TradeHistoryTab extends StatelessWidget {
  const TradeHistoryTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<PortfolioProvider, MarketProvider>(
      builder: (context, portfolioProvider, marketProvider, child) {
        final trades = portfolioProvider.portfolio.trades.reversed.toList();

        if (trades.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  '暂无交易记录',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: trades.length,
          itemBuilder: (context, index) {
            final trade = trades[index];
            final stockName = marketProvider.getStockName(trade.code) ?? trade.name;
            final isBuy = trade.type == TradeType.buy;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isBuy ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isBuy ? Colors.red : Colors.green,
                  ),
                ),
                title: Text(stockName),
                subtitle: Text(
                  '${DateFormat('yyyy-MM-dd HH:mm').format(trade.tradeTime)} · ${_formatCode(trade.code)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isBuy ? '买入' : '卖出'} ${trade.quantity}股',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isBuy ? Colors.red : Colors.green,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '¥${trade.price.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
}
