import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/stock.dart';

/// 股票列表项组件
class StockListItem extends StatelessWidget {
  final Stock stock;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showRemoveButton;
  final VoidCallback? onRemove;

  const StockListItem({
    Key? key,
    required this.stock,
    this.onTap,
    this.onLongPress,
    this.showRemoveButton = false,
    this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUp = stock.isUp;
    final color = isUp ? Colors.red : Colors.green;
    final changeSymbol = isUp ? '+' : '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 股票代码和名称
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stock.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCode(stock.code),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // 当前价格
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      stock.currentPrice.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '成交量: ${_formatVolume(stock.volume)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // 涨跌幅
              Container(
                width: 80,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    Text(
                      '$changeSymbol${stock.changePercent.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      '$changeSymbol${stock.changeAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),

              // 删除按钮
              if (showRemoveButton) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                  onPressed: onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
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
}

/// 股票行情摘要卡片
class MarketSummaryCard extends StatelessWidget {
  final List<Stock> stocks;

  const MarketSummaryCard({
    Key? key,
    required this.stocks,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (stocks.isEmpty) return const SizedBox.shrink();

    // 获取主要指数
    final indices = stocks.where((s) =>
      s.code == 'sh000001' ||
      s.code == 'sz399001' ||
      s.code == 'sz399006' ||
      s.code == 'sh000300'
    ).toList();

    if (indices.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '主要指数',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: indices.map((stock) {
                return Expanded(
                  child: _IndexItem(stock: stock),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// 指数项
class _IndexItem extends StatelessWidget {
  final Stock stock;

  const _IndexItem({required this.stock});

  @override
  Widget build(BuildContext context) {
    final isUp = stock.isUp;
    final color = isUp ? Colors.red : Colors.green;
    final changeSymbol = isUp ? '+' : '';

    return Column(
      children: [
        Text(
          stock.name,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          stock.currentPrice.toStringAsFixed(2),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$changeSymbol${stock.changePercent.toStringAsFixed(2)}%',
          style: TextStyle(
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// 股票代码标签
class StockCodeChip extends StatelessWidget {
  final String code;
  final Color? backgroundColor;
  final Color? textColor;

  const StockCodeChip({
    Key? key,
    required this.code,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String formattedCode = code;
    Color chipColor = Colors.blue;

    if (code.startsWith('sh')) {
      formattedCode = 'SH${code.substring(2)}';
      chipColor = Colors.red;
    } else if (code.startsWith('sz')) {
      formattedCode = 'SZ${code.substring(2)}';
      chipColor = Colors.blue;
    } else if (code.startsWith('bj')) {
      formattedCode = 'BJ${code.substring(2)}';
      chipColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (backgroundColor ?? chipColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        formattedCode,
        style: TextStyle(
          fontSize: 10,
          color: textColor ?? chipColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// 价格变化指示器
class PriceChangeIndicator extends StatelessWidget {
  final double changePercent;
  final double? changeAmount;
  final bool showAmount;
  final TextStyle? percentStyle;
  final TextStyle? amountStyle;

  const PriceChangeIndicator({
    Key? key,
    required this.changePercent,
    this.changeAmount,
    this.showAmount = true,
    this.percentStyle,
    this.amountStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUp = changePercent >= 0;
    final color = isUp ? Colors.red : Colors.green;
    final symbol = isUp ? '+' : '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$symbol${changePercent.toStringAsFixed(2)}%',
            style: percentStyle ?? TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        if (showAmount && changeAmount != null) ...[
          const SizedBox(width: 4),
          Text(
            '$symbol${changeAmount!.toStringAsFixed(2)}',
            style: amountStyle ?? TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ],
    );
  }
}
