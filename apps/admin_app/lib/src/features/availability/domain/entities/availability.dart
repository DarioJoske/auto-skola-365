final class WorkingPeriod {
  const WorkingPeriod(this.day, this.start, this.end);
  final int day;
  final String start, end;
}

final class UnavailablePeriod {
  const UnavailablePeriod(this.start, this.end, this.kind);
  final DateTime start, end;
  final String kind;
}

final class Availability {
  Availability({
    required List<WorkingPeriod> rules,
    required List<UnavailablePeriod> blocks,
    this.timeZone = 'Europe/Zagreb',
  }) : rules = List.unmodifiable(rules),
       blocks = List.unmodifiable(blocks);
  final String timeZone;
  final List<WorkingPeriod> rules;
  final List<UnavailablePeriod> blocks;
}
