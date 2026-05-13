import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/stock.dart';

/// K 线图组件
class KLineChart extends StatefulWidget {
  final List<KLineData> data;
  final bool showVolume;

  const KLineChart({
    Key? key,
    required this.data,
    this.showVolume = true,
  }) : super(key: key);

  @override
  State<KLineChart> createState() => _KLineChartState();
}

class _KLineChartState extends State<KLineChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const Center(
        child: Text('暂无数据', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: [
        // K线图
        Expanded(
          flex: 3,
          child: _buildCandlestickChart(),
        ),
        // 成交量图
        if (widget.showVolume) ...[
          const SizedBox(height: 8),
          Expanded(
            flex: 1,
            child: _buildVolumeChart(),
          ),
        ],
      ],
    );
  }

  /// 构建K线图
  Widget _buildCandlestickChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: _calculatePriceInterval(),
          verticalInterval: (widget.data.length / 5).toDouble(),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(2),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (widget.data.length / 5).toDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < widget.data.length) {
                  final date = widget.data[index].time;
                  return Text(
                    DateFormat('MM/dd').format(date),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        minX: 0,
        maxX: (widget.data.length - 1).toDouble(),
        minY: _getMinPrice() * 0.98,
        maxY: _getMaxPrice() * 1.02,
        lineBarsData: [
          // 收盘价线
          LineChartBarData(
            spots: widget.data.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.close);
            }).toList(),
            isCurved: false,
            color: Colors.blue,
            barWidth: 1.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.black87,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index >= 0 && index < widget.data.length) {
                  final kline = widget.data[index];
                  return LineTooltipItem(
                    '${DateFormat('yyyy-MM-dd').format(kline.time)}\n'
                    '开: ${kline.open.toStringAsFixed(2)}\n'
                    '高: ${kline.high.toStringAsFixed(2)}\n'
                    '低: ${kline.low.toStringAsFixed(2)}\n'
                    '收: ${kline.close.toStringAsFixed(2)}',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            // 平均线
            HorizontalLine(
              y: _getAveragePrice(),
              color: Colors.orange.withOpacity(0.5),
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建成交量图
  Widget _buildVolumeChart() {
    final maxVolume = _getMaxVolume();

    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const Text('');
                return Text(
                  _formatVolume(value),
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        minY: 0,
        maxY: maxVolume * 1.2,
        barGroups: widget.data.asMap().entries.map((e) {
          final index = e.key;
          final kline = e.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: kline.volume,
                color: kline.isUp ? Colors.red : Colors.green,
                width: 4,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(2),
                ),
              ),
            ],
          );
        }).toList(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.black87,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final kline = widget.data[groupIndex];
              return BarTooltipItem(
                '成交量: ${_formatVolume(kline.volume)}',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
      ),
    );
  }

  /// 计算价格间隔
  double _calculatePriceInterval() {
    final range = _getMaxPrice() - _getMinPrice();
    return range / 5;
  }

  /// 获取最低价格
  double _getMinPrice() {
    if (widget.data.isEmpty) return 0;
    return widget.data.map((e) => e.low).reduce((a, b) => a < b ? a : b);
  }

  /// 获取最高价格
  double _getMaxPrice() {
    if (widget.data.isEmpty) return 0;
    return widget.data.map((e) => e.high).reduce((a, b) => a > b ? a : b);
  }

  /// 获取平均价格
  double _getAveragePrice() {
    if (widget.data.isEmpty) return 0;
    final sum = widget.data.map((e) => e.close).reduce((a, b) => a + b);
    return sum / widget.data.length;
  }

  /// 获取最大成交量
  double _getMaxVolume() {
    if (widget.data.isEmpty) return 0;
    return widget.data.map((e) => e.volume).reduce((a, b) => a > b ? a : b);
  }

  /// 格式化成交量
  String _formatVolume(double volume) {
    if (volume >= 100000000) {
      return '${(volume / 100000000).toStringAsFixed(1)}亿';
    } else if (volume >= 10000) {
      return '${(volume / 10000).toStringAsFixed(1)}万';
    }
    return volume.toStringAsFixed(0);
  }
}

/// 简化的价格走势图
class PriceLineChart extends StatelessWidget {
  final List<double> prices;
  final Color? lineColor;
  final bool showGradient;
  final double height;

  const PriceLineChart({
    Key? key,
    required this.prices,
    this.lineColor,
    this.showGradient = true,
    this.height = 60,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (prices.isEmpty) {
      return SizedBox(height: height);
    }

    final color = lineColor ??
        (prices.last >= prices.first ? Colors.red : Colors.green);

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (prices.length - 1).toDouble(),
          minY: prices.reduce((a, b) => a < b ? a : b) * 0.99,
          maxY: prices.reduce((a, b) => a > b ? a : b) * 1.01,
          lineBarsData: [
            LineChartBarData(
              spots: prices.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value);
              }).toList(),
              isCurved: true,
              color: color,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: showGradient
                  ? BarAreaData(
                      show: true,
                      color: color.withOpacity(0.2),
                    )
                  : BarAreaData(show: false),
            ),
          ],
          lineTouchData: const LineTouchData(enabled: false),
        ),
      ),
    );
  }
}

/// 迷你K线指示器
class MiniKLineIndicator extends StatelessWidget {
  final List<KLineData> data;
  final double height;
  final double width;

  const MiniKLineIndicator({
    Key? key,
    required this.data,
    this.height = 40,
    this.width = 80,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(height: height, width: width);
    }

    final closes = data.map((e) => e.close).toList();
    final isUp = closes.last >= closes.first;
    final color = isUp ? Colors.red : Colors.green;

    return SizedBox(
      height: height,
      width: width,
      child: CustomPaint(
        painter: _MiniKLinePainter(data: data, color: color),
      ),
    );
  }
}

/// 迷你K线绘制器
class _MiniKLinePainter extends CustomPainter {
  final List<KLineData> data;
  final Color color;

  _MiniKLinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final minPrice = data.map((e) => e.low).reduce((a, b) => a < b ? a : b);
    final maxPrice = data.map((e) => e.high).reduce((a, b) => a > b ? a : b);
    final priceRange = maxPrice - minPrice;

    if (priceRange == 0) return;

    final path = Path();
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final kline = data[i];
      final x = i * stepX;
      final y = size.height - ((kline.close - minPrice) / priceRange) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
