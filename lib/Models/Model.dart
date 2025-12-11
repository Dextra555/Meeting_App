class Team {
  final String id;
  final String name;
  final String description;
  Team({required this.id, required this.name, required this.description});
}

class Employee {
  final String id;
  final String name;
  final String category;
  final String teamId;
  Employee({
    required this.id,
    required this.name,
    required this.category,
    required this.teamId,
  });
}

class Meeting {
  final String id;
  final String title;
  final List<String> teamIds;
  final List<String> attendeeIds;
  final DateTime date;
  final bool isOnline;
  Meeting({
    required this.id,
    required this.title,
    required this.teamIds,
    required this.attendeeIds,
    required this.date,
    required this.isOnline,
  });
}
