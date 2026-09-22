import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/match_model.dart';
import '../models/competition_model.dart';

// شاشة إضافة/تعديل مباراة - نفس الشاشة تُستخدم للحالتين
// إذا تم تمرير existingMatch تعمل الشاشة في وضع "تعديل"، وإلا تعمل في وضع "إضافة"
class AddEditMatchScreen extends StatefulWidget {
  final MatchModel? existingMatch;

  const AddEditMatchScreen({super.key, this.existingMatch});

  @override
  State<AddEditMatchScreen> createState() => _AddEditMatchScreenState();
}

class _AddEditMatchScreenState extends State<AddEditMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbHelper = DBHelper();

  late TextEditingController _homeTeamController;
  late TextEditingController _awayTeamController;
  late TextEditingController _homeLogoController;
  late TextEditingController _awayLogoController;
  late TextEditingController _homeScoreController;
  late TextEditingController _awayScoreController;
  late TextEditingController _stadiumController;
  late TextEditingController _refereeController;

  List<CompetitionModel> _competitions = [];
  int? _selectedCompetitionId;
  String _selectedStatus = 'upcoming';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  bool _isLoading = false;
  bool get _isEditMode => widget.existingMatch != null;

  @override
  void initState() {
    super.initState();
    final match = widget.existingMatch;

    _homeTeamController = TextEditingController(text: match?.homeTeam ?? '');
    _awayTeamController = TextEditingController(text: match?.awayTeam ?? '');
    _homeLogoController = TextEditingController(
        text: match?.homeLogoUrl ?? 'https://cdn-icons-png.flaticon.com/512/861/861512.png');
    _awayLogoController = TextEditingController(
        text: match?.awayLogoUrl ?? 'https://cdn-icons-png.flaticon.com/512/861/861512.png');
    _homeScoreController = TextEditingController(text: (match?.homeScore ?? 0).toString());
    _awayScoreController = TextEditingController(text: (match?.awayScore ?? 0).toString());
    _stadiumController = TextEditingController(text: match?.stadium ?? '');
    _refereeController = TextEditingController(text: match?.referee ?? '');

    _selectedStatus = match?.status ?? 'upcoming';
    _selectedCompetitionId = match?.competitionId;

    if (match != null) {
      final dateParts = match.matchDate.split('-');
      final timeParts = match.matchTime.split(':');
      _selectedDate = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
      );
      _selectedTime = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
    }

    _loadCompetitions();
  }

  Future<void> _loadCompetitions() async {
    final data = await _dbHelper.getCompetitions();
    setState(() {
      _competitions = data;
      _selectedCompetitionId ??= data.isNotEmpty ? data.first.id : null;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) setState(() => _selectedTime = picked);
  }

  String get _formattedDate =>
      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

  String get _formattedTime =>
      '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

  Future<void> _saveMatch() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCompetitionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار البطولة')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final match = MatchModel(
      id: widget.existingMatch?.id,
      competitionId: _selectedCompetitionId!,
      homeTeam: _homeTeamController.text.trim(),
      awayTeam: _awayTeamController.text.trim(),
      homeLogoUrl: _homeLogoController.text.trim(),
      awayLogoUrl: _awayLogoController.text.trim(),
      homeScore: int.parse(_homeScoreController.text),
      awayScore: int.parse(_awayScoreController.text),
      matchDate: _formattedDate,
      matchTime: _formattedTime,
      stadium: _stadiumController.text.trim(),
      referee: _refereeController.text.trim(),
      status: _selectedStatus,
    );

    if (_isEditMode) {
      await _dbHelper.updateMatch(match);
    } else {
      await _dbHelper.addMatch(match);
    }

    setState(() => _isLoading = false);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEditMode ? 'تم تعديل المباراة بنجاح' : 'تمت إضافة المباراة بنجاح')),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'تعديل المباراة' : 'إضافة مباراة جديدة')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  value: _selectedCompetitionId,
                  decoration: const InputDecoration(labelText: 'البطولة'),
                  items: _competitions
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedCompetitionId = value),
                  validator: (value) => value == null ? 'الرجاء اختيار البطولة' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _homeTeamController,
                        decoration: const InputDecoration(labelText: 'الفريق المضيف'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _awayTeamController,
                        decoration: const InputDecoration(labelText: 'الفريق الضيف'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _homeLogoController,
                        decoration: const InputDecoration(labelText: 'رابط شعار المضيف'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _awayLogoController,
                        decoration: const InputDecoration(labelText: 'رابط شعار الضيف'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _homeScoreController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'نتيجة المضيف'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'مطلوب';
                          if (int.tryParse(v) == null || int.parse(v) < 0) return 'رقم غير صحيح';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _awayScoreController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'نتيجة الضيف'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'مطلوب';
                          if (int.tryParse(v) == null || int.parse(v) < 0) return 'رقم غير صحيح';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(_formattedDate),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.access_time, size: 18),
                        label: Text(_formattedTime),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _stadiumController,
                  decoration: const InputDecoration(labelText: 'الملعب'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _refereeController,
                  decoration: const InputDecoration(labelText: 'الحكم'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(labelText: 'حالة المباراة'),
                  items: const [
                    DropdownMenuItem(value: 'upcoming', child: Text('لم تبدأ بعد')),
                    DropdownMenuItem(value: 'live', child: Text('مباشر الآن')),
                    DropdownMenuItem(value: 'finished', child: Text('انتهت')),
                  ],
                  onChanged: (value) => setState(() => _selectedStatus = value!),
                ),
                const SizedBox(height: 26),
                FilledButton(
                  onPressed: _isLoading ? null : _saveMatch,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_isEditMode ? 'حفظ التعديلات' : 'إضافة المباراة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
