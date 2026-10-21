from datetime import date, datetime, timedelta, timezone
import pytz

from backend.app.core.config import BUSINESS_TZ

_BRT = pytz.timezone(BUSINESS_TZ)


def get_business_day(dt: datetime) -> date:
    """Converte um datetime para o fuso de negócio e retorna o dia civil."""
    if dt.tzinfo is None:
        dt = _BRT.localize(dt)
    else:
        dt = dt.astimezone(_BRT)
    return dt.date()


def get_day_utc_bounds(day: date) -> tuple[datetime, datetime]:
    """Retorna (início, fim) em UTC do dia civil no fuso de negócio."""
    start_local = _BRT.localize(datetime(day.year, day.month, day.day, 0, 0, 0))
    end_local = _BRT.localize(datetime(day.year, day.month, day.day, 23, 59, 59, 999999))
    return start_local.astimezone(timezone.utc), end_local.astimezone(timezone.utc)
