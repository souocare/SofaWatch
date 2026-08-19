enum StatisticsActivityPeriod {
  days7(apiValue: '7d', label: '7D'),
  days14(apiValue: '14d', label: '14D'),
  days30(apiValue: '30d', label: '30D'),
  days90(apiValue: '90d', label: '90D'),
  year1(apiValue: '1y', label: '1Y'),
  all(apiValue: 'all', label: 'All');

  const StatisticsActivityPeriod({required this.apiValue, required this.label});

  final String apiValue;
  final String label;
}
