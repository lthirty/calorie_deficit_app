import 'package:flutter/material.dart';

void main() {
  runApp(const CalorieDeficitApp());
}

class CalorieDeficitApp extends StatelessWidget {
  const CalorieDeficitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calorie Deficit Calculator V2',
      theme: ThemeData(useMaterial3: true),
      home: const InputPage(),
    );
  }
}

enum Gender { male, female }

class InputPage extends StatefulWidget {
  const InputPage({super.key});

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  Gender _gender = Gender.male;

  final _ageCtrl = TextEditingController(text: '30');
  final _heightCtrl = TextEditingController(text: '175'); // cm
  final _weightCtrl = TextEditingController(text: '75');  // kg

  final _formKey = GlobalKey<FormState>();

  // Activity factor
  final List<_ActivityLevel> _levels = const [
    _ActivityLevel('Sedentary (little or no exercise)', 1.2),
    _ActivityLevel('Light (1–3 days/week)', 1.375),
    _ActivityLevel('Moderate (3–5 days/week)', 1.55),
    _ActivityLevel('Active (6–7 days/week)', 1.725),
  ];
  late _ActivityLevel _selectedLevel = _levels[0];

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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).size.width < 420 ? 16.0 : 20.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Calorie Deficit Calculator V2')),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(pad),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const Text(
                  'Enter your details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

                // Gender
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Gender', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      SegmentedButton<Gender>(
                        segments: const [
                          ButtonSegment(value: Gender.male, label: Text('Male')),
                          ButtonSegment(value: Gender.female, label: Text('Female')),
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
                        label: 'Age (years)',
                        controller: _ageCtrl,
                        hint: 'e.g. 30',
                        isInt: true,
                        min: 10,
                        max: 120,
                      ),
                      const SizedBox(height: 12),
                      _NumberField(
                        label: 'Height (cm)',
                        controller: _heightCtrl,
                        hint: 'e.g. 175',
                        min: 100,
                        max: 230,
                      ),
                      const SizedBox(height: 12),
                      _NumberField(
                        label: 'Weight (kg)',
                        controller: _weightCtrl,
                        hint: 'e.g. 75',
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
                      const Text('Activity level', style: TextStyle(fontWeight: FontWeight.w600)),
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
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text('Calculate'),
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Note: Results are estimates for general fitness planning only.',
                  style: TextStyle(fontSize: 12),
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

class ResultPage extends StatelessWidget {
  final Gender gender;
  final int age;
  final double heightCm;
  final double weightKg;
  final String activityLabel;

  final double bmr;
  final double tdee;
  final double suggestedCalories;
  final double estWeeklyLossKg;

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
  });

  @override
  Widget build(BuildContext context) {
    final genderText = gender == Gender.male ? 'Male' : 'Female';

    return Scaffold(
      appBar: AppBar(title: const Text('Your Results')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: ListView(
            children: [
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text('Gender: $genderText'),
                    Text('Age: $age years'),
                    Text('Height: ${heightCm.toStringAsFixed(0)} cm'),
                    Text('Weight: ${weightKg.toStringAsFixed(1)} kg'),
                    Text('Activity: $activityLabel'),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Calories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    _MetricRow('BMR (kcal/day)', bmr),
                    const SizedBox(height: 8),
                    _MetricRow('TDEE (kcal/day)', tdee),
                    const Divider(height: 24),
                    _MetricRow('Suggested intake (kcal/day)', suggestedCalories),
                    const SizedBox(height: 8),
                    Text(
                      'Estimated loss: ~${estWeeklyLossKg.toStringAsFixed(2)} kg/week (approx.)',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Placeholder for interstitial ad trigger later
              _AdPlaceholderInterstitial(),

              const SizedBox(height: 12),

              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text('Back'),
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
        if (s.isEmpty) return 'Required';
        final n = double.tryParse(s);
        if (n == null) return 'Enter a number';
        if (n < min || n > max) return 'Range: $min ~ $max';
        if (isInt && n % 1 != 0) return 'Must be an integer';
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

class _AdPlaceholderBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text('Banner Ad (placeholder)'),
    );
  }
}

class _AdPlaceholderInterstitial extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'Interstitial Ad will show here after calculation (placeholder).\nWe will integrate AdMob next.',
        style: TextStyle(fontSize: 12),
      ),
    );
  }
}