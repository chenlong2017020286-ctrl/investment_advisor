import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/market_provider.dart';
import '../providers/portfolio_provider.dart';
import '../widgets/stock_list_item.dart';
import 'stock_detail_screen.dart';
import 'portfolio_screen.dart';
import 'profile_screen.dart';

/// 首页 - 行情列表
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MarketListView(),
    const PortfolioScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: '行情',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: '持仓',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}

/// 行情列表视图
class MarketListView extends StatefulWidget {
  const MarketListView({Key? key}) : super(key: key);

  @override
  State<MarketListView> createState() => _MarketListViewState();
}

class _MarketListViewState extends State<MarketListView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('投资顾问'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: StockSearchDelegate(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<MarketProvider>().fetchStocks();
            },
          ),
        ],
      ),
      body: Consumer2<MarketProvider, PortfolioProvider>(
        builder: (context, marketProvider, portfolioProvider, child) {
          // 更新投资组合中的价格
          if (marketProvider.stocks.isNotEmpty) {
            final prices = <String, double>{};
            for (var stock in marketProvider.stocks) {
              prices[stock.code] = stock.currentPrice;
            }
            portfolioProvider.updatePrices(prices);
          }

          if (marketProvider.isLoading && marketProvider.stocks.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (marketProvider.error != null && marketProvider.stocks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(marketProvider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => marketProvider.fetchStocks(),
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => marketProvider.fetchStocks(),
            child: CustomScrollView(
              slivers: [
                // 主要指数
                SliverToBoxAdapter(
                  child: MarketSummaryCard(stocks: marketProvider.stocks),
                ),

                // 股票列表标题
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const Text(
                          '自选股',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '共 ${marketProvider.stocks.length} 只',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 股票列表
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final stock = marketProvider.stocks[index];
                      return StockListItem(
                        stock: stock,
                        showRemoveButton: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StockDetailScreen(
                                stockCode: stock.code,
                              ),
                            ),
                          );
                        },
                        onRemove: () {
                          _showRemoveDialog(context, stock.code, stock.name);
                        },
                      );
                    },
                    childCount: marketProvider.stocks.length,
                  ),
                ),

                const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showSearch(
            context: context,
            delegate: StockSearchDelegate(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showRemoveDialog(BuildContext context, String code, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除自选股'),
        content: Text('确定从自选列表中删除 "$name" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context.read<MarketProvider>().removeFromWatchList(code);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已删除 $name')),
              );
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// 股票搜索委托
class StockSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text('输入股票代码或名称进行搜索'),
      );
    }

    final marketProvider = context.read<MarketProvider>();

    return FutureBuilder<List<Map<String, String>>>(
      future: marketProvider.searchStocks(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('搜索失败: ${snapshot.error}'));
        }

        final results = snapshot.data ?? [];

        if (results.isEmpty) {
          return const Center(child: Text('未找到相关股票'));
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final stock = results[index];
            final code = stock['code'] ?? '';
            final name = stock['name'] ?? '';
            final isInWatchList = marketProvider.watchList.contains(code);

            return ListTile(
              title: Text(name),
              subtitle: Text(code),
              trailing: isInWatchList
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.add_circle_outline),
              onTap: () {
                if (isInWatchList) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$name 已在自选列表中')),
                  );
                } else {
                  marketProvider.addToWatchList(code);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('已添加 $name 到自选列表')),
                  );
                  close(context, code);
                }
              },
            );
          },
        );
      },
    );
  }
}
