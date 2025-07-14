import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/class_model.dart';
import '../services/schedule_service.dart';
import '../models/teacher_model.dart';
import '../services/auth_service.dart';


class TeacherHomeScreen extends StatefulWidget {
  final Teacher teacher;


  const TeacherHomeScreen({Key? key, required this.teacher}) : super(key: key);


  @override
  _TeacherHomeScreenState createState() => _TeacherHomeScreenState();
}


class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  final ScheduleService _scheduleService = ScheduleService();
  final AuthService _authService = AuthService();
  List<ClassSchedule> _schedules = [];
  bool _isLoading = true;
  bool _isDeleteMode = false;
  List<String> _selectedSchedules = [];
  ClassSchedule? _scheduleToEdit;


  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }


  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    try {
      final schedules = await _scheduleService.getTeacherSchedules(
        widget.teacher.id.toString(),
      );
      schedules.sort((a, b) {
        final dateCompare = a.date.compareTo(b.date);
        if (dateCompare != 0) return dateCompare;
        return a.startTime.compareTo(b.startTime);
      });
      setState(() => _schedules = schedules);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar aulas: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }


  Future<void> _deleteSelectedSchedules() async {
    if (_selectedSchedules.isEmpty) return;


    try {
      for (final id in _selectedSchedules) {
        await _scheduleService.deleteClassSchedule(id);
      }
      await _loadSchedules();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_selectedSchedules.length} aulas removidas com sucesso!',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao remover aulas: $e')));
    } finally {
      setState(() {
        _selectedSchedules.clear();
        _isDeleteMode = false;
      });
    }
  }


  String _formatTime(String time) {
    try {
      final parsedTime = DateFormat('HH:mm').parse(time);
      return DateFormat('h:mm a').format(parsedTime);
    } catch (e) {
      return time;
    }
  }


  void _showAddClassDialog() {
    _showClassDialog(isEditing: false);
  }


  void _showEditClassDialog(ClassSchedule schedule) {
    _scheduleToEdit = schedule;
    _showClassDialog(isEditing: true);
  }


  void _showClassDialog({required bool isEditing}) {
    final _formKey = GlobalKey<FormState>();
    final _classNameController = TextEditingController(
      text: isEditing ? _scheduleToEdit?.className ?? '' : '',
    );
    final _descriptionController = TextEditingController(
      text: isEditing ? _scheduleToEdit?.description ?? '' : '',
    );
    String _selectedDay = isEditing ? _scheduleToEdit!.dayOfWeek : 'Segunda';
    TimeOfDay _selectedTime =
        isEditing
            ? TimeOfDay(
              hour: int.parse(_scheduleToEdit!.startTime.split(':')[0]),
              minute: int.parse(_scheduleToEdit!.startTime.split(':')[1]),
            )
            : const TimeOfDay(hour: 9, minute: 0);
    DateTime _selectedDate =
        isEditing
            ? _scheduleToEdit!.date
            : DateTime.now().add(const Duration(days: 1));
    List<String> _selectedClasses =
        isEditing ? List.from(_scheduleToEdit!.classes) : ['A1'];


    final availableClasses = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];


    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(isEditing ? 'Editar Aula' : 'Adicionar Nova Aula'),
                content: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _classNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nome da Aula*',
                          ),
                          validator:
                              (value) =>
                                  value!.isEmpty ? 'Campo obrigatório' : null,
                        ),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Descrição (opcional)',
                          ),
                        ),
                        DropdownButtonFormField<String>(
                          value: _selectedDay,
                          items:
                              ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta']
                                  .map(
                                    (day) => DropdownMenuItem(
                                      value: day,
                                      child: Text(day),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (value) => setState(() => _selectedDay = value!),
                          decoration: const InputDecoration(
                            labelText: 'Dia da Semana*',
                          ),
                        ),
                        ListTile(
                          title: const Text('Data da Aula*'),
                          subtitle: Text(
                            DateFormat('dd/MM/yyyy').format(_selectedDate),
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (date != null) {
                              setState(() => _selectedDate = date);
                            }
                          },
                        ),
                        ListTile(
                          title: const Text('Horário*'),
                          subtitle: Text(_selectedTime.format(context)),
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _selectedTime,
                            );
                            if (time != null) {
                              setState(() => _selectedTime = time);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text('Turmas*', style: TextStyle(fontSize: 16)),
                        Wrap(
                          spacing: 8,
                          children:
                              availableClasses.map((classItem) {
                                final isSelected = _selectedClasses.contains(
                                  classItem,
                                );
                                return FilterChip(
                                  label: Text(classItem),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedClasses.add(classItem);
                                      } else {
                                        _selectedClasses.remove(classItem);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                        ),
                        if (_selectedClasses.isEmpty)
                          const Text(
                            'Selecione pelo menos uma turma',
                            style: TextStyle(color: Colors.red),
                          ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      _scheduleToEdit = null;
                      Navigator.pop(context);
                    },
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        if (_selectedClasses.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Selecione pelo menos uma turma'),
                            ),
                          );
                          return;
                        }


                        final schedule = ClassSchedule(
                          id:
                              isEditing
                                  ? _scheduleToEdit!.id
                                  : DateTime.now().millisecondsSinceEpoch
                                      .toString(),
                          teacherId: widget.teacher.id.toString(),
                          dayOfWeek: _selectedDay,
                          date: _selectedDate,
                          startTime:
                              '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                          className: _classNameController.text,
                          description:
                              _descriptionController.text.isNotEmpty
                                  ? _descriptionController.text
                                  : null,
                          classes: _selectedClasses,
                        );


                        try {
                          if (isEditing) {
                            await _scheduleService.updateClassSchedule(
                              schedule,
                            );
                          } else {
                            await _scheduleService.addClassSchedule(schedule);
                          }
                          await _loadSchedules();
                          _scheduleToEdit = null;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Aula ${isEditing ? 'atualizada' : 'adicionada'} com sucesso!',
                              ),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Erro ao ${isEditing ? 'atualizar' : 'adicionar'} aula: $e',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: Text(isEditing ? 'Atualizar' : 'Salvar'),
                  ),
                ],
              );
            },
          ),
    );
  }


  void _showEditOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Remover Aulas'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _isDeleteMode = true;
                    _selectedSchedules.clear();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Selecione as aulas que deseja remover'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar Aula'),
                onTap: () {
                  Navigator.pop(context);
                  _showSelectClassToEdit();
                },
              ),
            ],
          ),
    );
  }


  void _showSelectClassToEdit() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Selecione a aula para editar'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _schedules.length,
                itemBuilder: (context, index) {
                  final schedule = _schedules[index];
                  return ListTile(
                    title: Text(schedule.className),
                    subtitle: Text(
                      '${schedule.dayOfWeek} - ${DateFormat('dd/MM').format(schedule.date)} às ${_formatTime(schedule.startTime)}',
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showEditClassDialog(schedule);
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
    );
  }


  Widget _buildScheduleTable() {
    if (_schedules.isEmpty) {
      return const Center(child: Text('Nenhuma aula agendada'));
    }


    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          if (_isDeleteMode) const DataColumn(label: Text('Selecionar')),
          const DataColumn(label: Text('Dia')),
          const DataColumn(label: Text('Data')),
          const DataColumn(label: Text('Horário')),
          const DataColumn(label: Text('Turma')),
        ],
        rows:
            _schedules.map((schedule) {
              return DataRow(
                cells: [
                  if (_isDeleteMode)
                    DataCell(
                      Checkbox(
                        value: _selectedSchedules.contains(schedule.id),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedSchedules.add(schedule.id);
                            } else {
                              _selectedSchedules.remove(schedule.id);
                            }
                          });
                        },
                      ),
                    ),
                  DataCell(Text(schedule.dayOfWeek)),
                  DataCell(Text('${schedule.date.day}/${schedule.date.month}')),
                  DataCell(Text(_formatTime(schedule.startTime))),
                  DataCell(Text(schedule.classes.join(', '))),
                ],
              );
            }).toList(),
      ),
    );
  }


  Future<void> _performLogout(BuildContext context) async {
    try {
      await _authService.signOut();
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao sair: $e')));
    }
  }


  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar Saída'),
            content: const Text('Tem certeza que deseja sair do aplicativo?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _performLogout(context);
                },
                child: const Text('Sair', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }


  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (ctx) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Configurações'),
                onTap: () {
                  Navigator.pop(ctx);
                  
                },
              ),
              ListTile(
                leading: const Icon(Icons.exit_to_app),
                title: const Text('Sair'),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmLogout(context);
                },
              ),
            ],
          ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('HELLO, ${widget.teacher.name.toUpperCase()}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _showMenu(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddClassDialog,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Check your class schedule',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(child: _buildScheduleTable()),
                      ],
                    ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child:
                  _isDeleteMode
                      ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed:
                                _selectedSchedules.isEmpty
                                    ? null
                                    : () {
                                      _deleteSelectedSchedules();
                                    },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Confirmar Exclusão'),
                          ),
                          const SizedBox(width: 16),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isDeleteMode = false;
                                _selectedSchedules.clear();
                              });
                            },
                            child: const Text('Cancelar'),
                          ),
                        ],
                      )
                      : ElevatedButton.icon(
                        onPressed: () => _showEditOptions(context),
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar Aulas'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () {},
            ),
            IconButton(icon: const Icon(Icons.home), onPressed: () {}),
            IconButton(icon: const Icon(Icons.person), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}



