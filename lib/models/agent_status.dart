/// Agent status enum for multi-agent monitoring
enum AgentStatus {
  /// Currently responding or active
  live,

  /// Working on a task
  busy,

  /// Waiting for work
  idle,

  /// Error or problem state
  error;

  /// Get display color for this status (dark theme)
  int get darkColor {
    switch (this) {
      case AgentStatus.live:
        return 0xFF22C55E; // green
      case AgentStatus.busy:
        return 0xFFEAB308; // yellow
      case AgentStatus.idle:
        return 0xFF6B7280; // gray
      case AgentStatus.error:
        return 0xFFEF4444; // red
    }
  }

  /// Get display color for this status (light theme)
  int get lightColor {
    switch (this) {
      case AgentStatus.live:
        return 0xFF16A34A; // green
      case AgentStatus.busy:
        return 0xFFCA8A04; // yellow
      case AgentStatus.idle:
        return 0xFF9CA3AF; // gray
      case AgentStatus.error:
        return 0xFFDC2626; // red
    }
  }

  /// Get icon for this status
  String get icon {
    switch (this) {
      case AgentStatus.live:
        return '🟢';
      case AgentStatus.busy:
        return '🟡';
      case AgentStatus.idle:
        return '⚪';
      case AgentStatus.error:
        return '🔴';
    }
  }

  /// Get display label for this status
  String get label {
    switch (this) {
      case AgentStatus.live:
        return 'LIVE';
      case AgentStatus.busy:
        return 'BUSY';
      case AgentStatus.idle:
        return 'IDLE';
      case AgentStatus.error:
        return 'ERROR';
    }
  }
}
