/// Campster liquid-glass design system — single import for every screen.
///
/// ```dart
/// import 'package:rexo_marketplace/core/widgets/glass/glass.dart';
/// ```
///
/// Component map (use these; never raw `Card`, `AppBar`, `ElevatedButton`,
/// `TextField`, `AlertDialog` or ad-hoc `Container` decorations):
///
/// | Need                  | Use                                      |
/// |-----------------------|------------------------------------------|
/// | Screen scaffold       | `GlassScaffold`                          |
/// | Ambient backdrop      | `GlassBackdrop`                          |
/// | Raw glass pane        | `GlassSurface`                           |
/// | Content card          | `GlassCard`, `GlassListCard`             |
/// | Leading icon bubble   | `GlassIconBubble`                        |
/// | Buttons               | `GlassButton` (+ named variants)         |
/// | Icon buttons          | `GlassIconButton`                        |
/// | Navigation bar        | `GlassLargeTitleHeader` (preferred)      |
/// |                       | `GlassAppBar` (fixed bars only)          |
/// | Grouped list section  | `GlassSection`, `GlassGroup`, `GlassRow` |
/// | Stat pill             | `GlassStatPill`                          |
/// | Tile grid             | `GlassTileGrid` + `GlassTile`            |
/// | Bottom nav            | `GlassNavBar` + `GlassNavItem`           |
/// | Inputs                | `GlassTextField`                         |
/// | Bottom sheets         | `showGlassSheet`, `GlassSheet`           |
/// | Dialogs               | `showGlassDialog`, `showGlassConfirm`    |
/// | Chips / tags / status | `GlassChip`, `GlassChipRow`              |
/// | Toggles               | `GlassSwitch`, `GlassSwitchTile`         |
/// | Tabs                  | `GlassTabBar`                            |
/// | Toasts                | `showGlassSnackBar`                      |
/// | Empty / error / load  | `GlassEmptyState`, `GlassErrorState`, `GlassLoader`, `GlassSkeleton` |
library;

export 'glass_app_bar.dart';
export 'glass_backdrop.dart';
export 'glass_button.dart';
export 'glass_card.dart';
export 'glass_chip.dart';
export 'glass_dialog.dart';
export 'glass_group.dart';
export 'glass_header.dart';
export 'glass_icon_button.dart';
export 'glass_nav_bar.dart';
export 'glass_scaffold.dart';
export 'glass_sheet.dart';
export 'glass_snackbar.dart';
export 'glass_states.dart';
export 'glass_surface.dart';
export 'glass_switch.dart';
export 'glass_tab_bar.dart';
export 'glass_text_field.dart';
