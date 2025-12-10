import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// ============= MODELS =============
class CurrencyData {
  final String code;
  final String name;
  final String flag;
  final String symbol;

  const CurrencyData({
    required this.code,
    required this.name,
    required this.flag,
    required this.symbol,
  });
}

// ============= PROVIDERS =============
final themeProvider = StateProvider<bool>((ref) => true);

final currenciesProvider = Provider<List<CurrencyData>>(
  (ref) => const [
    CurrencyData(code: 'USD', name: 'US Dollar', flag: '🇺🇸', symbol: '\$'),
    CurrencyData(code: 'EUR', name: 'Euro', flag: '🇪🇺', symbol: '€'),
    CurrencyData(code: 'GBP', name: 'British Pound', flag: '🇬🇧', symbol: '£'),
    CurrencyData(code: 'RUB', name: 'Russian Ruble', flag: '🇷🇺', symbol: '₽'),
    CurrencyData(
      code: 'UZS',
      name: "O'zbek So'mi",
      flag: '🇺🇿',
      symbol: 'soʻm',
    ),
    CurrencyData(code: 'KZT', name: 'Kazakh Tenge', flag: '🇰🇿', symbol: '₸'),
    CurrencyData(code: 'TRY', name: 'Turkish Lira', flag: '🇹🇷', symbol: '₺'),
    CurrencyData(code: 'CNY', name: 'Chinese Yuan', flag: '🇨🇳', symbol: '¥'),
    CurrencyData(code: 'JPY', name: 'Japanese Yen', flag: '🇯🇵', symbol: '¥'),
    CurrencyData(code: 'AED', name: 'UAE Dirham', flag: '🇦🇪', symbol: 'د.إ'),
  ],
);

final exchangeRatesProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final response = await http.get(
      Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['rates'] as Map<String, dynamic>;
    }
    return {};
  } catch (e) {
    return {};
  }
});

final converterDisplayProvider = StateProvider<String>((ref) => '0');
final fromCurrencyProvider = StateProvider<String>((ref) => 'USD');
final toCurrencyProvider = StateProvider<String>((ref) => 'UZS');

final conversionResultProvider = Provider<double>((ref) {
  final display = ref.watch(converterDisplayProvider);
  final fromCurrency = ref.watch(fromCurrencyProvider);
  final toCurrency = ref.watch(toCurrencyProvider);
  final ratesAsync = ref.watch(exchangeRatesProvider);

  return ratesAsync.when(
    data: (rates) {
      if (display == '0' || display.isEmpty || rates.isEmpty) return 0.0;

      final amount = double.tryParse(display) ?? 0;
      if (amount <= 0) return 0.0;

      final fromRate = rates[fromCurrency] ?? 1.0;
      final toRate = rates[toCurrency] ?? 1.0;
      return (amount / fromRate) * toRate;
    },
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

final calculatorDisplayProvider = StateProvider<String>((ref) => '0');
final calculatorOperationProvider = StateProvider<String>((ref) => '');
final calculatorFirstOperandProvider = StateProvider<double>((ref) => 0.0);
final calculatorShouldResetProvider = StateProvider<bool>((ref) => false);

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

// ============= MAIN =============
void main() {
  runApp(const ProviderScope(child: KanvettarimApp()));
}

class KanvettarimApp extends ConsumerWidget {
  const KanvettarimApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Kanvettarim.uz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: isDarkMode
            ? const Color(0xFF1C1C1E)
            : const Color(0xFFF5F7FA),
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
      ),
      home: const SplashScreen(),
    );
  }
}

// ============= SPLASH SCREEN =============
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const MainScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00D4FF), Color(0xFF0051FF)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0051FF).withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.currency_exchange,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Kanvettarim.uz',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Valyuta va Kalkulyator',
                      style: TextStyle(fontSize: 16, color: Colors.white60),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============= MAIN SCREEN =============
class MainScreen extends ConsumerWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    final currentIndex = ref.watch(bottomNavIndexProvider);

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF1C1C1E)
          : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          currentIndex == 0 ? 'Valyuta Konvertori' : 'Kalkulyator',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.invalidate(exchangeRatesProvider);
              },
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: currentIndex,
          children: const [ConverterScreen(), CalculatorScreen()],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) =>
                ref.read(bottomNavIndexProvider.notifier).state = index,
            backgroundColor: Colors.transparent,
            selectedItemColor: const Color(0xFF0051FF),
            unselectedItemColor: Colors.grey,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.currency_exchange),
                label: 'Konvertor',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calculate),
                label: 'Kalkulyator',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============= CONVERTER SCREEN =============
class ConverterScreen extends ConsumerWidget {
  const ConverterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    final display = ref.watch(converterDisplayProvider);
    final result = ref.watch(conversionResultProvider);
    final fromCurrency = ref.watch(fromCurrencyProvider);
    final toCurrency = ref.watch(toCurrencyProvider);
    final currencies = ref.watch(currenciesProvider);

    final fromData = currencies.firstWhere((c) => c.code == fromCurrency);
    final toData = currencies.firstWhere((c) => c.code == toCurrency);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;

        return Column(
          children: [
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(isTablet ? 40 : 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildCurrencyButton(
                        context,
                        ref,
                        fromData,
                        true,
                        isDarkMode,
                        isTablet,
                      ),
                      SizedBox(height: isTablet ? 20 : 10),
                      Text(
                        display,
                        style: TextStyle(
                          fontSize: isTablet ? 64 : 48,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      SizedBox(height: isTablet ? 30 : 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCurrencyButton(
                            context,
                            ref,
                            toData,
                            false,
                            isDarkMode,
                            isTablet,
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.swap_vert,
                              color: const Color(0xFF0051FF),
                              size: isTablet ? 36 : 24,
                            ),
                            onPressed: () {
                              final temp = ref.read(fromCurrencyProvider);
                              ref.read(fromCurrencyProvider.notifier).state =
                                  ref.read(toCurrencyProvider);
                              ref.read(toCurrencyProvider.notifier).state =
                                  temp;
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: isTablet ? 20 : 10),
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 300),
                        tween: Tween(begin: 0.0, end: result),
                        builder: (context, value, child) {
                          return Text(
                            value.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: isTablet ? 48 : 36,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF00D4FF),
                            ),
                            textAlign: TextAlign.right,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                padding: EdgeInsets.all(isTablet ? 20 : 10),
                child: Column(
                  children: [
                    _buildButtonRow(ref, ['7', '8', '9'], isDarkMode, isTablet),
                    _buildButtonRow(ref, ['4', '5', '6'], isDarkMode, isTablet),
                    _buildButtonRow(ref, ['1', '2', '3'], isDarkMode, isTablet),
                    _buildButtonRow(ref, ['C', '0', '.'], isDarkMode, isTablet),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCurrencyButton(
    BuildContext context,
    WidgetRef ref,
    CurrencyData currency,
    bool isFrom,
    bool isDarkMode,
    bool isTablet,
  ) {
    return GestureDetector(
      onTap: () => _showCurrencyPicker(context, ref, isFrom, isDarkMode),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 15,
          vertical: isTablet ? 15 : 10,
        ),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF0051FF).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(currency.flag, style: TextStyle(fontSize: isTablet ? 32 : 24)),
            SizedBox(width: isTablet ? 12 : 8),
            Text(
              currency.code,
              style: TextStyle(
                fontSize: isTablet ? 22 : 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: const Color(0xFF0051FF),
              size: isTablet ? 28 : 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonRow(
    WidgetRef ref,
    List<String> buttons,
    bool isDarkMode,
    bool isTablet,
  ) {
    return Expanded(
      child: Row(
        children: buttons
            .map((button) => _buildButton(ref, button, isDarkMode, isTablet))
            .toList(),
      ),
    );
  }

  Widget _buildButton(
    WidgetRef ref,
    String text,
    bool isDarkMode,
    bool isTablet,
  ) {
    final isOperator = text == 'C';

    return Expanded(
      child: Container(
        margin: EdgeInsets.all(isTablet ? 8 : 5),
        child: Material(
          color: isOperator
              ? const Color(0xFFFF3B30)
              : (isDarkMode ? const Color(0xFF2C2C2E) : Colors.white),
          borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
          elevation: isOperator ? 2 : 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
            onTap: () => _onConverterButtonPressed(ref, text),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: isTablet ? 36 : 28,
                  fontWeight: FontWeight.w600,
                  color: isOperator
                      ? Colors.white
                      : (isDarkMode ? Colors.white : Colors.black),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onConverterButtonPressed(WidgetRef ref, String text) {
    final display = ref.read(converterDisplayProvider);

    if (text == 'C') {
      ref.read(converterDisplayProvider.notifier).state = '0';
    } else if (text == '.') {
      if (!display.contains('.')) {
        ref.read(converterDisplayProvider.notifier).state = display + '.';
      }
    } else {
      if (display == '0') {
        ref.read(converterDisplayProvider.notifier).state = text;
      } else {
        ref.read(converterDisplayProvider.notifier).state = display + text;
      }
    }
  }

  void _showCurrencyPicker(
    BuildContext context,
    WidgetRef ref,
    bool isFrom,
    bool isDarkMode,
  ) {
    final currencies = ref.read(currenciesProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Valyutani tanlang',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: currencies.length,
                itemBuilder: (context, index) {
                  final currency = currencies[index];
                  return ListTile(
                    leading: Text(
                      currency.flag,
                      style: const TextStyle(fontSize: 32),
                    ),
                    title: Text(
                      currency.code,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      currency.name,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: Text(
                      currency.symbol,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF0051FF),
                      ),
                    ),
                    onTap: () {
                      if (isFrom) {
                        ref.read(fromCurrencyProvider.notifier).state =
                            currency.code;
                      } else {
                        ref.read(toCurrencyProvider.notifier).state =
                            currency.code;
                      }
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============= CALCULATOR SCREEN =============
class CalculatorScreen extends ConsumerWidget {
  const CalculatorScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    final display = ref.watch(calculatorDisplayProvider);
    final operation = ref.watch(calculatorOperationProvider);
    final firstOperand = ref.watch(calculatorFirstOperandProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;

        return Column(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                padding: EdgeInsets.all(isTablet ? 40 : 20),
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (operation.isNotEmpty)
                      Text(
                        '$firstOperand $operation',
                        style: TextStyle(
                          fontSize: isTablet ? 32 : 24,
                          color: isDarkMode ? Colors.grey : Colors.grey[600],
                        ),
                      ),
                    SizedBox(height: isTablet ? 15 : 10),
                    Text(
                      display,
                      style: TextStyle(
                        fontSize: isTablet ? 72 : 56,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                padding: EdgeInsets.all(isTablet ? 20 : 10),
                child: Column(
                  children: [
                    _buildButtonRow(ref, ['C', '⌫', '÷'], isDarkMode, isTablet),
                    _buildButtonRow(
                      ref,
                      ['7', '8', '9', '×'],
                      isDarkMode,
                      isTablet,
                    ),
                    _buildButtonRow(
                      ref,
                      ['4', '5', '6', '-'],
                      isDarkMode,
                      isTablet,
                    ),
                    _buildButtonRow(
                      ref,
                      ['1', '2', '3', '+'],
                      isDarkMode,
                      isTablet,
                    ),
                    _buildButtonRow(ref, ['0', '.', '='], isDarkMode, isTablet),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildButtonRow(
    WidgetRef ref,
    List<String> buttons,
    bool isDarkMode,
    bool isTablet,
  ) {
    return Expanded(
      child: Row(
        children: buttons
            .map((button) => _buildButton(ref, button, isDarkMode, isTablet))
            .toList(),
      ),
    );
  }

  Widget _buildButton(
    WidgetRef ref,
    String text,
    bool isDarkMode,
    bool isTablet,
  ) {
    final isOperator = ['+', '-', '×', '÷'].contains(text);
    final isSpecial = ['C', '⌫', '='].contains(text);

    Color buttonColor;
    if (text == 'C') {
      buttonColor = const Color(0xFFFF3B30);
    } else if (text == '=') {
      buttonColor = const Color(0xFF00D4FF);
    } else if (isOperator || text == '⌫') {
      buttonColor = const Color(0xFF0051FF);
    } else {
      buttonColor = isDarkMode ? const Color(0xFF2C2C2E) : Colors.white;
    }

    return Expanded(
      flex: text == '0' ? 2 : 1,
      child: Container(
        margin: EdgeInsets.all(isTablet ? 8 : 5),
        child: Material(
          color: buttonColor,
          borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
          elevation: (isOperator || isSpecial) ? 2 : 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
            onTap: () => _onCalculatorButtonPressed(ref, text),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: isTablet ? 36 : 28,
                  fontWeight: FontWeight.w600,
                  color: (isOperator || isSpecial)
                      ? Colors.white
                      : (isDarkMode ? Colors.white : Colors.black),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onCalculatorButtonPressed(WidgetRef ref, String text) {
    final display = ref.read(calculatorDisplayProvider);
    final shouldReset = ref.read(calculatorShouldResetProvider);

    if (text == 'C') {
      ref.read(calculatorDisplayProvider.notifier).state = '0';
      ref.read(calculatorOperationProvider.notifier).state = '';
      ref.read(calculatorFirstOperandProvider.notifier).state = 0.0;
      ref.read(calculatorShouldResetProvider.notifier).state = false;
    } else if (text == '⌫') {
      if (display.length > 1) {
        ref.read(calculatorDisplayProvider.notifier).state = display.substring(
          0,
          display.length - 1,
        );
      } else {
        ref.read(calculatorDisplayProvider.notifier).state = '0';
      }
    } else if (text == '=') {
      _calculateResult(ref);
    } else if (['+', '-', '×', '÷'].contains(text)) {
      ref.read(calculatorFirstOperandProvider.notifier).state =
          double.tryParse(display) ?? 0;
      ref.read(calculatorOperationProvider.notifier).state = text;
      ref.read(calculatorShouldResetProvider.notifier).state = true;
    } else if (text == '.') {
      if (!display.contains('.')) {
        ref.read(calculatorDisplayProvider.notifier).state = display + '.';
      }
    } else {
      if (display == '0' || shouldReset) {
        ref.read(calculatorDisplayProvider.notifier).state = text;
        ref.read(calculatorShouldResetProvider.notifier).state = false;
      } else {
        ref.read(calculatorDisplayProvider.notifier).state = display + text;
      }
    }
  }

  void _calculateResult(WidgetRef ref) {
    final display = ref.read(calculatorDisplayProvider);
    final operation = ref.read(calculatorOperationProvider);
    final firstOperand = ref.read(calculatorFirstOperandProvider);

    final secondOperand = double.tryParse(display) ?? 0;
    double result = 0;

    switch (operation) {
      case '+':
        result = firstOperand + secondOperand;
        break;
      case '-':
        result = firstOperand - secondOperand;
        break;
      case '×':
        result = firstOperand * secondOperand;
        break;
      case '÷':
        if (secondOperand != 0) {
          result = firstOperand / secondOperand;
        } else {
          ref.read(calculatorDisplayProvider.notifier).state = 'Xato';
          return;
        }
        break;
    }

    String resultString = result.toString();
    if (resultString.endsWith('.0')) {
      resultString = resultString.substring(0, resultString.length - 2);
    }

    ref.read(calculatorDisplayProvider.notifier).state = resultString;
    ref.read(calculatorOperationProvider.notifier).state = '';
    ref.read(calculatorShouldResetProvider.notifier).state = true;
  }
}

// ============= SETTINGS SCREEN =============
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF1C1C1E)
          : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Sozlamalar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    'Qorong\'u rejim',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  subtitle: const Text('Tungi rejimni yoqish/o\'chirish'),
                  value: isDarkMode,
                  activeColor: const Color(0xFF0051FF),
                  onChanged: (value) {
                    ref.read(themeProvider.notifier).state = value;
                  },
                  secondary: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0051FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: const Color(0xFF0051FF),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: Color(0xFF00D4FF),
                    ),
                  ),
                  title: Text(
                    'Versiya',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  subtitle: const Text('2.0.0'),
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0051FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.code, color: Color(0xFF0051FF)),
                  ),
                  title: Text(
                    'Dasturchi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  subtitle: const Text('BATO Uz Team'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                const url = 'https://kurs.uz';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  );
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF54E2D), Color(0xFFFF6B4A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF54E2D).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Image.asset(
                        'assets/images/kurs_logo.svg',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kurs.uz',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Valyuta kurslari',
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
