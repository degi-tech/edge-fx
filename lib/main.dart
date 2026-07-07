import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'providers/trading_provider.dart';
import 'widgets/ticker_bar.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    print("Firebase init failed: $e");
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => TradingProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EDGE FX AI',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090B0C),
        cardColor: const Color(0xFF1D2428),
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          surface: Color(0xFF1D2428),
        ),
        useMaterial3: true,
      ),
      home: const DashboardLayout(),
    );
  }
}

class DashboardLayout extends StatefulWidget {
  const DashboardLayout({super.key});

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  final TextEditingController _apiKeyController = TextEditingController();
  final String _appId = '33LkncGXigSRqxUn4iEfO';

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TradingProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF101213),
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'EDGE FX AI',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
            ),
            const Spacer(),
            _buildStatusChip(provider),
            const SizedBox(width: 16),
            if (!provider.isAuthorized)
              ElevatedButton(
                onPressed: () => provider.loginToDeriv(_appId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Login with Deriv'),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.grey),
              onPressed: () => _showSettings(context, provider),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const TickerBar(),
          Expanded(
            child: Row(
              children: [
                _buildSidebar(provider),
                const VerticalDivider(width: 1, thickness: 1, color: Colors.white10),
                Expanded(
                  child: _buildMainView(provider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(TradingProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: provider.isAuthorized ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: provider.isAuthorized ? Colors.blue.withOpacity(0.3) : Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 4, backgroundColor: provider.isAuthorized ? Colors.blue : Colors.green),
          const SizedBox(width: 8),
          Text(
            provider.isAuthorized 
              ? '${provider.balance.toStringAsFixed(2)} USD' 
              : 'Server Connected',
            style: TextStyle(fontSize: 12, color: provider.isAuthorized ? Colors.blue : Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(TradingProvider provider) {
    return Container(
      width: 80,
      color: const Color(0xFF101213),
      child: Column(
        children: [
          _sidebarIcon(MarketView.dashboard, Icons.dashboard_rounded, provider),
          _sidebarIcon(MarketView.botBuilder, Icons.precision_manufacturing_outlined, provider),
          _sidebarIcon(MarketView.freeBots, Icons.download_for_offline_outlined, provider),
          _sidebarIcon(MarketView.bulkTrader, Icons.grid_view_rounded, provider),
          _sidebarIcon(MarketView.manualTrader, Icons.candlestick_chart_rounded, provider),
          _sidebarIcon(MarketView.copyTrading, Icons.people_outline_rounded, provider),
          _sidebarIcon(MarketView.charts, Icons.show_chart_rounded, provider),
          _sidebarIcon(MarketView.analysisTools, Icons.psychology_outlined, provider),
        ],
      ),
    );
  }

  Widget _sidebarIcon(MarketView view, IconData icon, TradingProvider provider) {
    final isSelected = provider.currentView == view;
    return InkWell(
      onTap: () => provider.setView(view),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          border: isSelected ? const Border(left: BorderSide(color: Colors.cyanAccent, width: 4)) : null,
          color: isSelected ? Colors.cyanAccent.withOpacity(0.05) : Colors.transparent,
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.cyanAccent : Colors.grey[600],
          size: 28,
        ),
      ),
    );
  }

  Widget _buildMainView(TradingProvider provider) {
    switch (provider.currentView) {
      case MarketView.dashboard:
        return _buildDashboard(provider);
      case MarketView.manualTrader:
        return _buildManualTrader(provider);
      case MarketView.analysisTools:
        return _buildAiAnalysis(provider);
      case MarketView.botBuilder:
        return _buildComingSoon('Bot Builder');
      case MarketView.freeBots:
        return _buildComingSoon('Free Bots Library');
      case MarketView.bulkTrader:
        return _buildComingSoon('Bulk Trader');
      case MarketView.copyTrading:
        return _buildComingSoon('Copy Trading');
      case MarketView.charts:
        return _buildLiveChartContainer(provider);
    }
  }

  Widget _buildComingSoon(String name) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.construction_rounded, size: 64, color: Colors.white10),
          const SizedBox(height: 16),
          Text('$name', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text('Module under development', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDashboard(TradingProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Market Overview', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildStatCard('Current Price', provider.currentPrice?.toStringAsFixed(2) ?? '---', Icons.account_balance_wallet_outlined, Colors.blue),
              const SizedBox(width: 16),
              _buildStatCard('24h Change', provider.change24h, Icons.trending_up, Colors.green),
              const SizedBox(width: 16),
              _buildStatCard('Active Bots', provider.activeBots.toString(), Icons.shopping_basket_outlined, Colors.orange),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildLiveChartContainer(provider)),
                const SizedBox(width: 24),
                Expanded(flex: 1, child: _buildActivityFeed(provider)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1D2428),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveChartContainer(TradingProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2428),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Volatility 100 Index', style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold)),
              if (provider.currentPrice != null)
                Text('\$${provider.currentPrice!.toStringAsFixed(2)}', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: provider.priceHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const FaIcon(FontAwesomeIcons.chartLine, size: 48, color: Colors.white10),
                        const SizedBox(height: 16),
                        const Text('No live data streaming', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => provider.startTrading('R_100'),
                          child: const Text('Connect Live Stream'),
                        ),
                      ],
                    ),
                  )
                : _buildChart(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(TradingProvider provider) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: provider.priceHistory.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
            isCurved: true,
            color: Colors.cyanAccent,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [Colors.cyanAccent.withOpacity(0.2), Colors.cyanAccent.withOpacity(0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityFeed(TradingProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2428),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live Activity', style: TextStyle(fontWeight: FontWeight.bold)),
          const Divider(height: 32, color: Colors.white10),
          Expanded(
            child: ListView.builder(
              itemCount: provider.activities.length,
              itemBuilder: (context, index) {
                final activity = provider.activities[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(activity.title, style: const TextStyle(fontSize: 13, color: Colors.white70))),
                      Text(
                        activity.status,
                        style: TextStyle(fontSize: 11, color: activity.color, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualTrader(TradingProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Expanded(flex: 3, child: _buildLiveChartContainer(provider)),
          const SizedBox(width: 24),
          Container(
            width: 300,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1D2428),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Trade Panel', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                const Text('Stake (USD)', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (v) => provider.updateStake(double.tryParse(v) ?? 10.0),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    hintText: '10.00',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => provider.placeTrade('Rise'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('RISE / CALL', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.placeTrade('Fall'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('FALL / PUT', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiAnalysis(TradingProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('AI Pattern Detector', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: provider.isAnalyzing ? null : provider.analyzeMarket,
                icon: provider.isAnalyzing 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome),
                label: const Text('Detect Patterns'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1D2428),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: Text(
                  provider.aiAdvice,
                  style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.white70),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context, TradingProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D2428),
        title: const Text('App Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Gemini API Key', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                hintText: 'Paste Gemini Key',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              provider.initAi(_apiKeyController.text);
              Navigator.pop(context);
            },
            child: const Text('Save Settings'),
          ),
        ],
      ),
    );
  }
}
