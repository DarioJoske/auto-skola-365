import '../../domain/entities/availability.dart';

final class AvailabilityModel {
  AvailabilityModel(this.data);
  final Availability data;
  factory AvailabilityModel.fromJson(Map<String, dynamic> json) =>
      AvailabilityModel(
        Availability(
          timeZone: json['timeZone'] as String,
          rules: (json['rules'] as List)
              .map(
                (r) => WorkingPeriod(
                  r['dayOfWeek'] as int,
                  r['startTime'] as String,
                  r['endTime'] as String,
                ),
              )
              .toList(),
          blocks: (json['blocks'] as List)
              .map(
                (b) => UnavailablePeriod(
                  DateTime.parse(b['startAt'] as String).toLocal(),
                  DateTime.parse(b['endAt'] as String).toLocal(),
                  b['kind'] as String,
                ),
              )
              .toList(),
        ),
      );
  Map<String, dynamic> toJson() => {
    'rules': data.rules
        .map(
          (r) => {'dayOfWeek': r.day, 'startTime': r.start, 'endTime': r.end},
        )
        .toList(),
    'blocks': data.blocks
        .map(
          (b) => {
            'startAt': b.start.toUtc().toIso8601String(),
            'endAt': b.end.toUtc().toIso8601String(),
            'kind': b.kind,
          },
        )
        .toList(),
  };
}
