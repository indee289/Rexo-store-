import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Every icon used across the app, in one place.
///
/// ### Weight
/// Icons use Phosphor **Regular** — a clean single-weight stroke. The app
/// previously used **Duotone**, which paints a tinted fill behind the stroke;
/// at 16-22px that second tone reads as visual noise and muddies the glyph,
/// especially next to text. A single crisp stroke is what makes an interface
/// look considered rather than busy.
///
/// ### Active states
/// [AppIcons.fill] holds the solid variants of the handful of icons that need
/// a selected state (the bottom navigation). Pairing a stroke icon for rest
/// with a filled icon for active is the standard iOS/Material pattern and
/// reads instantly, without relying on colour alone.
///
/// ### Brand marks
/// Social platforms use their real logos. Previously TikTok fell back to a
/// generic music note and X/Twitter and Facebook both fell back to the same
/// globe, so three different platforms were indistinguishable in campaign
/// cards.
class AppIcons {
  AppIcons._();

  static const IconData add = PhosphorIconsRegular.plus;
  static const IconData add_circle = PhosphorIconsRegular.plusCircle;
  static const IconData arrow_down_1 = PhosphorIconsRegular.caretDown;
  static const IconData arrow_left = PhosphorIconsRegular.arrowLeft;
  static const IconData arrow_right_3 = PhosphorIconsRegular.caretRight;
  static const IconData award = PhosphorIconsRegular.medal;
  static const IconData bag_2 = PhosphorIconsRegular.shoppingBag;
  static const IconData bookmark = PhosphorIconsRegular.bookmarkSimple;
  static const IconData box = PhosphorIconsRegular.package;
  static const IconData box_1 = PhosphorIconsRegular.package;
  static const IconData briefcase = PhosphorIconsRegular.briefcase;
  static const IconData building = PhosphorIconsRegular.building;
  static const IconData buildings = PhosphorIconsRegular.buildings;
  static const IconData calculator = PhosphorIconsRegular.calculator;
  static const IconData calendar = PhosphorIconsRegular.calendar;
  static const IconData calendar_1 = PhosphorIconsRegular.calendarBlank;
  static const IconData call = PhosphorIconsRegular.phone;
  static const IconData camera = PhosphorIconsRegular.camera;
  static const IconData category = PhosphorIconsRegular.squaresFour;
  static const IconData chart_1 = PhosphorIconsRegular.chartLine;
  static const IconData chart_2 = PhosphorIconsRegular.chartBar;
  static const IconData chart_square = PhosphorIconsRegular.chartBar;
  static const IconData clock = PhosphorIconsRegular.clock;
  static const IconData close_circle = PhosphorIconsRegular.xCircle;
  static const IconData cloud = PhosphorIconsRegular.cloud;
  static const IconData copy = PhosphorIconsRegular.copy;
  static const IconData drag = PhosphorIconsRegular.dotsSixVertical;
  static const IconData crown_1 = PhosphorIconsRegular.crown;
  static const IconData document = PhosphorIconsRegular.fileText;
  static const IconData document_text = PhosphorIconsRegular.fileText;
  static const IconData document_upload = PhosphorIconsRegular.fileArrowUp;
  static const IconData edit = PhosphorIconsRegular.pencilSimple;
  static const IconData flag = PhosphorIconsRegular.flag;
  static const IconData edit_2 = PhosphorIconsRegular.pencilSimple;
  static const IconData export_1 = PhosphorIconsRegular.export;
  static const IconData eye = PhosphorIconsRegular.eye;
  static const IconData eye_slash = PhosphorIconsRegular.eyeSlash;
  static const IconData filter = PhosphorIconsRegular.slidersHorizontal;
  static const IconData gallery = PhosphorIconsRegular.image;
  static const IconData gallery_add = PhosphorIconsRegular.image;
  static const IconData gallery_slash = PhosphorIconsRegular.imageSquare;
  static const IconData gift = PhosphorIconsRegular.gift;
  static const IconData global = PhosphorIconsRegular.globe;
  static const IconData hashtag = PhosphorIconsRegular.hash;
  static const IconData heart = PhosphorIconsRegular.heart;
  static const IconData home_2 = PhosphorIconsRegular.house;
  static const IconData image = PhosphorIconsRegular.image;
  static const IconData info_circle = PhosphorIconsRegular.info;
  static const IconData key = PhosphorIconsRegular.key;
  static const IconData link = PhosphorIconsRegular.linkSimple;
  static const IconData link_2 = PhosphorIconsRegular.link;
  static const IconData location = PhosphorIconsRegular.mapPin;
  static const IconData lock = PhosphorIconsRegular.lock;
  static const IconData lock_1 = PhosphorIconsRegular.lockKey;
  static const IconData logout = PhosphorIconsRegular.signOut;
  static const IconData map = PhosphorIconsRegular.mapTrifold;
  static const IconData medal_star = PhosphorIconsRegular.medal;
  static const IconData message = PhosphorIconsRegular.chatCircle;
  static const IconData message_question = PhosphorIconsRegular.question;
  static const IconData message_text = PhosphorIconsRegular.chatCircleDots;
  static const IconData minus = PhosphorIconsRegular.minus;
  static const IconData mobile = PhosphorIconsRegular.deviceMobile;
  static const IconData money = PhosphorIconsRegular.currencyInr;
  static const IconData money_add = PhosphorIconsRegular.money;
  static const IconData money_recive = PhosphorIconsRegular.handCoins;
  static const IconData money_send = PhosphorIconsRegular.coins;
  static const IconData monitor = PhosphorIconsRegular.monitor;
  static const IconData more = PhosphorIconsRegular.dotsThreeVertical;
  static const IconData moon = PhosphorIconsRegular.moon;
  static const IconData music = PhosphorIconsRegular.musicNote;
  static const IconData notification = PhosphorIconsRegular.bell;
  static const IconData pause = PhosphorIconsRegular.pause;
  static const IconData people = PhosphorIconsRegular.users;
  static const IconData percentage_circle = PhosphorIconsRegular.percent;
  static const IconData play = PhosphorIconsRegular.play;
  static const IconData profile_circle = PhosphorIconsRegular.userCircle;
  static const IconData receipt = PhosphorIconsRegular.receipt;
  static const IconData refresh = PhosphorIconsRegular.arrowsClockwise;
  static const IconData save_2 = PhosphorIconsRegular.floppyDisk;
  static const IconData search_normal = PhosphorIconsRegular.magnifyingGlass;
  static const IconData send_1 = PhosphorIconsRegular.paperPlaneTilt;
  static const IconData send_2 = PhosphorIconsRegular.paperPlaneRight;
  static const IconData setting = PhosphorIconsRegular.gearSix;
  static const IconData setting_2 = PhosphorIconsRegular.gearSix;
  static const IconData share = PhosphorIconsRegular.shareNetwork;
  static const IconData shield_cross = PhosphorIconsRegular.shieldWarning;
  static const IconData shield_tick = PhosphorIconsRegular.shieldCheck;
  static const IconData shop = PhosphorIconsRegular.storefront;
  static const IconData shopping_bag = PhosphorIconsRegular.shoppingBag;
  static const IconData shopping_cart = PhosphorIconsRegular.shoppingCart;
  static const IconData slash = PhosphorIconsRegular.prohibit;
  static const IconData sms = PhosphorIconsRegular.envelopeSimple;
  static const IconData star_1 = PhosphorIconsRegular.star;
  static const IconData sun_1 = PhosphorIconsRegular.sun;
  static const IconData tag = PhosphorIconsRegular.tag;
  static const IconData task_square = PhosphorIconsRegular.checkSquare;
  static const IconData tick_circle = PhosphorIconsRegular.checkCircle;
  static const IconData ticket_discount = PhosphorIconsRegular.ticket;
  static const IconData timer = PhosphorIconsRegular.timer;
  static const IconData trash = PhosphorIconsRegular.trash;
  static const IconData trend_up = PhosphorIconsRegular.trendUp;
  static const IconData user = PhosphorIconsRegular.user;
  static const IconData user_add = PhosphorIconsRegular.userPlus;
  static const IconData user_edit = PhosphorIconsRegular.userGear;
  static const IconData user_remove = PhosphorIconsRegular.userMinus;
  static const IconData user_tag = PhosphorIconsRegular.at;
  static const IconData user_tick = PhosphorIconsRegular.userCheck;
  static const IconData verify = PhosphorIconsRegular.sealCheck;
  static const IconData video = PhosphorIconsRegular.videoCamera;
  static const IconData video_play = PhosphorIconsRegular.playCircle;
  static const IconData video_tick = PhosphorIconsRegular.videoCamera;
  static const IconData volume_high = PhosphorIconsRegular.speakerHigh;
  static const IconData wallet = PhosphorIconsRegular.wallet;
  static const IconData wallet_1 = PhosphorIconsRegular.wallet;
  static const IconData wallet_2 = PhosphorIconsRegular.wallet;
  static const IconData wallet_3 = PhosphorIconsRegular.wallet;
  static const IconData warning_2 = PhosphorIconsRegular.warning;

  // ── Real brand marks ────────────────────────────────────────────────────
  static const IconData instagram = PhosphorIconsRegular.instagramLogo;
  static const IconData youtube = PhosphorIconsRegular.youtubeLogo;
  static const IconData facebook = PhosphorIconsRegular.facebookLogo;
  static const IconData tiktok = PhosphorIconsRegular.tiktokLogo;
  static const IconData x = PhosphorIconsRegular.xLogo;
  static const IconData linkedin = PhosphorIconsRegular.linkedinLogo;

  /// Solid variants, for selected/active states.
  static const fill = _FilledIcons();
}

/// Filled counterparts of the icons that need an active state.
class _FilledIcons {
  const _FilledIcons();

  IconData get home_2 => PhosphorIconsFill.house;
  IconData get volume_high => PhosphorIconsFill.speakerHigh;
  IconData get briefcase => PhosphorIconsFill.briefcase;
  IconData get user => PhosphorIconsFill.user;
  IconData get bookmark => PhosphorIconsFill.bookmarkSimple;
  IconData get heart => PhosphorIconsFill.heart;
  IconData get star_1 => PhosphorIconsFill.star;
  IconData get notification => PhosphorIconsFill.bell;
  IconData get message_text => PhosphorIconsFill.chatCircleDots;
  IconData get wallet => PhosphorIconsFill.wallet;
  IconData get shield_tick => PhosphorIconsFill.shieldCheck;
  IconData get tick_circle => PhosphorIconsFill.checkCircle;

  // Admin Center dock destinations.
  IconData get chart_square => PhosphorIconsFill.chartBar;
  IconData get people => PhosphorIconsFill.users;
  IconData get task_square => PhosphorIconsFill.checkSquare;
  IconData get setting_2 => PhosphorIconsFill.gearSix;
  IconData get profile_circle => PhosphorIconsFill.userCircle;
}
