/// Market Status — Production-grade Flutter package for global market status.
///
/// Supports stock exchanges, commodity exchanges, futures markets, and crypto
/// with DST handling, holiday calendars, and remote calendar sync via GitHub.
library market_status;

// Core models
export 'src/models/market_type.dart';
export 'src/models/session_type.dart';
export 'src/models/trading_session.dart';
export 'src/models/market_definition.dart';
export 'src/models/market_state.dart';
export 'src/models/holiday.dart';
export 'src/models/special_day.dart';
export 'src/models/timezone_mode.dart';

// Market registry
export 'src/markets/markets.dart';

// Providers
export 'src/providers/time_provider.dart';
export 'src/providers/timezone_provider.dart';
export 'src/providers/holiday_provider.dart'
    show
        HolidayProvider,
        LocalHolidayProvider,
        CachedHolidayProvider,
        RemoteHolidayProvider,
        CompositeHolidayProvider;

// Engine
export 'src/engine/trading_session_engine.dart';
export 'src/engine/holiday_engine.dart';
export 'src/engine/market_engine.dart';

// Sync
export 'src/sync/calendar_sync.dart'
    show CalendarSync, SyncResult;

// Embedded default data
export 'src/data/default_holidays.dart';

// Main API
export 'src/market_status_api.dart';
