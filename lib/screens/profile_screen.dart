import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/portfolio_provider.dart';

/// 我的页面
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
      ),
      body: ListView(
        children: [
          // 用户信息头部
          _buildUserHeader(context),

          const SizedBox(height: 16),

          // 资产概览
          _buildAssetOverview(context),

          const SizedBox(height: 16),

          // 功能列表
          _buildFunctionList(context),

          const SizedBox(height: 16),

          // 设置列表
          _buildSettingsList(context),

          const SizedBox(height: 32),

          // 版本信息
          Center(
            child: Text(
              '投资顾问 v1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// 构建用户头部
  Widget _buildUserHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 头像
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person,
                size: 40,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '模拟投资者',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'VIP用户',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建资产概览
  Widget _buildAssetOverview(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        final totalAssets = provider.totalAssets;
        final totalProfitLoss = provider.totalProfitLoss;
        final totalProfitLossPercent = provider.totalProfitLossPercent;
        final isProfit = totalProfitLoss >= 0;
        final profitColor = isProfit ? Colors.red : Colors.green;
        final profitSymbol = isProfit ? '+' : '';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '模拟资产概览',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildAssetItem(
                        '总资产',
                        '¥${totalAssets.toStringAsFixed(2)}',
                        Icons.account_balance_wallet,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildAssetItem(
                        '累计盈亏',
                        '$profitSymbol${totalProfitLoss.toStringAsFixed(2)}',
                        isProfit ? Icons.trending_up : Icons.trending_down,
                        profitColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: (totalProfitLossPercent + 100) / 200, // 映射到 0-1
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(profitColor),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '盈亏比例: $profitSymbol${totalProfitLossPercent.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: profitColor,
                      ),
                    ),
                    Text(
                      '初始资金: ¥${provider.initialCapital.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建资产项
  Widget _buildAssetItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建功能列表
  Widget _buildFunctionList(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildListTile(
            icon: Icons.history,
            title: '交易记录',
            subtitle: '查看所有模拟交易记录',
            onTap: () {
              // 跳转到持仓页的交易记录标签
            },
          ),
          const Divider(height: 1),
          _buildListTile(
            icon: Icons.pie_chart,
            title: '持仓分析',
            subtitle: '分析持仓分布和收益',
            onTap: () {
              // 显示持仓分析
            },
          ),
          const Divider(height: 1),
          _buildListTile(
            icon: Icons.notifications,
            title: '价格提醒',
            subtitle: '设置股票价格提醒',
            onTap: () {
              // 价格提醒功能
            },
          ),
        ],
      ),
    );
  }

  /// 构建设置列表
  Widget _buildSettingsList(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildListTile(
            icon: Icons.refresh,
            title: '重置模拟盘',
            subtitle: '清空所有持仓和交易记录',
            iconColor: Colors.orange,
            onTap: () {
              _showResetDialog(context);
            },
          ),
          const Divider(height: 1),
          _buildListTile(
            icon: Icons.help_outline,
            title: '使用帮助',
            subtitle: '了解如何使用模拟交易功能',
            onTap: () {
              _showHelpDialog(context);
            },
          ),
          const Divider(height: 1),
          _buildListTile(
            icon: Icons.info_outline,
            title: '关于',
            subtitle: '应用信息和免责声明',
            onTap: () {
              _showAboutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  /// 构建列表项
  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? Colors.blue).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor ?? Colors.blue),
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  /// 显示重置对话框
  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置模拟盘'),
        content: const Text(
          '确定要重置模拟盘吗？这将清空所有持仓和交易记录，初始资金将恢复为100万元。此操作不可撤销。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<PortfolioProvider>().resetPortfolio();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('模拟盘已重置')),
                );
              }
            },
            child: const Text('确定重置', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 显示帮助对话框
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('使用帮助'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '模拟交易说明',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. 初始资金为100万元模拟资金'),
              Text('2. 买入股票需支付0.03%手续费'),
              Text('3. 卖出股票需支付0.03%手续费和0.1%印花税'),
              Text('4. 交易数量为100股的整数倍'),
              SizedBox(height: 16),
              Text(
                '数据来源',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('行情数据仅供参考，不构成投资建议。实际交易请以证券交易所数据为准。'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  /// 显示关于对话框
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关于投资顾问'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('投资顾问是一款股票行情监控和模拟交易应用。'),
            SizedBox(height: 16),
            Text(
              '免责声明',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '本应用提供的行情数据仅供参考，不构成任何投资建议。股市有风险，投资需谨慎。用户据此操作，风险自担。',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
