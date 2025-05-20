import 'package:flutter/material.dart';
import 'package:shift_app/services/settings_database_service.dart';

class SettingsManager {
  static Future<List<String>> loadRoles() async =>
      await SettingsDatabaseService.getAllRoles();

  static Future<List<String>> loadStations() async =>
      await SettingsDatabaseService.getAllStations();

  static Future<List<String>> loadPositions() async =>
      await SettingsDatabaseService.getAllPositions();

  static Future<void> addRole(
    String role,
    List<String> existing,
    Function(String) onSuccess,
    Function(String) onError,
  ) async {
    final text = role.trim();
    if (text.isEmpty || existing.contains(text)) {
      onError("❌ שגיאה: לא ניתן להוסיף את המשימה");
      return;
    }
    try {
      await SettingsDatabaseService.insertRole(text);
      onSuccess(text);
    } catch (e) {
      onError("❌ שגיאה בשמירה: $e");
    }
  }

  static Future<void> addStation(
    String station,
    List<String> existing,
    Function(String) onSuccess,
    Function(String) onError,
  ) async {
    final text = station.trim();
    if (text.isEmpty || existing.contains(text)) {
      onError("❌ שגיאה: לא ניתן להוסיף את התחנה");
      return;
    }
    try {
      await SettingsDatabaseService.insertStation(text);
      onSuccess(text);
    } catch (e) {
      onError("❌ שגיאה בשמירה: $e");
    }
  }

  static Future<void> addPosition(
    String pos,
    List<String> existing,
    Function(String) onSuccess,
    Function(String) onError,
  ) async {
    final text = pos.trim();
    if (text.isEmpty || existing.contains(text)) {
      onError("❌ שגיאה: לא ניתן להוסיף את התפקיד");
      return;
    }
    try {
      await SettingsDatabaseService.insertPosition(text);
      onSuccess(text);
    } catch (e) {
      onError("❌ שגיאה בשמירה: $e");
    }
  }

  static Future<void> deleteRole(String role, Function() onDone) async {
    await SettingsDatabaseService.deleteRole(role);
    onDone();
  }

  static Future<void> deleteStation(String station, Function() onDone) async {
    await SettingsDatabaseService.deleteStation(station);
    onDone();
  }

  static Future<void> deletePosition(String pos, Function() onDone) async {
    await SettingsDatabaseService.deletePosition(pos);
    onDone();
  }
}

class ShiftSettings {
  static Future<Map<String, List<String>>> loadAll() async {
    final roles = await SettingsDatabaseService.getAllRoles();
    final stations = await SettingsDatabaseService.getAllStations();
    final positions = await SettingsDatabaseService.getAllPositions();
    return {'roles': roles, 'stations': stations, 'positions': positions};
  }

  static Widget buildSettingsSections({
    required BuildContext context,
    required List<String> roles,
    required List<String> stations,
    required List<String> positions,
    required VoidCallback onRefresh,
  }) {
    void showRoleSettingsDialog(String role) async {
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
      String mode = existing?['mode'] ?? 'תחנה';

      bool hasFixedHours =
          _startTimeController.text.isNotEmpty ||
          _endTimeController.text.isNotEmpty;
      bool hasPositions = selectedPositions.isNotEmpty;

      showDialog(
        context: context,
        builder:
            (_) => StatefulBuilder(
              builder:
                  (context, setStateDialog) => AlertDialog(
                    title: Text("הגדרות עבור '$role'"),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.now(),
                                      );
                                      if (picked != null) {
                                        setStateDialog(() {
                                          _startTimeController.text = picked
                                              .format(context);
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
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.now(),
                                      );
                                      if (picked != null) {
                                        setStateDialog(() {
                                          _endTimeController.text = picked
                                              .format(context);
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
                                  positions.map((pos) {
                                    final isSelected = selectedPositions
                                        .contains(pos);
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
                            positions:
                                hasPositions ? selectedPositions.toList() : [],
                          );

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("✅ נשמרו הגדרות ל־'$role'")),
                          );
                        },
                        child: const Text("שמור"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("בטל"),
                      ),
                    ],
                  ),
            ),
      );
    }

    void showPositionSettingsDialog(String position) async {
      final existingCode = await SettingsDatabaseService.getPositionCode(
        position,
      );
      final _codeController = TextEditingController(
        text: existingCode?.toString() ?? '',
      );

      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("✅ נשמר קוד לתפקיד '$position'"),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("❌ קוד לא תקין")),
                      );
                    }
                  },
                  child: const Text("שמור"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("בטל"),
                ),
              ],
            ),
      );
    }

    Widget buildSection({
      required String title,
      required String labelText,
      required List<String> values,
      required Function(String) onAdd,
      required Function(String) onDelete,
      Function(String)? onSettings,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Autocomplete<String>(
            optionsBuilder: (value) {
              final query = value.text.toLowerCase();
              return values.where((v) => v.toLowerCase().contains(query));
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
                decoration: InputDecoration(labelText: labelText),
                onEditingComplete: () {
                  onAdd(controller.text);
                  controller.clear();
                  onEditingComplete();
                },
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              final optList = options.toList();
              final content = ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: optList.length,
                itemBuilder: (context, index) {
                  final item = optList[index];
                  return ListTile(
                    title: Text(item),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onSettings != null)
                          IconButton(
                            icon: const Icon(Icons.settings),
                            onPressed: () => onSettings(item),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => onDelete(item),
                        ),
                      ],
                    ),
                    onTap: () => onSelected(item),
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
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSection(
          title: "🎯 סוג משמרת",
          labelText: "הוסף סוג משמרת חדש",
          values: roles,
          onAdd:
              (val) => SettingsManager.addRole(
                val,
                roles,
                (v) => onRefresh(),
                (err) => ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(err))),
              ),
          onDelete: (val) => SettingsManager.deleteRole(val, onRefresh),
          onSettings: showRoleSettingsDialog,
        ),
        buildSection(
          title: "🧍 תפקיד",
          labelText: "הוסף תפקיד חדש",
          values: positions,
          onAdd:
              (val) => SettingsManager.addPosition(
                val,
                positions,
                (v) => onRefresh(),
                (err) => ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(err))),
              ),
          onDelete: (val) => SettingsManager.deletePosition(val, onRefresh),
          onSettings: showPositionSettingsDialog,
        ),
        buildSection(
          title: "🏥 תחנה",
          labelText: "הוסף תחנה חדשה",
          values: stations,
          onAdd:
              (val) => SettingsManager.addStation(
                val,
                stations,
                (v) => onRefresh(),
                (err) => ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(err))),
              ),
          onDelete: (val) => SettingsManager.deleteStation(val, onRefresh),
        ),
      ],
    );
  }
}
