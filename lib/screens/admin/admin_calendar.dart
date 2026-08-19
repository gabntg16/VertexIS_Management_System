// lib/screens/admin/admin_calendar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../services/data_service.dart';
import '../../models/models.dart';
import '../../utils/theme.dart';
import '../../widgets/shared_widgets.dart';

class AdminCalendar extends StatefulWidget {
  const AdminCalendar({super.key});

  @override
  State<AdminCalendar> createState() => _AdminCalendarState();
}

class _AdminCalendarState extends State<AdminCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedBranchFilter;
  CalendarEventType? _selectedTypeFilter;

  Future<void> _showAddEventDialog(
      BuildContext context, DateTime initialDay) async {
    final theme = Theme.of(context);
    final svc = context.read<DataService>();
    final branches = svc.branches;
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String? selectedBranchId;
    var eventType = CalendarEventType.task;
    var selectedDate = initialDay;
    var selectedTime = const TimeOfDay(hour: 9, minute: 0);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        height: 4,
                        width: 40,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: theme.disabledColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text('Schedule Task or Appointment',
                        style: theme.textTheme.titleLarge),
                    const SizedBox(height: 24),
                    Form(
                      key: formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: titleController,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              hintText: 'Production run or client meeting',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Title is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: descriptionController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              hintText: 'Add notes for this task...',
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: ctx,
                                      initialDate: selectedDate,
                                      firstDate: DateTime.utc(2024, 1, 1),
                                      lastDate: DateTime.utc(2027, 12, 31),
                                    );
                                    if (picked != null) {
                                      setModalState(() => selectedDate = picked);
                                    }
                                  },
                                  icon: const Icon(Icons.calendar_today_rounded, size: 18),
                                  label: Text(DateFormat('MMM d').format(selectedDate)),
                                  style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1), foregroundColor: theme.colorScheme.primary),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final picked = await showTimePicker(
                                      context: ctx,
                                      initialTime: selectedTime,
                                    );
                                    if (picked != null) {
                                      setModalState(() => selectedTime = picked);
                                    }
                                  },
                                  icon: const Icon(Icons.access_time_rounded, size: 18),
                                  label: Text(selectedTime.format(ctx)),
                                  style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1), foregroundColor: theme.colorScheme.primary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String?>(
                            initialValue: selectedBranchId,
                            decoration: const InputDecoration(labelText: 'Branch (Optional)'),
                            dropdownColor: theme.cardTheme.color,
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Global / All Branches')),
                              ...branches.map((branch) => DropdownMenuItem(value: branch.id, child: Text(branch.name))),
                            ],
                            onChanged: (value) => setModalState(() => selectedBranchId = value),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<CalendarEventType>(
                            initialValue: eventType,
                            decoration: const InputDecoration(labelText: 'Event Type'),
                            dropdownColor: theme.cardTheme.color,
                            items: CalendarEventType.values
                                .map((type) => DropdownMenuItem(value: type, child: Text(type.label)))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) setModalState(() => eventType = value);
                            },
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('CANCEL'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (!formKey.currentState!.validate()) return;
                                    final eventDate = DateTime(
                                      selectedDate.year,
                                      selectedDate.month,
                                      selectedDate.day,
                                      selectedTime.hour,
                                      selectedTime.minute,
                                    );
                                    final branchName = selectedBranchId == null
                                        ? null
                                        : branches.firstWhere((b) => b.id == selectedBranchId).name;
                                    svc.addEvent(
                                      titleController.text.trim(),
                                      eventDate,
                                      descriptionController.text.trim(),
                                      eventType,
                                      branchId: selectedBranchId,
                                      branchName: branchName,
                                    );
                                    Navigator.of(ctx).pop();
                                    showSnack(context, '${eventType.label} scheduled successfully');
                                  },
                                  child: const Text('SAVE EVENT'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final svc = context.watch<DataService>();
    final selected = _selectedDay ?? _focusedDay;
    final filteredEvents = svc.events.where((e) {
      if (_selectedBranchFilter != null && e.branchId != _selectedBranchFilter) return false;
      if (_selectedTypeFilter != null && e.type != _selectedTypeFilter) return false;
      return true;
    }).toList();

    final dayEvents = filteredEvents.where((e) => isSameDay(e.date, selected)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TableCalendar(
                        firstDay: DateTime.utc(2024, 1, 1),
                        lastDay: DateTime.utc(2027, 12, 31),
                        focusedDay: _focusedDay,
                        rowHeight: 48,
                        selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
                        eventLoader: (day) => svc.events.where((e) => isSameDay(e.date, day)).toList(),
                        onDaySelected: (sel, foc) => setState(() {
                          _selectedDay = sel;
                          _focusedDay = foc;
                        }),
                        calendarStyle: CalendarStyle(
                          defaultTextStyle: theme.textTheme.bodyMedium!,
                          weekendTextStyle: theme.textTheme.bodyMedium!.copyWith(color: AppTheme.accentOrange),
                          outsideTextStyle: theme.textTheme.bodySmall!.copyWith(color: theme.disabledColor),
                          selectedDecoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                          todayDecoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.3), shape: BoxShape.circle),
                          markerDecoration: BoxDecoration(color: theme.colorScheme.tertiary, shape: BoxShape.circle),
                          markerSize: 6,
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: theme.textTheme.titleMedium!,
                          leftChevronIcon: Icon(Icons.chevron_left_rounded, color: theme.colorScheme.primary),
                          rightChevronIcon: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.primary),
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: theme.textTheme.labelSmall!,
                          weekendStyle: theme.textTheme.labelSmall!.copyWith(color: AppTheme.accentOrange),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SectionHeader(
                    title: DateFormat('MMMM d, yyyy').format(selected),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${dayEvents.length} scheduled', style: theme.textTheme.labelSmall),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _showAddEventDialog(context, selected),
                          icon: Icon(Icons.add_circle_rounded, color: theme.colorScheme.primary, size: 24),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          isExpanded: true,
                          initialValue: _selectedBranchFilter,
                          decoration: const InputDecoration(labelText: 'Branch', isDense: true),
                          dropdownColor: theme.cardTheme.color,
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Branches')),
                            ...svc.branches.map((branch) => DropdownMenuItem(value: branch.id, child: Text(branch.name))),
                          ],
                          onChanged: (value) => setState(() => _selectedBranchFilter = value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<CalendarEventType?>(
                          isExpanded: true,
                          initialValue: _selectedTypeFilter,
                          decoration: const InputDecoration(labelText: 'Type', isDense: true),
                          dropdownColor: theme.cardTheme.color,
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Types')),
                            ...CalendarEventType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.label))),
                          ],
                          onChanged: (value) => setState(() => _selectedTypeFilter = value),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (dayEvents.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(icon: Icons.event_available_outlined, message: 'No events scheduled for this day.'),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _EventCard(event: dayEvents[i]),
                  childCount: dayEvents.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final CalendarEvent event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final svc = context.read<DataService>();
    final typeColor = event.type == CalendarEventType.appointment ? AppTheme.accentOrange : AppTheme.accentYellow;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(color: typeColor, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(event.title, style: theme.textTheme.titleSmall)),
                      StatusBadge(label: event.type.label, color: typeColor),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14, color: theme.disabledColor),
                      const SizedBox(width: 4),
                      Text(DateFormat('h:mm a').format(event.date), style: theme.textTheme.bodySmall),
                      if (event.branchName != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.store_rounded, size: 14, color: theme.disabledColor),
                        const SizedBox(width: 4),
                        Text(event.branchName!, style: theme.textTheme.bodySmall),
                      ],
                    ],
                  ),
                  if (event.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(event.description, style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: () async {
                final confirmed = await showConfirmDialog(
                  context,
                  title: 'Remove event',
                  message: 'Delete "${event.title}" from the calendar?',
                  confirmText: 'Delete',
                  confirmColor: AppTheme.error,
                );
                if (confirmed == true) svc.deleteEvent(event.id);
              },
              icon: Icon(Icons.delete_outline_rounded, color: theme.disabledColor, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
