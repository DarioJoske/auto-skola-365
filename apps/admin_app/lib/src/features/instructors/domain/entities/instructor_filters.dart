class InstructorFilters {
  const InstructorFilters({this.active, this.categoryCode});

  final bool? active;
  final String? categoryCode;

  bool get isActive =>
      active != null ||
      (categoryCode != null && categoryCode!.trim().isNotEmpty);

  InstructorFilters clear() {
    return const InstructorFilters();
  }
}
