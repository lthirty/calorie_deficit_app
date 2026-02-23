// 版本说明：
// 2025-01-21 - CodeGeeX - 添加 flutter_localizations 支持，删除自定义的 _SimpleMaterialLocalizations 类
// 2025-01-21 - CodeGeeX - 修复 MaterialLocalizations 相关错误
// 2025-01-21 - CodeGeeX - 去掉插页式广告广告。
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class _LocaleData extends InheritedWidget {
  final AppLocalizations localizations;

  const _LocaleData({
    required this.localizations,
    required Widget child,
    Key? key,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(_LocaleData old) => localizations != old.localizations;
}

// AdMob 测试广告单元ID
const String _adAppId = 'ca-app-pub-3940256099942544~3347511713';
const String _bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 MobileAds
  await MobileAds.instance.initialize();
  
  // 配置请求配置
  final requestConfiguration = RequestConfiguration(
    testDeviceIds: <String>[],
  );
  MobileAds.instance.updateRequestConfiguration(requestConfiguration);
  
  runApp(const CalorieDeficitApp());
}

class CalorieDeficitApp extends StatefulWidget {
  const CalorieDeficitApp({super.key});

  @override
  State<CalorieDeficitApp> createState() => _CalorieDeficitAppState();
}

class _CalorieDeficitAppState extends State<CalorieDeficitApp> {
  Locale _locale = const Locale('en');

  void _changeLanguage(Locale locale) {
    setState(() {
      _locale = locale;
      AppLocalizations.setCurrent(AppLocalizations(locale));
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations(_locale);
    AppLocalizations.setCurrent(localizations);
    
    return _LocaleData(
      localizations: localizations,
      child: MaterialApp(
        title: 'Calorie Deficit Calculator V2.02231046',
        theme: ThemeData(useMaterial3: true),
        locale: _locale,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('zh'),
        ],
        home: InputPage(onLanguageChanged: _changeLanguage),
      ),
    );
  }
}

enum Gender { male, female }

class InputPage extends StatefulWidget {
  final Function(Locale) onLanguageChanged;
  
  const InputPage({super.key, required this.onLanguageChanged});

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  Gender _gender = Gender.male;
  Locale _currentLocale = const Locale('en');

  final _ageCtrl = TextEditingController(text: '30');
  final _heightCtrl = TextEditingController(text: '175'); // cm
  final _weightCtrl = TextEditingController(text: '75');  // kg

  final _formKey = GlobalKey<FormState>();

  // Activity factor
  late List<_ActivityLevel> _levels;
  late _ActivityLevel _selectedLevel;

  @override
  void initState() {
    super.initState();
    _updateActivityLevels();
  }

  void _updateActivityLevels() {
    final localizations = AppLocalizations.of(context);
    _levels = [
      _ActivityLevel(localizations.sedentary, 1.2),
      _ActivityLevel(localizations.light, 1.375),
      _ActivityLevel(localizations.moderate, 1.55),
      _ActivityLevel(localizations.active, 1.725),
    ];
    _selectedLevel = _levels[0];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateActivityLevels();
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    final age = int.parse(_ageCtrl.text.trim());
    final heightCm = double.parse(_heightCtrl.text.trim());
    final weightKg = double.parse(_weightCtrl.text.trim());

    final bmr = _calcBmr(
      gender: _gender,
      age: age,
      heightCm: heightCm,
      weightKg: weightKg,
    );

    final tdee = bmr * _selectedLevel.factor;

    // Suggested deficit: -500 kcal/day (safe general guidance)
    final suggested = (tdee - 500).clamp(1200.0, 99999.0).toDouble();

    // Estimated weekly loss: 500*7 / 7700 ≈ 0.45 kg/week
    const weeklyLossKg = 500 * 7 / 7700;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultPage(
          gender: _gender,
          age: age,
          heightCm: heightCm,
          weightKg: weightKg,
          activityLabel: _selectedLevel.label,
          bmr: bmr,
          tdee: tdee,
          suggestedCalories: suggested,
          estWeeklyLossKg: weeklyLossKg,
          onLanguageChanged: widget.onLanguageChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).size.width < 420 ? 16.0 : 20.0;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.appTitle),
        actions: [
          IconButton(
            icon: Text(_currentLocale.languageCode == 'zh' ? 'EN' : '中'),
            onPressed: () {
              final newLocale = _currentLocale.languageCode == 'zh' 
                  ? const Locale('en') 
                  : const Locale('zh');
              setState(() {
                _currentLocale = newLocale;
              });
              widget.onLanguageChanged(newLocale);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(pad),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Text(
                  localizations.enterDetails,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

                // Gender
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(localizations.gender, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      SegmentedButton<Gender>(
                        segments: [
                          ButtonSegment(value: Gender.male, label: Text(localizations.male)),
                          ButtonSegment(value: Gender.female, label: Text(localizations.female)),
                        ],
                        selected: {_gender},
                        onSelectionChanged: (s) => setState(() => _gender = s.first),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Age / Height / Weight
                _Card(
                  child: Column(
                    children: [
                      _NumberField(
                        label: localizations.age,
                        controller: _ageCtrl,
                        hint: localizations.ageHint,
                        isInt: true,
                        min: 10,
                        max: 120,
                      ),
                      const SizedBox(height: 12),
                      _NumberField(
                        label: localizations.height,
                        controller: _heightCtrl,
                        hint: localizations.heightHint,
                        min: 100,
                        max: 230,
                      ),
                      const SizedBox(height: 12),
                      _NumberField(
                        label: localizations.weight,
                        controller: _weightCtrl,
                        hint: localizations.weightHint,
                        min: 30,
                        max: 300,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Activity
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(localizations.activityLevel, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<_ActivityLevel>(
                        value: _selectedLevel,
                        items: _levels
                            .map((e) => DropdownMenuItem<_ActivityLevel>(
                                  value: e,
                                  child: Text(e.label),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedLevel = v!),
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                FilledButton.icon(
                  onPressed: _calculate,
                  icon: const Icon(Icons.calculate),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(localizations.calculate),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  localizations.note,
                  style: const TextStyle(fontSize: 12),
                ),

                const SizedBox(height: 12),

                // Placeholder for banner ad later
                _AdPlaceholderBanner(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ResultPage extends StatefulWidget {
  final Gender gender;
  final int age;
  final double heightCm;
  final double weightKg;
  final String activityLabel;

  final double bmr;
  final double tdee;
  final double suggestedCalories;
  final double estWeeklyLossKg;
  final Function(Locale) onLanguageChanged;

  const ResultPage({
    super.key,
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.activityLabel,
    required this.bmr,
    required this.tdee,
    required this.suggestedCalories,
    required this.estWeeklyLossKg,
    required this.onLanguageChanged,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  Locale _currentLocale = const Locale('en');

  void _changeLanguage(Locale locale) {
    setState(() {
      _currentLocale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final genderText = widget.gender == Gender.male ? localizations.male : localizations.female;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.yourResults),
        actions: [
          IconButton(
            icon: Text(_currentLocale.languageCode == 'zh' ? 'EN' : '中'),
            onPressed: () {
              final newLocale = _currentLocale.languageCode == 'zh' 
                  ? const Locale('en') 
                  : const Locale('zh');
              _changeLanguage(newLocale);
              // 通知父级应用语言已更改
              widget.onLanguageChanged(newLocale);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: ListView(
            children: [
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(localizations.summary, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text('${localizations.gender}: $genderText'),
                    Text('${localizations.age}: ${widget.age} ${_currentLocale.languageCode == 'zh' ? '岁' : 'years'}'),
                    Text('${localizations.height}: ${widget.heightCm.toStringAsFixed(0)} ${_currentLocale.languageCode == 'zh' ? '厘米' : 'cm'}'),
                    Text('${localizations.weight}: ${widget.weightKg.toStringAsFixed(1)} ${_currentLocale.languageCode == 'zh' ? '公斤' : 'kg'}'),
                    Text('${localizations.activityLevel}: ${widget.activityLabel}'),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(localizations.calories, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    _MetricRow(localizations.bmr, widget.bmr),
                    const SizedBox(height: 8),
                    _MetricRow(localizations.tdee, widget.tdee),
                    const Divider(height: 24),
                    _MetricRow(localizations.suggestedIntake, widget.suggestedCalories),
                    const SizedBox(height: 8),
                    Text(
                      localizations.estimatedLoss(widget.estWeeklyLossKg),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(localizations.back),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

double _calcBmr({
  required Gender gender,
  required int age,
  required double heightCm,
  required double weightKg,
}) {
  // Mifflin-St Jeor equation
  final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
  return gender == Gender.male ? base + 5 : base - 161;
}

class _ActivityLevel {
  final String label;
  final double factor;
  const _ActivityLevel(this.label, this.factor);
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: child,
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool isInt;
  final double min;
  final double max;

  const _NumberField({
    required this.label,
    required this.controller,
    required this.hint,
    this.isInt = false,
    required this.min,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      validator: (v) {
        final s = (v ?? '').trim();
        if (s.isEmpty) return localizations.required;
        final n = double.tryParse(s);
        if (n == null) return localizations.enterNumber;
        if (n < min || n > max) return localizations.range(min, max);
        if (isInt && n % 1 != 0) return localizations.mustBeInteger;
        return null;
      },
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final double value;
  const _MetricRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(value.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _AdPlaceholderBanner extends StatefulWidget {
  @override
  State<_AdPlaceholderBanner> createState() => _AdPlaceholderBannerState();
}

class _AdPlaceholderBannerState extends State<_AdPlaceholderBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  // 使用实际的横幅广告单元ID
  final String _adUnitId = _bannerAdUnitId;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (_isLoaded && _bannerAd != null) {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    } else {
      return Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(localizations.loadingAd),
      );
    }
  }
}
          








    
