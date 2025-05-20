import 'package:flutter/material.dart';
import 'package:shift_app/services/settings_database_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<String> _roles = [];
  List<String> _stations = [];
  List<String> _positions = [];

  final _roleTextController = TextEditingController();
  final _stationTextController = TextEditingController();
  final _positionTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadData() async {
    _roles = await SettingsDatabaseService.getAllRoles();
    _stations = await SettingsDatabaseService.getAllStations();
    _positions = await SettingsDatabaseService.getAllPositions();
    setState(() {});
  }

  Future<void> _addRole(String role) async {
    final text = role.trim();
    if (text.isEmpty || _roles.contains(text)) {
      _showSnackbar("❌ שגיאה: לא ניתן להוסיף את המשימה", isError: true);
      return;
    }

    try {
      await SettingsDatabaseService.insertRole(text);
      _roleTextController.clear();
      await _loadData();
      _showSnackbar("✅ המשימה נשמרה בהצלחה");
    } catch (e) {
      _showSnackbar("❌ שגיאה בשמירה: $e", isError: true);
    }
  }

  Future<void> _addStation(String station) async {
    final text = station.trim();
    if (text.isEmpty || _stations.contains(text)) {
      _showSnackbar("❌ שגיאה: לא ניתן להוסיף את התחנה", isError: true);
      return;
    }

    try {
      await SettingsDatabaseService.insertStation(text);
      _stationTextController.clear();
      await _loadData();
      _showSnackbar("✅ התחנה נשמרה בהצלחה");
    } catch (e) {
      _showSnackbar("❌ שגיאה בשמירה: $e", isError: true);
    }
  }

  Future<void> _addPosition(String pos) async {
    final text = pos.trim();
    if (text.isEmpty || _positions.contains(text)) {
      _showSnackbar("❌ שגיאה: לא ניתן להוסיף את התפקיד", isError: true);
      return;
    }

    try {
      await SettingsDatabaseService.insertPosition(text);
      _positionTextController.clear();
      await _loadData();
      _showSnackbar("✅ התפקיד נשמר בהצלחה");
    } catch (e) {
      _showSnackbar("❌ שגיאה בשמירה: $e", isError: true);
    }
  }

  Future<void> _deleteRole(String role) async {
    await SettingsDatabaseService.deleteRole(role);
    setState(() {
      _roles.remove(role);
    });
  }

  Future<void> _deleteStation(String station) async {
    await SettingsDatabaseService.deleteStation(station);
    setState(() {
      _stations.remove(station);
    });
  }

  Future<void> _deletePosition(String pos) async {
    await SettingsDatabaseService.deletePosition(pos);
    setState(() {
      _positions.remove(pos);
    });
  }

  void _openRoleSettingsPopup(String role) async {
    final existing = await SettingsDatabaseService.getRoleMetadata(role);
    final selectedPositions = Set<String>.from(
      await SettingsDatabaseService.getPositionsForRole(role),
    );

    final _startTimeController = TextEditingController(
      text: existing?['start_time'] ?? '',
    );
    final _endTimeController = TextEditingController(
      text: existing?['end_time'] ?? '',
    );
    String _mode = existing?['mode'] ?? 'תחנה';

    bool hasFixedHours =
        _startTimeController.text.isNotEmpty ||
        _endTimeController.text.isNotEmpty;
    bool hasPositions = selectedPositions.isNotEmpty;
    String mode = _mode;

    // ✅ עכשיו מותר להמשיך עם showDialog
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("הגדרות עבור '$role'"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text("יש שעות קבועות למשימה"),
                      value: hasFixedHours,
                      onChanged: (val) {
                        setStateDialog(() {
                          hasFixedHours = val;
                          if (!val) {
                            _startTimeController.clear();
                            _endTimeController.clear();
                          }
                        });
                      },
                    ),
                    if (hasFixedHours)
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final TimeOfDay? picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (picked != null) {
                                  setStateDialog(() {
                                    _startTimeController.text = picked.format(
                                      context,
                                    );
                                  });
                                }
                              },
                              child: AbsorbPointer(
                                child: TextField(
                                  controller: _startTimeController,
                                  decoration: const InputDecoration(
                                    labelText: "שעת התחלה",
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final TimeOfDay? picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (picked != null) {
                                  setStateDialog(() {
                                    _endTimeController.text = picked.format(
                                      context,
                                    );
                                  });
                                }
                              },
                              child: AbsorbPointer(
                                child: TextField(
                                  controller: _endTimeController,
                                  decoration: const InputDecoration(
                                    labelText: "שעת סיום",
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text("יש תפקידים קבועים למשימה"),
                      value: hasPositions,
                      onChanged: (val) {
                        setStateDialog(() => hasPositions = val);
                      },
                    ),
                    if (hasPositions)
                      Wrap(
                        spacing: 8,
                        children:
                            _positions.map((pos) {
                              final isSelected = selectedPositions.contains(
                                pos,
                              );
                              return FilterChip(
                                label: Text(pos),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setStateDialog(() {
                                    if (selected) {
                                      selectedPositions.add(pos);
                                    } else {
                                      selectedPositions.remove(pos);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text("שיוך: "),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: mode,
                          items: const [
                            DropdownMenuItem(
                              value: 'תחנה',
                              child: Text("תחנה"),
                            ),
                            DropdownMenuItem(
                              value: 'פירוט',
                              child: Text("פירוט"),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setStateDialog(() => mode = val);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await SettingsDatabaseService.saveRoleMetadata(
                      roleName: role,
                      startTime: _startTimeController.text.trim(),
                      endTime: _endTimeController.text.trim(),
                      mode: mode,
                    );

                    await SettingsDatabaseService.saveRolePositions(
                      roleName: role,
                      positions: hasPositions ? selectedPositions.toList() : [],
                    );

                    Navigator.pop(context);
                    _showSnackbar("✅ נשמרו הגדרות ל־'$role'");
                  },
                  child: const Text("שמור"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("בטל"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openPositionSettingsPopup(String position) async {
    final existingCode = await SettingsDatabaseService.getPositionCode(
      position,
    );
    final _codeController = TextEditingController(
      text: existingCode?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("הגדרות עבור '$position'"),
          content: TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "קוד תפקיד"),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final code = int.tryParse(_codeController.text.trim());
                if (code != null) {
                  await SettingsDatabaseService.savePositionMetadata(
                    positionName: position,
                    code: code,
                  );
                  Navigator.pop(context);
                  _showSnackbar("✅ נשמר קוד לתפקיד '$position'");
                } else {
                  _showSnackbar("❌ קוד לא תקין", isError: true);
                }
              },
              child: const Text("שמור"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("בטל"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("הגדרות מערכת")),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ListView(
            children: [
              const Divider(),
              const Text(
                "🎯 סוג משמרת",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Autocomplete<String>(
                optionsBuilder: (value) {
                  final query = value.text.toLowerCase();
                  return _roles.where((r) => r.toLowerCase().contains(query));
                },
                fieldViewBuilder: (
                  context,
                  controller,
                  focusNode,
                  onEditingComplete,
                ) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: "הוסף סוג משמרת חדש",
                    ),
                    onEditingComplete: () {
                      _addRole(controller.text);
                      controller.clear(); // ✅ מנקה את השדה לאחר ההוספה
                      onEditingComplete();
                    },
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  final optList = options.toList();
                  final content = ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: optList.length,
                    itemBuilder: (context, index) {
                      final role = optList[index];
                      return ListTile(
                        title: Text(role),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.settings),
                              onPressed: () => _openRoleSettingsPopup(role),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deleteRole(role),
                            ),
                          ],
                        ),
                        onTap: () => onSelected(role),
                      );
                    },
                  );

                  return Material(
                    elevation: 4,
                    child:
                        optList.length <= 5
                            ? content
                            : ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 200),
                              child: content,
                            ),
                  );
                },
                onSelected: (val) => _roleTextController.text = val,
              ),

              const Divider(),
              const Text(
                "🧍 תפקיד",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Autocomplete<String>(
                optionsBuilder: (value) {
                  final query = value.text.toLowerCase();
                  return _positions.where(
                    (p) => p.toLowerCase().contains(query),
                  );
                },
                fieldViewBuilder: (
                  context,
                  controller,
                  focusNode,
                  onEditingComplete,
                ) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: "הוסף תפקיד חדש",
                    ),
                    onEditingComplete: () {
                      _addPosition(controller.text);
                      controller.clear(); // ✅ מנקה את השדה לאחר ההוספה
                      onEditingComplete();
                    },
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  final optList = options.toList();
                  final content = ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: optList.length,
                    itemBuilder: (context, index) {
                      final pos = optList[index];
                      return ListTile(
                        title: Text(pos),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.settings),
                              onPressed:
                                  () => _openPositionSettingsPopup(
                                    pos,
                                  ), // ✅ גלגל שיניים
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deletePosition(pos),
                            ),
                          ],
                        ),
                        onTap: () => onSelected(pos),
                      );
                    },
                  );

                  return Material(
                    elevation: 4,
                    child:
                        optList.length <= 5
                            ? content
                            : ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 200),
                              child: content,
                            ),
                  );
                },
                onSelected: (val) => _positionTextController.text = val,
              ),
              const Divider(),
              const Text(
                "🏥 תחנה",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Autocomplete<String>(
                optionsBuilder: (value) {
                  final query = value.text.toLowerCase();
                  return _stations.where(
                    (s) => s.toLowerCase().contains(query),
                  );
                },
                fieldViewBuilder: (
                  context,
                  controller,
                  focusNode,
                  onEditingComplete,
                ) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: "הוסף תחנה חדשה",
                    ),
                    onEditingComplete: () {
                      _addStation(controller.text);
                      controller.clear(); // ✅ מנקה את השדה לאחר ההוספה
                      onEditingComplete();
                    },
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  final optList = options.toList();
                  final content = ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: optList.length,
                    itemBuilder: (context, index) {
                      final station = optList[index];
                      return ListTile(
                        title: Text(station),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteStation(station),
                        ),
                        onTap: () => onSelected(station),
                      );
                    },
                  );

                  return Material(
                    elevation: 4,
                    child:
                        optList.length <= 5
                            ? content
                            : ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 200),
                              child: content,
                            ),
                  );
                },
                onSelected: (val) => _stationTextController.text = val,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
