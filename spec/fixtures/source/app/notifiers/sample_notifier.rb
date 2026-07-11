# frozen_string_literal: true

# A notifier-style class whose icon name lives in an `ICON` constant, rendered
# dynamically (by a *different* file) via `PhosphorIcon(notification.icon)`.
# The name never appears as an icon-call argument, so only declaration-based
# harvesting keeps it. Not loaded at runtime — only parsed by SourceScanner.
class SampleNotifier
  ICON = :bell_ringing
end
