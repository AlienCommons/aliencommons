from datetime import datetime, timedelta

from django.utils import timezone


def compute_next_enqueue_at(interval_seconds: float) -> datetime:
    if interval_seconds <= 0:
        raise ValueError('Interval must be greater than 0')

    next_enqueue_at = timezone.now() + timedelta(seconds=interval_seconds)

    return next_enqueue_at
