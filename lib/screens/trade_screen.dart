import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/stock.dart';
import '../models/portfolio.dart';
import '../providers/portfolio_provider.dart';

/// 交易页面
class TradeScreen extends StatefulWidget {
  final Stock stock;
  final TradeType tradeType;
  final int? maxQuantity;

  const TradeScreen({
    Key? key,
    required this.stock,
    required this.tradeType,
    this.maxQuantity,
  }) : super(key: key);

  @override
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> {
  final TextEditingController _quantityController = TextEditingController();
  int _quantity = 100;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _quantityController.text = _quantity.toString();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBuy = widget.tradeType == TradeType.buy;
    final color = isBuy ? Colors.red : Colors.green;
    final actionText = isBuy ? '买入' : '卖出';

    return Scaffold(
      appBar: AppBar(
        title: Text('$actionText ${widget.stock.name}'),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: Consumer<PortfolioProvider>(
        builder: (context, provider, child) {
          final availableCash = provider.availableCash;
          final maxBuyQuantity = (availableCash / widget.stock.currentPrice).floor();
          final maxSellQuantity = widget.maxQuantity ?? 0;
          final maxQuantity = isBuy ? maxBuyQuantity : maxSellQuantity;

          // 计算预估金额
          final estimatedAmount = _quantity * widget.stock.currentPrice;
          final fee = estimatedAmount * 0.0003; // 手续费
          final stampDuty = isBuy ? 0 : estimatedAmount * 0.001; // 印花税（卖出）
          final totalAmount = isBuy
              ? estimatedAmount + fee
              : estimatedAmount - fee - stampDuty;

          return Column(
            children: [
              // 股票信息卡片
              _buildStockInfoCard(color),

              // 可用资金/持仓信息
              _buildAccountInfoCard(provider, isBuy, maxQuantity),

              const SizedBox(height: 16),

              // 数量输入
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '交易数量',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _quantity > 100
                              ? () => _updateQuantity(_quantity - 100)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12),
                              suffixText: '股',
                            ),
                            onChanged: (value) {
                              setState(() {
                                _quantity = int.tryParse(value) ?? 0;
                              });
                            },
                          ),
                        ),
                        IconButton(
                          onPressed: () => _updateQuantity(_quantity + 100),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),

                    // 快捷数量按钮
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildQuantityButton('100', 100),
                        _buildQuantityButton('500', 500),
                        _buildQuantityButton('1000', 1000),
                        if (maxQuantity > 0)
                          _buildQuantityButton('全仓', maxQuantity),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 费用明细
              _buildFeeCard(
                estimatedAmount.toDouble(),
                fee.toDouble(),
                stampDuty.toDouble(),
                totalAmount.toDouble(),
                isBuy,
              ),

              const SizedBox(height: 16),

              // 提交按钮
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitting || _quantity <= 0 || _quantity > maxQuantity
                        ? null
                        : () => _submitTrade(context, provider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            '$actionText $_quantity股',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),

              // 错误提示
              if (provider.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    provider.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  /// 构建股票信息卡片
  Widget _buildStockInfoCard(Color color) {
    final isUp = widget.stock.isUp;
    final changeColor = isUp ? Colors.red : Colors.green;
    final changeSymbol = isUp ? '+' : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: color.withOpacity(0.2)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.stock.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatCode(widget.stock.code),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.stock.currentPrice.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: changeColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$changeSymbol${widget.stock.changePercent.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: changeColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建账户信息卡片
  Widget _buildAccountInfoCard(PortfolioProvider provider, bool isBuy, int maxQuantity) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBuy ? '可用资金' : '可卖数量',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isBuy
                      ? '¥${provider.availableCash.toStringAsFixed(2)}'
                      : '${widget.maxQuantity ?? 0}股',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (isBuy)
              Text(
                '最多可买 ${maxQuantity > 0 ? maxQuantity : 0}股',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建数量按钮
  Widget _buildQuantityButton(String label, int quantity) {
    return OutlinedButton(
      onPressed: () => _updateQuantity(quantity),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label),
    );
  }

  /// 构建费用卡片
  Widget _buildFeeCard(
    double estimatedAmount,
    double fee,
    double stampDuty,
    double totalAmount,
    bool isBuy,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildFeeRow('成交金额', '¥${estimatedAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 4),
            _buildFeeRow('手续费 (0.03%)', '¥${fee.toStringAsFixed(2)}'),
            if (!isBuy) ...[
              const SizedBox(height: 4),
              _buildFeeRow('印花税 (0.1%)', '¥${stampDuty.toStringAsFixed(2)}'),
            ],
            const Divider(height: 16),
            _buildFeeRow(
              isBuy ? '预估总支出' : '预估总收入',
              '¥${totalAmount.toStringAsFixed(2)}',
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建费用行
  Widget _buildFeeRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  /// 更新数量
  void _updateQuantity(int quantity) {
    setState(() {
      _quantity = quantity;
      _quantityController.text = quantity.toString();
    });
  }

  /// 提交交易
  Future<void> _submitTrade(BuildContext context, PortfolioProvider provider) async {
    if (_quantity <= 0) return;

    setState(() {
      _isSubmitting = true;
    });

    provider.clearError();

    if (widget.tradeType == TradeType.buy) {
      await provider.buyStock(widget.stock, _quantity);
    } else {
      await provider.sellStock(widget.stock, _quantity);
    }

    setState(() {
      _isSubmitting = false;
    });

    if (provider.error == null) {
      // 交易成功
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('交易成功'),
            content: Text(
              '${widget.tradeType == TradeType.buy ? '买入' : '卖出'} ${widget.stock.name} $_quantity股',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // 关闭对话框
                  Navigator.pop(context); // 返回上一页
                },
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
    }
  }

  /// 格式化股票代码
  String _formatCode(String code) {
    if (code.startsWith('sh')) {
      return 'SH${code.substring(2)}';
    } else if (code.startsWith('sz')) {
      return 'SZ${code.substring(2)}';
    } else if (code.startsWith('bj'))
{
      return 'BJ${code.substring(2)}';
    }
    return code.toUpperCase();
  }
}
