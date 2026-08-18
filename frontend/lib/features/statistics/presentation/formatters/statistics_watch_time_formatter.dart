String formatStatisticsWatchTime(int minutes) {
  if (minutes <= 0) {
    return '0m';
  }

  final int days = minutes ~/ (24 * 60);

  final int remainingAfterDays = minutes % (24 * 60);

  final int hours = remainingAfterDays ~/ 60;

  final int remainingMinutes = remainingAfterDays % 60;

  if (days > 0) {
    if (hours > 0) {
      return '${days}d ${hours}h';
    }

    return '${days}d';
  }

  if (hours > 0) {
    if (remainingMinutes > 0) {
      return '${hours}h ${remainingMinutes}m';
    }

    return '${hours}h';
  }

  return '${remainingMinutes}m';
}
