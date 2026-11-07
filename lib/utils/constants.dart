class IncidentCategories {
  static const all = [
    'Broken facilities',
    'Water shortage',
    'Electricity outage',
    'Damaged furniture',
    'Sanitation',
    'Safety concern',
    'Other',
  ];
}

class IncidentStatus {
  static const submitted = 'Submitted';
  static const inReview = 'In Review';
  static const inProgress = 'In Progress';
  static const resolved = 'Resolved';
  static const all = [submitted, inReview, inProgress, resolved];
}